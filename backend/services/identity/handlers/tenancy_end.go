package handlers

// Kiracılığın bitişi (altıncı tur D4, migration 069).
//
// Sakin (oturum):
//   POST /users/me/units/:id/tenancy-end               {reason}          — malik ister, kiracı onaylayınca biter
//   POST /users/me/units/:id/tenancy-exit              {reason?}         — kiracı kendi çıkışını bildirir (hemen biter)
//   GET  /users/me/tenancy-requests                                      — kişinin dairelerindeki istekler
//   POST /users/me/tenancy-requests/:id/approve|decline {note?}          — kiracı
//   POST /users/me/tenancy-requests/:id/object          {reason}         — kiracı, yönetim yolunda 7 gün içinde
//   POST /users/me/tenancy-requests/:id/cancel                           — isteği açan malik
//   GET  /users/me/tenancy-requests/:id/documents/:docId                 — kiracı (kendi kiracılığının belgesi)
// Yönetim:
//   GET  /residents/tenancy-requests
//   POST /residents/tenancy-requests                    (multipart: unit_id, reason, document_kind, uyap_code?, password, attest=true, file)
//   POST /residents/tenancy-requests/:id/documents      (multipart: document_kind, uyap_code?, password, attest=true, file)
//   POST /residents/tenancy-requests/:id/complete | cancel {note?}
//   POST /residents/tenancy-requests/:id/reverse        {reason, password}
//   GET  /residents/tenancy-requests/:id/documents/:docId
// Kimlik servisi bildirim tablosuna yazamaz: taraflara SMS/e-posta doğrudan gider, uygulamada istek listesi görünür.

import (
	"bytes"
	"context"
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
	"time"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/pkg/storage"
	"github.com/siteeksen/backend/services/identity/repository"
	"github.com/siteeksen/backend/services/identity/service"
)

const endDocMaxBytes = 10 << 20

var endDocTypes = map[string]string{"application/pdf": "pdf", "image/png": "png", "image/jpeg": "jpg", "image/webp": "webp"}
var endDocKinds = map[string]bool{"TAHLIYE_KARARI": true, "ICRA_TAHLIYE": true, "TASINMA_TUTANAGI": true, "DIGER": true}

