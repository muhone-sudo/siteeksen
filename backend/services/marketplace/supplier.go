package main

// Tedarikçi uçları (FAZ M3): hesap, belgeler, işletmeler, hizmet kalemleri. Yalnız SUPPLIER rolü; her işlem
// kişinin kendi hesabının kapsamında (dbscope.ForSupplier) çalışır.

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/siteeksen/backend/pkg/storage"
	"github.com/siteeksen/backend/services/marketplace/store"
)

const (
	maxDocumentBytes = 10 << 20
	maxPhotoBytes    = 5 << 20
)

var documentTypes = map[string]bool{"application/pdf": true, "image/jpeg": true, "image/png": true}
var photoTypes = map[string]bool{"image/jpeg": true, "image/png": true, "image/webp": true}

// accountID, oturumdaki tedarikçinin hesabını çözer; hesap yoksa 404 NO_ACCOUNT yazar ve boş döner.
func (a *App) accountID(c *gin.Context) string {
	id, err := a.store.AccountIDOfUser(c.Request.Context(), c.GetString("user_id"))
	if err != nil {
		fail(c, err, "tedarikçi hesabı")
		return ""
	}
	if id == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "Önce tedarikçi hesabınızı oluşturun", "code": "NO_ACCOUNT"})
		return ""
	}
	return id
}

