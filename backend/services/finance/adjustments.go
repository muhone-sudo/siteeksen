package main

// Alacak dekontu ve banka ekstresi mutabakatı (migration 059, Apsiyon BUG-12).

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"io"
	"log"
	"net/http"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shopspring/decimal"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/money"
	"github.com/siteeksen/backend/pkg/reports"
	"github.com/siteeksen/backend/services/finance/repository"
	"github.com/siteeksen/backend/services/finance/service"
)

// maxStatementBytes: banka ekstresi dosyasının en büyük boyutu.
const maxStatementBytes = 5 << 20

func adjustmentError(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, repository.ErrAssessmentNotFound), errors.Is(err, repository.ErrCreditNoteNotFound),
		errors.Is(err, repository.ErrBankLineNotFound), errors.Is(err, repository.ErrPaymentNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Kayıt bulunamadı"})
	case errors.Is(err, repository.ErrCreditExceeds), errors.Is(err, repository.ErrBankAmountMismatch),
		errors.Is(err, repository.ErrCreditReverseInvalid):
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error()})
	case errors.Is(err, repository.ErrCreditNoteReversed), errors.Is(err, repository.ErrBankLineResolved),
		errors.Is(err, repository.ErrPaymentNotPending):
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
	case errors.Is(err, repository.ErrInvalidAssessmentInput), errors.Is(err, service.ErrStatementFormat):
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
	default:
		if middleware.DBErrorResponse(c, err) {
			return
		}
		log.Printf("[finance] %s: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}

// createCreditNote: POST /finance/credit-notes {assessment_id, amount_try, reason} (yönetim).
func createCreditNote(repo *repository.FinanceRepository) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			AssessmentID string          `json:"assessment_id"`
			AmountTRY    decimal.Decimal `json:"amount_try"`
			Reason       string          `json:"reason"`
		}
		if err := c.ShouldBindJSON(&in); err != nil || in.AssessmentID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "assessment_id, amount_try ve reason zorunludur"})
			return
		}
		k := in.AmountTRY.Mul(decimal.NewFromInt(100))
		if !k.Equal(k.Round(0)) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Tutar en fazla iki ondalık hane içerebilir"})
			return
		}
		cn, err := repo.CreateCreditNote(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), in.AssessmentID,
			k.IntPart(), in.Reason)
		if err != nil {
			adjustmentError(c, err, "alacak dekontu")
			return
		}
		c.JSON(http.StatusCreated, gin.H{"credit_note": cn,
			"note": "Dekont kesildi ve borçtan düşüldü; tahsilat defteri zincirine yazıldı. Dekont silinemez, hata ancak gerekçeli ters kayıtla düzeltilir."})
	}
}

// reverseCreditNote: POST /finance/credit-notes/:id/reverse {reason} (yönetim).
func reverseCreditNote(repo *repository.FinanceRepository) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Reason string `json:"reason"`
		}
		_ = c.ShouldBindJSON(&in)
		if err := repo.ReverseCreditNote(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), c.Param("id"), in.Reason); err != nil {
			adjustmentError(c, err, "dekont ters kaydı")
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Dekontun ters kaydı yapıldı; borç geri yüklendi", "note": "Dekont silinmedi; ters kayıt tahsilat defterine yazıldı."})
	}
}

// residentScope: yönetim tüm dekontları, sakin kendi aktif dairelerininkini görür.
func residentScope(c *gin.Context) string {
	if isFinanceManager(c) {
		return ""
	}
	return c.GetString("user_id")
}

// listCreditNotes: GET /finance/credit-notes.
func listCreditNotes(repo *repository.FinanceRepository) gin.HandlerFunc {
	return func(c *gin.Context) {
		list, err := repo.ListCreditNotes(c.Request.Context(), c.GetString("property_id"), residentScope(c))
		if err != nil {
			adjustmentError(c, err, "dekont listesi")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	}
}

// openAssessments: GET /finance/units/:id/open-assessments — dekont için açık tahakkuklar (yönetim).
func openAssessments(repo *repository.FinanceRepository) gin.HandlerFunc {
	return func(c *gin.Context) {
		list, err := repo.OpenAssessmentsForUnit(c.Request.Context(), c.GetString("property_id"), c.Param("id"))
		if err != nil {
			adjustmentError(c, err, "açık tahakkuklar")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	}
}

// creditNotePDF: GET /finance/credit-notes/:id/pdf — sisteme işlenmiş, doğrulama kodlu belge.
func creditNotePDF(repo *repository.FinanceRepository, pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		propertyID := c.GetString("property_id")
		cn, err := repo.GetCreditNote(c.Request.Context(), propertyID, residentScope(c), c.Param("id"))
		if err != nil {
			adjustmentError(c, err, "dekont PDF")
			return
		}
		facts := [][2]string{
			{"Belge no", cn.DocumentNo}, {"Bağımsız bölüm", cn.Unit}, {"Dönem", cn.Period},
			{"Tutar", money.Kurus(cn.AmountKurus).Display()}, {"Gerekçe", cn.Reason},
			{"Düzenleyen", cn.CreatedBy}, {"Düzenlenme", cn.CreatedAt.Format("02.01.2006 15:04")},
		}
		if cn.ReversedAt != nil {
			facts = append(facts, [2]string{"DURUM", "TERS KAYDI YAPILDI (" + cn.ReversedAt.Format("02.01.2006") + "): " + derefStr(cn.ReversalReason)})
		}
		doc := &reports.Document{
			PropertyName: reports.PropertyName(c.Request.Context(), pool, propertyID),
			Title:        "Alacak dekontu " + cn.DocumentNo, GeneratedAt: cn.CreatedAt, Facts: facts,
			Notes: []string{"Bu tutar ilgili tahakkukun borcundan düşülmüştür; tahsilat değildir.",
				"Dekont sistemde kayıtlıdır ve tahsilat defteri zincirine yazılmıştır; silinemez."},
		}
		if err := reports.Write(c.Writer, doc, "pdf", "alacak-dekontu-"+cn.DocumentNo); err != nil {
			log.Printf("[finance] dekont PDF: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Belge üretilemedi"})
		}
	}
}