func tenancyError(c *gin.Context, err error, fallback string) {
	switch {
	case errors.Is(err, repository.ErrEndRequestNotFound), errors.Is(err, storage.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Bitiş isteği ya da belge bulunamadı"})
	case errors.Is(err, repository.ErrNotOwner), errors.Is(err, repository.ErrNotTenant), errors.Is(err, repository.ErrConflictOfInterest):
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
	case errors.Is(err, repository.ErrNoActiveTenant), errors.Is(err, repository.ErrEndRequestOpen), errors.Is(err, repository.ErrEndRequestState),
		errors.Is(err, repository.ErrObjectionClosed), errors.Is(err, repository.ErrWindowOpen), errors.Is(err, repository.ErrUnitHasTenant):
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
	case errors.Is(err, service.ErrWrongPassword):
		// 401 değil: istemciler 401'de oturumu kapatır (ders 49).
		c.JSON(http.StatusBadRequest, gin.H{"error": "Şifre hatalı; kimlik doğrulanamadı"})
	default:
		ownerError(c, err, fallback)
	}
}

// notifyContacts, taraflara SMS ve e-postayla haber verir; sonuç sayaçlarla döner (sağlayıcısızlık açıkça söylenir).
func notifyContacts(ctx context.Context, contacts []repository.ContactTarget, subject, body string) gin.H {
	sent, failed, notConfigured := 0, 0, 0
	send := func(s notify.Sender, ch, to string) {
		if to == "" {
			return
		}
		if s == nil {
			notConfigured++
			return
		}
		cctx, cancel := context.WithTimeout(ctx, 20*time.Second)
		defer cancel()
		if _, err := s.Send(cctx, notify.Message{Channel: ch, Category: notify.CategoryTransactional, Topic: "identity.tenancy",
			Recipient: to, Subject: subject, Body: "SiteEksen: " + body}); err != nil {
			log.Printf("[identity] kiracılık bildirimi gönderilemedi: %v", err)
			failed++
			return
		}
		sent++
	}
	for _, c := range contacts {
		send(activationSMS, notify.ChannelSMS, c.Phone)
		send(activationEmail, notify.ChannelEmail, c.Email)
	}
	note := fmt.Sprintf("%d ileti gönderildi", sent)
	if notConfigured > 0 {
		note += fmt.Sprintf("; %d kanal için sağlayıcı yapılandırılmamış (kişi uygulamadaki istek listesinden görür)", notConfigured)
	}
	if failed > 0 {
		note += fmt.Sprintf("; %d ileti gönderilemedi", failed)
	}
	return gin.H{"recipients": len(contacts), "sent": sent, "failed": failed, "not_configured": notConfigured, "note": note}
}

func bindReason(c *gin.Context, required bool) (string, bool) {
	var body struct {
		Reason string `json:"reason"`
		Note   string `json:"note"`
	}
	_ = c.ShouldBindJSON(&body)
	r := strings.TrimSpace(body.Reason + body.Note)
	if required && len([]rune(r)) < 5 {
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Gerekçe en az 5 karakter olmalı"})
		return "", false
	}
	return r, true
}

// OwnerRequestTenancyEnd: malik kiracılığın bitmesini ister.
func OwnerRequestTenancyEnd(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		reason, ok := bindReason(c, true)
		if !ok {
			return
		}
		id, contacts, err := svc.OwnerRequestEnd(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), c.Param("id"), reason)
		if err != nil {
			tenancyError(c, err, "Bitiş isteği açılamadı")
			return
		}
		c.JSON(http.StatusCreated, gin.H{"id": id, "status": "PENDING_TENANT",
			"delivery": notifyContacts(c.Request.Context(), contacts, "Kiracılık bitiş isteği",
				"Maliki olduğu dairedeki kiracılığınızın bitmesini istedi. Uygulamadaki kiracılık işlemlerinden onaylayabilir ya da reddedebilirsiniz; siz onaylamadan kiracılığınız bitmez."),
			"message": "İstek kiracıya iletildi. Kiracı onaylayınca kiracılık biter; reddederse sürer."})
	}
}

// TenantExitHandler: kiracı kendi çıkışını bildirir.
func TenantExitHandler(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		reason, _ := bindReason(c, false)
		id, contacts, err := svc.TenantExit(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), c.Param("id"), reason)
		if err != nil {
			tenancyError(c, err, "Çıkış bildirilemedi")
			return
		}
		c.JSON(http.StatusOK, gin.H{"id": id, "status": "COMPLETED",
			"delivery": notifyContacts(c.Request.Context(), contacts, "Kiracı çıkışı", "Dairenizdeki kiracı çıkışını bildirdi; daire boş olarak işaretlendi."),
			"message":  "Kiracılığınız bugün itibarıyla sona erdi; bu daire için bildirim almazsınız. Geçmiş kayıtlarınız silinmez."})
	}
}