func (a *App) createAccount(c *gin.Context) {
	var in struct {
		store.AccountInput
		TermsAccepted bool `json:"terms_accepted"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek gövdesi"})
		return
	}
	if !in.TermsAccepted {
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Tedarikçi üyelik koşullarının kabulü zorunludur"})
		return
	}
	acc, err := a.store.CreateAccount(c.Request.Context(), c.GetString("user_id"), in.AccountInput)
	if err != nil {
		fail(c, err, "tedarikçi hesabı açma")
		return
	}
	c.JSON(http.StatusCreated, acc)
}

func (a *App) updateAccount(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	var in store.AccountInput
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek gövdesi"})
		return
	}
	acc, err := a.store.UpdateAccount(c.Request.Context(), id, in)
	if err != nil {
		fail(c, err, "hesap güncelleme")
		return
	}
	c.JSON(http.StatusOK, acc)
}

func (a *App) submitAccount(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	acc, err := a.store.SubmitAccount(c.Request.Context(), id)
	if err != nil {
		fail(c, err, "hesabı incelemeye gönderme")
		return
	}
	c.JSON(http.StatusOK, acc)
}

// readUpload, çok parçalı formdaki "file" alanını okur; boyut ve içerik türü (dosyanın kendisinden) denetlenir.
func readUpload(c *gin.Context, max int64, allowed map[string]bool) ([]byte, string, string, bool) {
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, max+1<<20)
	fh, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Dosya (file) zorunludur"})
		return nil, "", "", false
	}
	if fh.Size > max {
		c.JSON(http.StatusRequestEntityTooLarge, gin.H{"error": fmt.Sprintf("Dosya en çok %d MB olabilir", max>>20)})
		return nil, "", "", false
	}
	f, err := fh.Open()
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Dosya okunamadı"})
		return nil, "", "", false
	}
	defer f.Close()
	data, err := io.ReadAll(io.LimitReader(f, max+1))
	if err != nil || int64(len(data)) > max || len(data) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Dosya boş ya da çok büyük"})
		return nil, "", "", false
	}
	ctype := http.DetectContentType(data)
	if i := strings.Index(ctype, ";"); i > 0 {
		ctype = ctype[:i]
	}
	if !allowed[ctype] {
		kinds := []string{}
		for k := range allowed {
			kinds = append(kinds, k)
		}
		c.JSON(http.StatusUnsupportedMediaType, gin.H{"error": "Bu dosya türü kabul edilmiyor: " + ctype, "valid_types": kinds})
		return nil, "", "", false
	}
	name := filepath.Base(strings.TrimSpace(fh.Filename))
	if name == "." || name == "/" || name == "" {
		name = "belge"
	}
	return data, ctype, name, true
}

func (a *App) needStorage(c *gin.Context) bool {
	if a.files == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Dosya deposu yapılandırılmamış (STORAGE_BACKEND)", "code": "NO_STORAGE"})
		return false
	}
	return true
}

func (a *App) uploadDocument(c *gin.Context) {
	id := a.accountID(c)
	if id == "" || !a.needStorage(c) {
		return
	}
	docType := c.PostForm("doc_type")
	ok := false
	for _, t := range store.DocumentTypes {
		ok = ok || t == docType
	}
	if !ok {
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Belge türü geçersiz", "valid_types": store.DocumentTypes})
		return
	}
	if err := a.store.CanUploadDocument(c.Request.Context(), id); err != nil {
		fail(c, err, "belge yükleme")
		return
	}
	data, ctype, name, ok := readUpload(c, maxDocumentBytes, documentTypes)
	if !ok {
		return
	}
	key := fmt.Sprintf("market/%s/docs/%s", id, uuid.NewString())
	obj, err := a.files.Put(c.Request.Context(), key, ctype, bytes.NewReader(data))
	if err != nil {
		fail(c, err, "belge saklama")
		return
	}
	d, err := a.store.AddDocument(c.Request.Context(), id, c.GetString("user_id"), store.Document{
		DocType: docType, FileName: name, ContentType: ctype, SizeBytes: obj.Size, SHA256: obj.SHA256, StorageKey: key})
	if err != nil {
		_ = a.files.Delete(c.Request.Context(), key)
		fail(c, err, "belge kaydı")
		return
	}
	c.JSON(http.StatusCreated, d)
}

func (a *App) listDocuments(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	list, err := a.store.Documents(c.Request.Context(), id)
	if err != nil {
		fail(c, err, "belge listesi")
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": list})
}

func (a *App) downloadDocument(c *gin.Context) {
	id := a.accountID(c)
	if id == "" || !a.needStorage(c) {
		return
	}
	d, err := a.store.DocumentForOwner(c.Request.Context(), id, c.Param("id"), c.GetString("user_id"))
	if err != nil {
		fail(c, err, "belge")
		return
	}
	a.serveFile(c, d.StorageKey, d.ContentType, d.FileName)
}

// serveFile, depodaki dosyayı indirme olarak verir.
func (a *App) serveFile(c *gin.Context, key, ctype, name string) {
	rc, obj, err := a.files.Get(c.Request.Context(), key)
	if errors.Is(err, storage.ErrNotFound) {
		c.JSON(http.StatusNotFound, gin.H{"error": "Dosya depoda bulunamadı"})
		return
	}
	if err != nil {
		fail(c, err, "dosya okuma")
		return
	}
	defer rc.Close()
	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=%q", name))
	c.Header("X-Content-Type-Options", "nosniff")
	c.DataFromReader(http.StatusOK, obj.Size, ctype, rc, nil)
}

func (a *App) deleteDocument(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	key, err := a.store.DeleteDocument(c.Request.Context(), id, c.Param("id"))
	if err != nil {
		fail(c, err, "belge silme")
		return
	}
	if a.files != nil {
		if err := a.files.Delete(c.Request.Context(), key); err != nil {
			log.Printf("[marketplace] silinen belgenin dosyası depodan kaldırılamadı (%s): %v", key, err)
		}
	}
	c.JSON(http.StatusOK, gin.H{"message": "Belge silindi"})
}

func (a *App) listBusinesses(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	list, err := a.store.Businesses(c.Request.Context(), id)
	if err != nil {
		fail(c, err, "işletme listesi")
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": list})
}

func (a *App) getBusiness(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	b, err := a.store.Business(c.Request.Context(), id, c.Param("id"))
	if err != nil {
		fail(c, err, "işletme")
		return
	}
	c.JSON(http.StatusOK, b)
}

func (a *App) saveBusiness(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	var in store.BusinessInput
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek gövdesi"})
		return
	}
	var b *store.Business
	var err error
	status := http.StatusOK
	if bid := c.Param("id"); bid != "" {
		b, err = a.store.UpdateBusiness(c.Request.Context(), id, bid, in)
	} else {
		b, err = a.store.CreateBusiness(c.Request.Context(), id, in)
		status = http.StatusCreated
	}
	if err != nil {
		fail(c, err, "işletme kaydı")
		return
	}
	c.JSON(status, b)
}

func (a *App) businessAction(action string) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := a.accountID(c)
		if id == "" {
			return
		}
		b, err := a.store.SetBusinessStatus(c.Request.Context(), id, c.Param("id"), action)
		if err != nil {
			fail(c, err, "işletme durumu")
			return
		}
		c.JSON(http.StatusOK, b)
	}
}

func (a *App) listServices(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	list, err := a.store.Services(c.Request.Context(), id, c.Param("id"))
	if err != nil {
		fail(c, err, "hizmet listesi")
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": list})
}

func (a *App) saveService(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	var in store.ServiceInput
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek gövdesi"})
		return
	}
	var x *store.Service
	var err error
	status := http.StatusOK
	if c.Request.Method == http.MethodPost {
		x, err = a.store.CreateService(c.Request.Context(), id, c.Param("id"), in)
		status = http.StatusCreated
	} else {
		x, err = a.store.UpdateService(c.Request.Context(), id, c.Param("id"), in)
	}
	if err != nil {
		fail(c, err, "hizmet kaydı")
		return
	}
	c.JSON(status, x)
}

func (a *App) deleteService(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	key, err := a.store.DeleteService(c.Request.Context(), id, c.Param("id"))
	if err != nil {
		fail(c, err, "hizmet silme")
		return
	}
	if key != nil && a.files != nil {
		_ = a.files.Delete(c.Request.Context(), *key)
	}
	c.JSON(http.StatusOK, gin.H{"message": "Hizmet silindi"})
}

func (a *App) uploadServicePhoto(c *gin.Context) {
	id := a.accountID(c)
	if id == "" || !a.needStorage(c) {
		return
	}
	data, ctype, _, ok := readUpload(c, maxPhotoBytes, photoTypes)
	if !ok {
		return
	}
	key := fmt.Sprintf("market/%s/photos/%s", id, uuid.NewString())
	if _, err := a.files.Put(c.Request.Context(), key, ctype, bytes.NewReader(data)); err != nil {
		fail(c, err, "fotoğraf saklama")
		return
	}
	old, err := a.store.SetServicePhoto(c.Request.Context(), id, c.GetString("user_id"), c.Param("id"), key, ctype)
	if err != nil {
		_ = a.files.Delete(c.Request.Context(), key)
		fail(c, err, "fotoğraf kaydı")
		return
	}
	if old != nil {
		_ = a.files.Delete(c.Request.Context(), *old)
	}
	c.JSON(http.StatusOK, gin.H{"message": "Fotoğraf yüklendi; platform denetiminden geçince vitrinde görünür"})
}

// servicePhoto: vitrindeki hizmetin fotoğrafı (oturum açmış herkes) ya da tedarikçinin kendi kalemi.
func (a *App) servicePhoto(c *gin.Context) {
	if !a.needStorage(c) {
		return
	}
	acc := ""
	if hasRole(c, "SUPPLIER") {
		acc, _ = a.store.AccountIDOfUser(c.Request.Context(), c.GetString("user_id"))
	}
	key, err := a.store.ServicePhotoKey(c.Request.Context(), acc, c.Param("id"))
	if err != nil {
		fail(c, err, "fotoğraf")
		return
	}
	rc, obj, err := a.files.Get(c.Request.Context(), key)
	if err != nil {
		fail(c, err, "fotoğraf okuma")
		return
	}
	defer rc.Close()
	c.Header("X-Content-Type-Options", "nosniff")
	c.Header("Cache-Control", "private, max-age=300")
	c.DataFromReader(http.StatusOK, obj.Size, obj.ContentType, rc, nil)
}

func (a *App) supplierNotifications(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	list, unread, err := a.store.SupplierNotifications(c.Request.Context(), id, c.GetString("user_id"))
	if err != nil {
		fail(c, err, "bildirimler")
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": list, "unread": unread})
}

func (a *App) readSupplierNotifications(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	var in struct {
		IDs []string `json:"ids"`
	}
	_ = c.ShouldBindJSON(&in)
	if in.IDs == nil {
		in.IDs = []string{}
	}
	n, err := a.store.MarkSupplierNotificationsRead(c.Request.Context(), id, c.GetString("user_id"), in.IDs)
	if err != nil {
		fail(c, err, "okundu bilgisi")
		return
	}
	c.JSON(http.StatusOK, gin.H{"marked": n})
}