func derefStr(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}

// importBankStatement: POST /finance/bank-statements (multipart "file": .csv ya da .xlsx).
func importBankStatement(repo *repository.FinanceRepository) gin.HandlerFunc {
	return func(c *gin.Context) {
		fh, err := c.FormFile("file")
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "file alanında CSV ya da Excel (.xlsx) dosyası gönderin"})
			return
		}
		if fh.Size > maxStatementBytes {
			c.JSON(http.StatusRequestEntityTooLarge, gin.H{"error": "Dosya en çok 5 MB olabilir"})
			return
		}
		ext := strings.ToLower(filepath.Ext(fh.Filename))
		if ext != ".csv" && ext != ".xlsx" && ext != ".txt" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Yalnızca .csv ya da .xlsx yüklenebilir"})
			return
		}
		f, err := fh.Open()
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Dosya okunamadı"})
			return
		}
		defer f.Close()
		data, err := io.ReadAll(io.LimitReader(f, maxStatementBytes+1))
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Dosya okunamadı"})
			return
		}
		rows, err := service.ParseStatement(fh.Filename, data)
		if err != nil {
			adjustmentError(c, err, "ekstre ayrıştırma")
			return
		}
		lines := make([]repository.BankLineInput, len(rows))
		for i, r := range rows {
			lines[i] = repository.BankLineInput{LineNo: r.LineNo, Date: r.Date, AmountKurus: r.AmountKurus, Description: r.Description, Reference: r.Reference}
		}
		sum := sha256.Sum256(data)
		propertyID := c.GetString("property_id")
		id, err := repo.ImportBankStatement(c.Request.Context(), propertyID, c.GetString("user_id"), filepath.Base(fh.Filename), hex.EncodeToString(sum[:]), lines)
		if err != nil {
			adjustmentError(c, err, "ekstre yükleme")
			return
		}
		imp, err := repo.GetBankImport(c.Request.Context(), propertyID, id)
		if err != nil {
			adjustmentError(c, err, "ekstre okuma")
			return
		}
		c.JSON(http.StatusCreated, gin.H{"import": imp,
			"note": "Hiçbir ödeme kendiliğinden onaylanmadı. Önerilen eşleşmeleri kontrol edip satır satır onaylayın; aynı hareket bir daha yüklenirse mükerrer sayılır."})
	}
}

func listBankImports(repo *repository.FinanceRepository) gin.HandlerFunc {
	return func(c *gin.Context) {
		list, err := repo.ListBankImports(c.Request.Context(), c.GetString("property_id"))
		if err != nil {
			adjustmentError(c, err, "ekstre listesi")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	}
}

func getBankImport(repo *repository.FinanceRepository) gin.HandlerFunc {
	return func(c *gin.Context) {
		imp, err := repo.GetBankImport(c.Request.Context(), c.GetString("property_id"), c.Param("id"))
		if err != nil {
			adjustmentError(c, err, "ekstre okuma")
			return
		}
		c.JSON(http.StatusOK, imp)
	}
}

// confirmBankLine: POST /finance/bank-statements/lines/:id/confirm {payment_id?} — ödeme aynı işlemde onaylanır.
func confirmBankLine(repo *repository.FinanceRepository) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			PaymentID string `json:"payment_id"`
		}
		_ = c.ShouldBindJSON(&in)
		pid, err := repo.ConfirmBankLine(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), c.Param("id"), strings.TrimSpace(in.PaymentID))
		if err != nil {
			adjustmentError(c, err, "ekstre satırı onayı")
			return
		}
		c.JSON(http.StatusOK, gin.H{"payment_id": pid, "message": "Banka hareketi ödemeyle eşleştirildi; ödeme onaylandı ve borçtan düşüldü"})
	}
}

// ignoreBankLine: POST /finance/bank-statements/lines/:id/ignore {note}.
func ignoreBankLine(repo *repository.FinanceRepository) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Note string `json:"note"`
		}
		_ = c.ShouldBindJSON(&in)
		if err := repo.IgnoreBankLine(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), c.Param("id"), in.Note); err != nil {
			adjustmentError(c, err, "ekstre satırı")
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Satır gerekçesiyle yok sayıldı"})
	}
}