// MyTenancyRequests: kişinin dairelerindeki bitiş istekleri.
func MyTenancyRequests(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		list, err := svc.MyEndRequests(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"))
		if err != nil {
			tenancyError(c, err, "Bitiş istekleri alınamadı")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	}
}

// TenantRespondHandler: kiracının onayı ya da reddi.
func TenantRespondHandler(svc *service.ResidentService, approve bool) gin.HandlerFunc {
	return func(c *gin.Context) {
		note, _ := bindReason(c, false)
		contacts, err := svc.TenantRespond(c.Request.Context(), c.GetString("user_id"), c.Param("id"), approve, note)
		if err != nil {
			tenancyError(c, err, "İstek yanıtlanamadı")
			return
		}
		msg, body := "İsteği reddettiniz; kiracılığınız sürüyor.", "Kiracı, kiracılığın bitmesi isteğini reddetti; kiracılık sürüyor."
		if approve {
			msg, body = "Onayladınız; kiracılığınız bugün itibarıyla sona erdi.", "Kiracı onayladı; kiracılık sona erdi, daire boş olarak işaretlendi."
		}
		c.JSON(http.StatusOK, gin.H{"approved": approve, "message": msg,
			"delivery": notifyContacts(c.Request.Context(), contacts, "Kiracılık bitiş isteği", body)})
	}
}

// TenantObjectHandler: kiracının yönetim yoluna itirazı.
func TenantObjectHandler(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		reason, ok := bindReason(c, true)
		if !ok {
			return
		}
		if err := svc.TenantObject(c.Request.Context(), c.GetString("user_id"), c.Param("id"), reason); err != nil {
			tenancyError(c, err, "İtiraz kaydedilemedi")
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "SUSPENDED",
			"message": "İtirazınız kaydedildi; işlem askıya alındı. Yönetim ancak sizin onayınızla ya da yeni bir belgeyle (yeni 7 günlük itiraz süresiyle) ilerleyebilir."})
	}
}

// OwnerCancelHandler: malik isteğini geri çeker.
func OwnerCancelHandler(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		if err := svc.OwnerCancel(c.Request.Context(), c.GetString("user_id"), c.Param("id")); err != nil {
			tenancyError(c, err, "İstek geri çekilemedi")
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "CANCELLED", "message": "İsteğinizi geri çektiniz."})
	}
}

// ManagementTenancyRequests: yönetim listesi.
func ManagementTenancyRequests(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		list, err := svc.EndRequests(c.Request.Context(), c.GetString("property_id"), getRoles(c))
		if err != nil {
			tenancyError(c, err, "Bitiş istekleri alınamadı")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list, "attestation_text": service.AttestationText})
	}
}

// readEndDocument: yönetim yolunun çok parçalı gövdesini okur, şifreyle kimliği doğrular ve belgeyi depoya yazar.
func readEndDocument(c *gin.Context, svc *service.ResidentService, store storage.Store) (*repository.NewDocument, bool) {
	if store == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Dosya deposu yapılandırılmamış; yönetim yolu belgesiz yürütülemez.",
			"note": "STORAGE_BACKEND (local|s3) ayarlanınca belge saklanır."})
		return nil, false
	}
	kind := strings.ToUpper(strings.TrimSpace(c.PostForm("document_kind")))
	if !endDocKinds[kind] {
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "document_kind TAHLIYE_KARARI, ICRA_TAHLIYE, TASINMA_TUTANAGI ya da DIGER olmalı"})
		return nil, false
	}
	if c.PostForm("attest") != "true" {
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Beyan onaylanmadan belge yüklenemez", "attestation_text": service.AttestationText})
		return nil, false
	}
	uyap := strings.TrimSpace(c.PostForm("uyap_code"))
	if len(uyap) > 64 {
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "UYAP doğrulama kodu en çok 64 karakter"})
		return nil, false
	}
	if err := svc.ConfirmManager(c.Request.Context(), c.GetString("user_id"), getRoles(c), c.PostForm("password")); err != nil {
		tenancyError(c, err, "Kimlik doğrulanamadı")
		return nil, false
	}
	fh, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "file alanında belge (PDF ya da görsel) gönderin"})
		return nil, false
	}
	f, err := fh.Open()
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Dosya okunamadı"})
		return nil, false
	}
	data, err := io.ReadAll(io.LimitReader(f, endDocMaxBytes+1))
	f.Close()
	if err != nil || len(data) == 0 || len(data) > endDocMaxBytes {
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": fmt.Sprintf("Dosya boş ya da %d MB sınırını aşıyor", endDocMaxBytes>>20)})
		return nil, false
	}
	ct := http.DetectContentType(data)
	ext, ok := endDocTypes[ct]
	if !ok {
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Yalnızca PDF, PNG, JPEG ya da WEBP belge kabul edilir (gelen: " + ct + ")"})
		return nil, false
	}
	sum := sha256.Sum256(data)
	sha := hex.EncodeToString(sum[:])
	// Anahtar yüklemeye özgüdür: aynı içerik ikinci kez yüklenip işlem reddedilirse silinen dosya ilkini götürmemeli.
	key := fmt.Sprintf("tenancy-end/%s/%d-%s.%s", c.GetString("property_id"), time.Now().UnixNano(), sha[:16], ext)
	if _, err := store.Put(c.Request.Context(), key, ct, bytes.NewReader(data)); err != nil {
		log.Printf("[identity] belge depoya yazılamadı: %v", err)
		c.JSON(http.StatusBadGateway, gin.H{"error": "Belge depoya yazılamadı; biraz sonra yeniden deneyin"})
		return nil, false
	}
	name := strings.TrimSpace(filepath.Base(fh.Filename))
	if name == "" || name == "." || len([]rune(name)) > 200 {
		name = "belge." + ext
	}
	return &repository.NewDocument{DocumentKind: kind, UyapCode: uyap, StorageKey: key, FileName: name, ContentType: ct,
		SHA256: sha, SizeBytes: int64(len(data)), AttestationText: service.AttestationText, IP: c.ClientIP()}, true
}

