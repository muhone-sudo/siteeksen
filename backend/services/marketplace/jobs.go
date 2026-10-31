package main

// Pazaryerinin zamanlı işleri (FAZ M5–M7): paket aidatı yenileme, yarıda kalan bakiye yüklemelerinin uzlaştırılması
// ve (sonraki aşamalarda) öncelik penceresi bildirimi, talep süresi, otomatik tamamlama. Servisin içinde düzenli
// aralıkla çalışır; birden çok kopya varsa veritabanı danışma kilidi turu tek kopyaya bırakır.
//
//	MARKET_JOBS_INTERVAL      (vars. 1m)  — tur aralığı
//	MARKET_TOPUP_RECONCILE_AGE (vars. 20m) — sonucu bu kadar süredir gelmemiş yükleme sağlayıcıdan sorulur, belirsizse kapanır

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/services/marketplace/store"
)

// marketJobsLock, danışma kilidinin anahtarıdır (pazaryeri işlerine özgü sabit).
const marketJobsLock = 0x4d4b5431 // "MKT1"

func envDuration(name string, def time.Duration) time.Duration {
	v := os.Getenv(name)
	if v == "" {
		return def
	}
	d, err := time.ParseDuration(v)
	if err != nil || d < time.Second {
		log.Fatalf("[marketplace] %s geçersiz: %q", name, v)
	}
	return d
}

func (a *App) startJobs() {
	interval := envDuration("MARKET_JOBS_INTERVAL", time.Minute)
	age := envDuration("MARKET_TOPUP_RECONCILE_AGE", 20*time.Minute)
	go func() {
		t := time.NewTicker(interval)
		defer t.Stop()
		for range t.C {
			ctx, cancel := context.WithTimeout(context.Background(), interval*5)
			a.runJobs(ctx, age)
			cancel()
		}
	}()
}

func (a *App) runJobs(ctx context.Context, topupAge time.Duration) {
	release, ok, err := a.store.TryJobsLock(ctx, marketJobsLock)
	if err != nil {
		log.Printf("[marketplace] iş kilidi: %v", err)
		return
	}
	if !ok {
		return
	}
	defer release()
	if outs, err := a.store.RenewPackages(ctx); err != nil {
		log.Printf("[marketplace] aidat yenileme: %v", err)
	} else {
		for _, o := range outs {
			a.notifyRenewal(ctx, o)
		}
	}
	if list, err := a.store.StaleTopups(ctx, topupAge); err != nil {
		log.Printf("[marketplace] yükleme uzlaştırma: %v", err)
	} else {
		for i := range list {
			if st, _, err := a.settleTopup(ctx, &list[i], true); err != nil {
				log.Printf("[marketplace] yükleme uzlaştırma (%s): %v", list[i].ID, err)
			} else {
				log.Printf("[marketplace] yükleme uzlaştırma %s → %s", list[i].ID, st)
			}
		}
	}
}

func (a *App) notifyRenewal(ctx context.Context, o store.RenewalOutcome) {
	day := time.Now().Format("2006-01-02")
	switch o.Result {
	case "DOWNGRADED":
		a.notifyJob(ctx, o.AccountID, "market.package.downgraded", "Paketiniz yenilenemedi",
			o.PackageName+" paketinin aylık aidatı için bakiye yetmedi; hesabınız ücretsiz pakete geçti. Bakiye yükleyip paketinizi yeniden seçebilirsiniz.",
			"market.package.downgraded:"+o.AccountID+":"+day)
	case "RENEWED":
		a.lowBalanceCheck(ctx, o.AccountID, o.BalanceAfter)
	}
}

// notifyJob, zamanlı işin tedarikçiye uygulama içi bildirimidir (dedupe anahtarıyla bir kez).
func (a *App) notifyJob(ctx context.Context, accountID, topic, subject, body, dedupe string) {
	if a.notifier == nil {
		return
	}
	c, err := a.store.AccountContact(ctx, "", accountID)
	if err != nil {
		log.Printf("[marketplace] bildirim alıcısı (%s): %v", topic, err)
		return
	}
	for _, ch := range []string{notify.ChannelInApp, notify.ChannelEmail} {
		addr := c.UserID
		if ch == notify.ChannelEmail {
			if c.Email == "" {
				continue
			}
			addr = c.Email
		}
		_, err := a.notifier.Enqueue(ctx, notify.Message{SupplierAccountID: accountID, RecipientUserID: c.UserID, Recipient: addr,
			Channel: ch, Topic: topic, Subject: subject, Body: body, DedupeKey: fmt.Sprintf("%s:%s", dedupe, ch)})
		if err != nil && err != notify.ErrDuplicate {
			log.Printf("[marketplace] bildirim (%s/%s): %v", topic, ch, err)
		}
	}
}
