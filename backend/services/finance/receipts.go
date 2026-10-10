package main

// Havale bildirimine dekont dosyası (migration 064, beşinci tur B9).
//   POST /finance/payments/:id/receipts                         (multipart "file") — bildirimi yapan sakin, ödeme onay beklerken
//   GET  /finance/payments/:id/receipts                         — bildirimi yapan sakin ya da yönetim
//   GET  /finance/payments/:id/receipts/:receiptId/download     — bildirimi yapan sakin ya da yönetim
// Dekont dayanaktır; borcu düşürmez (onay ya da banka ekstresi eşleşmesi düşürür).

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"log"
	"mime"
	"net/http"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/storage"
	"github.com/siteeksen/backend/services/finance/repository"
)

// receiptMaxBytes: dekont başına üst sınır.
const receiptMaxBytes = 5 << 20

// receiptTypes: içerik baytlara bakılarak doğrulanır (uzantıya değil).
var receiptTypes = map[string]string{"application/pdf": "pdf", "image/png": "png", "image/jpeg": "jpg", "image/webp": "webp"}

func receiptError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, repository.ErrReceiptNotAllowed):
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
	case errors.Is(err, repository.ErrReceiptLimit):
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
	case errors.Is(err, repository.ErrPaymentNotFound), errors.Is(err, storage.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Kayıt bulunamadı"})
	default:
		adjustmentError(c, err, "dekont")
	}
}

func uploadReceipt(repo *repository.FinanceRepository, store storage.Store) gin.HandlerFunc {
	return func(c *gin.Context) {
		if store == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Dosya deposu yapılandırılmamış; dekont yüklenemez. Dekont numarasını açıklamaya yazabilirsiniz.",
				"note": "STORAGE_BACKEND (local|s3) ayarlanınca dekont saklanır."})
			return
		}
		fh, err := c.FormFile("file")
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "file alanında dekont dosyası (PDF ya da görsel) gönderin"})
			return
		}
		if fh.Size > receiptMaxBytes {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": fmt.Sprintf("Dosya %d MB sınırını aşıyor", receiptMaxBytes>>20)})
			return
		}
		f, err := fh.Open()
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Dosya okunamadı"})
			return
		}
		data, err := io.ReadAll(io.LimitReader(f, receiptMaxBytes+1))
		f.Close()
		if err != nil || len(data) == 0 || len(data) > receiptMaxBytes {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": fmt.Sprintf("Dosya boş ya da %d MB sınırını aşıyor", receiptMaxBytes>>20)})
			return
		}
		ct := http.DetectContentType(data)
		ext, ok := receiptTypes[ct]
		if !ok {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Yalnızca PDF, PNG, JPEG ya da WEBP dekont kabul edilir (gelen: " + ct + ")"})
			return
		}
		propertyID, userID, paymentID := c.GetString("property_id"), c.GetString("user_id"), c.Param("id")
		ctx := c.Request.Context()
		// Önce yetki: başkasının ödemesine ya da sonuçlanmış ödemeye dosya yüklenmez.
		if _, err := repo.ReceiptAllowed(ctx, propertyID, userID, paymentID); err != nil {
			receiptError(c, err)
			return
		}
		sum := sha256.Sum256(data)
		sha := hex.EncodeToString(sum[:])
		key := fmt.Sprintf("receipts/%s/%s/%s.%s", propertyID, paymentID, sha[:16], ext)
		if _, err := store.Put(ctx, key, ct, bytes.NewReader(data)); err != nil {
			log.Printf("[finance] dekont depoya yazılamadı: %v", err)
			c.JSON(http.StatusBadGateway, gin.H{"error": "Dekont depoya yazılamadı; biraz sonra yeniden deneyin"})
			return
		}
		name := strings.TrimSpace(filepath.Base(fh.Filename))
		if name == "" || name == "." || len([]rune(name)) > 200 {
			name = "dekont." + ext
		}
		rc, err := repo.AddReceipt(ctx, propertyID, userID, &repository.Receipt{PaymentID: paymentID, StorageKey: key,
			FileName: name, ContentType: ct, SizeBytes: int64(len(data)), SHA256: sha})
		if err != nil {
			_ = store.Delete(ctx, key) // kayıt yazılamadıysa sahipsiz dosya bırakılmaz
			receiptError(c, err)
			return
		}
		c.JSON(http.StatusCreated, gin.H{"receipt": rc,
			"message": "Dekont bildiriminize eklendi; yönetim onay sırasında görür. Borç, yönetim onayıyla ya da banka hareketi eşleşince düşer."})
	}
}

func listReceipts(repo *repository.FinanceRepository) gin.HandlerFunc {
	return func(c *gin.Context) {
		propertyID := c.GetString("property_id")
		if err := repo.CanViewReceipts(c.Request.Context(), propertyID, c.GetString("user_id"), c.Param("id"), isFinanceManager(c)); err != nil {
			receiptError(c, err)
			return
		}
		list, err := repo.ListReceipts(c.Request.Context(), propertyID, c.Param("id"))
		if err != nil {
			receiptError(c, err)
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	}
}

func downloadReceipt(repo *repository.FinanceRepository, store storage.Store) gin.HandlerFunc {
	return func(c *gin.Context) {
		if store == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Dosya deposu yapılandırılmamış"})
			return
		}
		propertyID, ctx := c.GetString("property_id"), c.Request.Context()
		if err := repo.CanViewReceipts(ctx, propertyID, c.GetString("user_id"), c.Param("id"), isFinanceManager(c)); err != nil {
			receiptError(c, err)
			return
		}
		list, err := repo.ListReceipts(ctx, propertyID, c.Param("id"))
		if err != nil {
			receiptError(c, err)
			return
		}
		var rc *repository.Receipt
		for i := range list {
			if list[i].ID == c.Param("receiptId") {
				rc = &list[i]
			}
		}
		if rc == nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Kayıt bulunamadı"})
			return
		}
		body, _, err := store.Get(ctx, rc.StorageKey)
		if err != nil {
			receiptError(c, err)
			return
		}
		defer body.Close()
		c.Header("Content-Type", rc.ContentType)
		c.Header("Content-Disposition", mime.FormatMediaType("attachment", map[string]string{"filename": rc.FileName}))
		c.Header("X-Content-SHA256", rc.SHA256)
		c.Status(http.StatusOK)
		if _, err := io.Copy(c.Writer, body); err != nil {
			log.Printf("[finance] dekont gönderilemedi: %v", err)
		}
	}
}