const managementNotice = "Site yönetimi, kiracılığınızın bittiğine dair bir belge yükledi. Belgeyi uygulamadaki kiracılık işlemlerinden " +
	"görebilirsiniz. Belge size ait değilse ya da hatalıysa 7 gün içinde uygulamadan itiraz edin; itirazınızla işlem askıya alınır."

// ManagementStartHandler: yönetim yolunu başlatır.
func ManagementStartHandler(svc *service.ResidentService, store storage.Store) gin.HandlerFunc {
	return func(c *gin.Context) {
		unitID, reason := strings.TrimSpace(c.PostForm("unit_id")), strings.TrimSpace(c.PostForm("reason"))
		if unitID == "" || len([]rune(reason)) < 10 {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "unit_id ve en az 10 karakterlik gerekçe zorunludur"})
			return
		}
		doc, ok := readEndDocument(c, svc, store)
		if !ok {
			return
		}
		id, contacts, err := svc.ManagementStart(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), unitID, reason, *doc)
		if err != nil {
			_ = store.Delete(c.Request.Context(), doc.StorageKey)
			tenancyError(c, err, "Yönetim yolu başlatılamadı")
			return
		}
		c.JSON(http.StatusCreated, gin.H{"id": id, "status": "OBJECTION_WINDOW",
			"objection_deadline": time.Now().Add(repository.ObjectionWindow),
			"delivery":           notifyContacts(c.Request.Context(), contacts, "Kiracılık bitişi — belge", managementNotice),
			"message":            "Kiracıya bildirildi. 7 günlük itiraz süresi itirazsız dolarsa 'tamamla' ile kiracılığı bitirebilirsiniz."})
	}
}

// ManagementNewDocumentHandler: askıdaki yönetim yoluna yeni belge.
func ManagementNewDocumentHandler(svc *service.ResidentService, store storage.Store) gin.HandlerFunc {
	return func(c *gin.Context) {
		doc, ok := readEndDocument(c, svc, store)
		if !ok {
			return
		}
		contacts, err := svc.ManagementNewDocument(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), c.Param("id"), *doc)
		if err != nil {
			_ = store.Delete(c.Request.Context(), doc.StorageKey)
			tenancyError(c, err, "Belge eklenemedi")
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "OBJECTION_WINDOW", "objection_deadline": time.Now().Add(repository.ObjectionWindow),
			"delivery": notifyContacts(c.Request.Context(), contacts, "Kiracılık bitişi — yeni belge", managementNotice),
			"message":  "Yeni belge eklendi; kiracı için yeni 7 günlük itiraz süresi başladı."})
	}
}

