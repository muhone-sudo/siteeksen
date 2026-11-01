package main

import (
	"context"
	"errors"
	"io"
	"log"
	"strings"
	"time"

	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/pkg/storage"
)

// maxOCRAttempts: OCR çalışmazsa (araç yok, zaman aşımı) bu kadar denendikten sonra fotoğraf elle onaya düşer.
const maxOCRAttempts = 3

// App, servis bağımlılıklarıdır.
type App struct {
	store    *Store
	files    storage.Store
	ocr      OCR
	ai       *AIClient
	notifier *notify.Notifier
}

func strp(s string) *string { return &s }

// startWorker, kuyruğu düzenli aralıkla işler.
func (a *App) startWorker(interval time.Duration) {
	go func() {
		t := time.NewTicker(interval)
		defer t.Stop()
		for {
			ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
			a.processDue(ctx)
			cancel()
			<-t.C
		}
	}()
}

func (a *App) processDue(ctx context.Context) {
	list, err := a.store.Claim(ctx, 10)
	if err != nil {
		log.Printf("[moderation] kuyruk: %v", err)
		return
	}
	for i := range list {
		a.process(ctx, &list[i])
	}
}

// process, bir fotoğrafı denetler: OCR → iletişim bilgisi varsa ret; yoksa yapay zekâ açıksa sor (temiz: onay,
// sakıncalı/hata: elle onay); kapalıysa elle onay.
func (a *App) process(ctx context.Context, it *Item) {
	o := a.evaluate(ctx, it)
	done, err := a.store.Finish(ctx, it.ID, o)
	if err != nil {
		log.Printf("[moderation] sonuç yazılamadı (%s): %v", it.ID, err)
		return
	}
	if done != nil && done.Status == "REJECTED" {
		a.notifyRejected(ctx, done)
	}
}

func (a *App) evaluate(ctx context.Context, it *Item) Outcome {
	data, ctype, err := a.read(ctx, it.StorageKey)
	if errors.Is(err, storage.ErrNotFound) {
		return Outcome{Status: "REPLACED", LastError: strp("dosya bulunamadı (değiştirilmiş ya da silinmiş)")}
	}
	if err != nil {
		return a.retryOrReview(it, "dosya okunamadı: "+err.Error())
	}
	if it.ContentType != "" {
		ctype = it.ContentType
	}
	text, err := a.ocr.Read(ctx, data)
	if err != nil {
		return a.retryOrReview(it, err.Error())
	}
	o := Outcome{OCRText: &text}
	if f := findContacts(text); len(f) > 0 {
		o.Status, o.OCRFindings, o.DecisionSource = "REJECTED", describe(f), strp("OCR")
		o.Reason = strp("Fotoğrafta iletişim bilgisi var (" + strings.Join(describe(f), ", ") + "). " +
			"İletişim bilgisi içermeyen bir fotoğraf yükleyin.")
		return o
	}
	cfg, err := a.store.AISettings(ctx)
	if err != nil {
		o.Status, o.LastError = "REVIEW", strp("yapay zekâ ayarı okunamadı: "+err.Error())
		return o
	}
	if !cfg.Enabled {
		o.Status = "REVIEW"
		return o
	}
	provider := cfg.Provider + " " + cfg.Model
	o.AIProvider = &provider
	v, err := a.ai.Classify(ctx, *cfg, data, ctype)
	switch {
	case errors.Is(err, ErrRefused):
		o.Status, o.AIVerdict, o.AIReason = "REVIEW", strp("UNSAFE"), strp(err.Error())
	case err != nil:
		o.Status, o.AIVerdict, o.AIReason = "REVIEW", strp("ERROR"), strp(err.Error())
	case v.Unsafe:
		o.Status, o.AIVerdict, o.AICategories, o.AIReason = "REVIEW", strp("UNSAFE"), v.Categories, strp(v.Reason)
	default:
		o.Status, o.AIVerdict, o.AIReason, o.DecisionSource = "APPROVED", strp("CLEAN"), strp(v.Reason), strp("AI")
	}
	return o
}

// retryOrReview: geçici hata yeniden denenir; deneme hakkı bitince fotoğraf elle onaya düşer (sessiz onay yok).
func (a *App) retryOrReview(it *Item, msg string) Outcome {
	log.Printf("[moderation] %s: %s (deneme %d)", it.ID, msg, it.Attempts)
	if it.Attempts < maxOCRAttempts {
		return Outcome{Status: "PENDING", LastError: &msg}
	}
	return Outcome{Status: "REVIEW", LastError: &msg}
}

func (a *App) read(ctx context.Context, key string) ([]byte, string, error) {
	if a.files == nil {
		return nil, "", errors.New("dosya deposu yapılandırılmamış")
	}
	rc, obj, err := a.files.Get(ctx, key)
	if err != nil {
		return nil, "", err
	}
	defer rc.Close()
	data, err := io.ReadAll(io.LimitReader(rc, 20<<20))
	return data, obj.ContentType, err
}

// notifyRejected, yükleyene fotoğrafın neden gösterilmediğini bildirir (uygulama içi).
func (a *App) notifyRejected(ctx context.Context, it *Item) {
	if a.notifier == nil {
		log.Printf("[moderation] bildirim altyapısı yok; ret bildirimi GÖNDERİLMEDİ (%s)", it.ID)
		return
	}
	reason := ""
	if it.Reason != nil {
		reason = *it.Reason
	}
	m := notify.Message{Channel: notify.ChannelInApp, Category: notify.CategoryTransactional, Topic: "market.photo.rejected",
		Payload: map[string]any{"photo_id": it.ID, "source": it.Source}, DedupeKey: "market.photo.rejected:" + it.ID + ":" + it.Status}
	switch it.Source {
	case "SERVICE_PHOTO":
		uid := ""
		if it.UploadedBy != nil {
			uid = *it.UploadedBy
		} else if it.AccountID != nil {
			uid, _ = a.store.AccountOwner(ctx, *it.AccountID)
		}
		if it.AccountID == nil || uid == "" {
			return
		}
		m.SupplierAccountID, m.RecipientUserID, m.Recipient = *it.AccountID, uid, uid
		m.Subject, m.Body = "Hizmet fotoğrafınız yayınlanmadı", it.Context+": "+reason
		if it.ServiceID != nil {
			m.Payload["service_id"] = *it.ServiceID
		}
	case "REQUEST_PHOTO":
		if it.PropertyID == nil || it.UploadedBy == nil {
			return
		}
		m.PropertyID, m.RecipientUserID, m.Recipient = *it.PropertyID, *it.UploadedBy, *it.UploadedBy
		m.Subject, m.Body = "Talep fotoğrafınız tedarikçilere gösterilmedi", reason
		if it.RequestID != nil {
			m.Payload["request_id"] = *it.RequestID
		}
	}
	if _, err := a.notifier.Enqueue(ctx, m); err != nil && !errors.Is(err, notify.ErrDuplicate) {
		log.Printf("[moderation] ret bildirimi (%s): %v", it.ID, err)
	}
}