// ManagementCompleteHandler: süresi itirazsız dolan yönetim yolunu tamamlar.
func ManagementCompleteHandler(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		contacts, err := svc.ManagementComplete(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), getRoles(c), c.Param("id"))
		if err != nil {
			tenancyError(c, err, "Kiracılık bitirilemedi")
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "COMPLETED",
			"delivery": notifyContacts(c.Request.Context(), contacts, "Kiracılık bitti", "İtiraz süresi dolduğu için kiracılığınız site yönetimince sona erdirildi. Belge hatalıysa yönetime başvurun; kayıt geri açılabilir."),
			"message":  "Kiracılık sona erdi; daire boş olarak işaretlendi. Belge sahte çıkarsa 'geri al' ile kiracılık aynı kayıtla açılır."})
	}
}

// ManagementCancelHandler: açık yönetim yolunu iptal eder.
func ManagementCancelHandler(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		note, _ := bindReason(c, false)
		if err := svc.ManagementCancel(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), getRoles(c), c.Param("id"), note); err != nil {
			tenancyError(c, err, "İptal edilemedi")
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "CANCELLED", "message": "Yönetim yolu iptal edildi; kiracılık sürüyor."})
	}
}

// ManagementReverseHandler: yönetim yoluyla biten kiracılığı geri açar.
func ManagementReverseHandler(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var body struct {
			Reason   string `json:"reason"`
			Password string `json:"password"`
		}
		if err := c.ShouldBindJSON(&body); err != nil || len([]rune(strings.TrimSpace(body.Reason))) < 10 {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "En az 10 karakterlik gerekçe ve şifre zorunludur"})
			return
		}
		if err := svc.ConfirmManager(c.Request.Context(), c.GetString("user_id"), getRoles(c), body.Password); err != nil {
			tenancyError(c, err, "Kimlik doğrulanamadı")
			return
		}
		contacts, err := svc.ManagementReverse(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), c.Param("id"), body.Reason)
		if err != nil {
			tenancyError(c, err, "Geri alınamadı")
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "REVERSED",
			"delivery": notifyContacts(c.Request.Context(), contacts, "Kiracılık geri açıldı", "Site yönetimi, kiracılığınızı sona erdiren işlemi geri aldı; kiracılığınız aynı kayıtla sürüyor."),
			"message":  "Kiracılık aynı kayıtla geri açıldı."})
	}
}

// EndDocumentDownload: belge içeriği (kiracı kendi kiracılığının; yönetim sitesinin).
func EndDocumentDownload(svc *service.ResidentService, store storage.Store) gin.HandlerFunc {
	return func(c *gin.Context) {
		if store == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Dosya deposu yapılandırılmamış"})
			return
		}
		ctx := c.Request.Context()
		d, err := svc.EndDocument(ctx, c.GetString("property_id"), c.GetString("user_id"), getRoles(c), c.Param("id"), c.Param("docId"))
		if err != nil {
			tenancyError(c, err, "Belge alınamadı")
			return
		}
		body, _, err := store.Get(ctx, d.StorageKey)
		if err != nil {
			tenancyError(c, err, "Belge alınamadı")
			return
		}
		defer body.Close()
		c.Header("Content-Type", d.ContentType)
		c.Header("Content-Disposition", mime.FormatMediaType("attachment", map[string]string{"filename": d.FileName}))
		c.Header("X-Content-SHA256", d.SHA256)
		c.Status(http.StatusOK)
		if _, err := io.Copy(c.Writer, body); err != nil {
			log.Printf("[identity] belge gönderilemedi: %v", err)
		}
	}
}
