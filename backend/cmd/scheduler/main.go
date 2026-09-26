// scheduler — ZAMANA BAĞLI bildirimleri üreten işçi.
//
// NEDEN VAR (2026-09-26): modüller bildirimi bir OLAY anında üretiyordu
// (duyuru yayını, kargo girişi…). Gecikmiş aidat, sözleşme ihbar süresi ve
// süresini aşan devriye ise bir olaya değil ZAMANIN GEÇMESİNE bağlıdır;
// bunları kimse üretmiyordu. Aidatı gecikmiş sakin de, ihbar son günü geçen
// yönetim de haberdar olmuyordu.
//
// Çalışma biçimi:
//   - Her turda aktif siteler `scheduler_property_ids()` ile alınır (migration
//     028) ve her site KENDİ KAPSAMIYLA işlenir (pkg/dbscope): işçi uygulama
//     rolüyle bağlanır, site verisine erişimi RLS'e tabidir.
//   - Aynı bildirim iki kez üretilmez: her bildirimin bir `dedupe_key`'i vardır
//     ve `notifications` tablosunda (site, anahtar) tekildir. İşçi yeniden
//     başlasa ya da iki kopya aynı anda çalışsa da sakin aynı hatırlatmayı iki
//     kez almaz.
//   - İki kopya aynı anda çalışırsa biri advisory lock ile turu atlar (gereksiz
//     iş yapılmasın diye; doğruluk dedupe anahtarından gelir).
//   - Bir sitedeki hata diğer siteleri durdurmaz; raporda sayılır.
//
// Kullanım:
//
//	scheduler            # SCHEDULER_INTERVAL (varsayılan 15m) aralıkla çalışır, /health sunar
//	scheduler -once      # tek tur çalışır, raporu JSON yazar ve çıkar (hata varsa çıkış 1)
package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/notify"
)

// lockKey, çok kopyalı çalışmada turu tek kopyaya bırakan advisory lock
// anahtarıdır (cmd/migrate'in anahtarından farklıdır).
const lockKey int64 = 0x5E17E45C4ED

// maxErrors, raporda tutulan en fazla hata metni.
const maxErrors = 10

// JobReport, bir işin tek turdaki sonucudur.
type JobReport struct {
	Job  string `json:"job"`
	What string `json:"what"`
	// Notices, üretilen bildirim konusu sayısıdır (ör. borçlu daire sayısı).
	Notices      int `json:"notices"`
	NoRecipients int `json:"no_recipients"`
	// Aşağıdakiler alıcı bazındadır (pkg/notify.BroadcastResult ile aynı anlam).
	Sent       int      `json:"sent"`
	Pending    int      `json:"pending"`
	Suppressed int      `json:"suppressed"`
	Duplicate  int      `json:"duplicate"`
	Failed     int      `json:"failed"`
	SiteErrors int      `json:"site_errors"`
	Errors     []string `json:"errors,omitempty"`
}

// RunReport, bir turun raporudur.
type RunReport struct {
	StartedAt  time.Time   `json:"started_at"`
	FinishedAt time.Time   `json:"finished_at"`
	Sites      int         `json:"sites"`
	Skipped    string      `json:"skipped,omitempty"`
	Providers  []string    `json:"providers"`
	Jobs       []JobReport `json:"jobs"`
	// Note, sonucu insan diliyle özetler; sağlayıcı yoksa bunu AÇIKÇA söyler.
	Note string `json:"note"`
}

// Failed, turda herhangi bir hata olup olmadığını söyler.
func (r *RunReport) Failed() bool {
	for _, j := range r.Jobs {
		if j.Failed > 0 || j.SiteErrors > 0 {
			return true
		}
	}
	return false
}

// Scheduler, zamanlanmış işleri çalıştırır.
type Scheduler struct {
	pool     *pgxpool.Pool
	notifier *notify.Notifier
	jobs     []job

	mu   sync.Mutex
	last *RunReport
}

// RunOnce, bütün siteler için bütün işleri bir kez çalıştırır.
func (s *Scheduler) RunOnce(ctx context.Context) (*RunReport, error) {
	rep := &RunReport{StartedAt: time.Now().UTC(), Providers: s.notifier.Providers()}
	defer func() {
		rep.FinishedAt = time.Now().UTC()
		s.mu.Lock()
		s.last = rep
		s.mu.Unlock()
	}()

	conn, err := s.pool.Acquire(ctx)
	if err != nil {
		return rep, err
	}
	defer conn.Release()
	var got bool
	if err := conn.QueryRow(ctx, `SELECT pg_try_advisory_lock($1)`, lockKey).Scan(&got); err != nil {
		return rep, err
	}
	if !got {
		rep.Skipped = "Başka bir kopya bu turu çalıştırıyor; atlandı."
		rep.Note = rep.Skipped
		return rep, nil
	}
	defer func() {
		// İptal edilmiş bağlamla kilit bırakılamaz; ayrı bağlam kullanılır.
		if _, err := conn.Exec(context.Background(), `SELECT pg_advisory_unlock($1)`, lockKey); err != nil {
			log.Printf("[scheduler] kilit bırakılamadı: %v", err)
		}
	}()

	sites, err := s.sites(ctx)
	if err != nil {
		return rep, fmt.Errorf("site listesi alınamadı: %w", err)
	}
	rep.Sites = len(sites)

	for _, j := range s.jobs {
		jr := JobReport{Job: j.name, What: j.what}
		for _, pid := range sites {
			if ctx.Err() != nil {
				return rep, ctx.Err()
			}
			s.runJob(ctx, j, pid, &jr)
		}
		rep.Jobs = append(rep.Jobs, jr)
	}
	rep.Note = summarize(rep)
	return rep, nil
}

func (s *Scheduler) sites(ctx context.Context) ([]string, error) {
	rows, err := s.pool.Query(ctx, `SELECT id::text FROM scheduler_property_ids() AS id`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		out = append(out, id)
	}
	return out, rows.Err()
}

func (s *Scheduler) runJob(ctx context.Context, j job, propertyID string, jr *JobReport) {
	addErr := func(msg string) {
		if len(jr.Errors) < maxErrors {
			jr.Errors = append(jr.Errors, msg)
		}
	}
	notices, err := j.run(ctx, s.pool, propertyID)
	if err != nil {
		jr.SiteErrors++
		addErr(fmt.Sprintf("site %s: %v", propertyID, err))
		log.Printf("[scheduler] %s / site %s: %v", j.name, propertyID, err)
		return
	}
	for _, n := range notices {
		jr.Notices++
		if len(n.recipients) == 0 {
			// Alıcısız konu sessizce yutulmaz: raporda görünür (ör. sakini
			// kayıtlı olmayan borçlu daire, yöneticisi atanmamış site).
			jr.NoRecipients++
			continue
		}
		br := s.notifier.Broadcast(ctx, n.msg, n.recipients)
		jr.Sent += br.Sent
		jr.Pending += br.Pending
		jr.Suppressed += br.Suppressed
		jr.Duplicate += br.Duplicate
		jr.Failed += br.Failed
		for _, e := range br.Errors {
			addErr(e)
		}
	}
}

// summarize, sonucu ABARTMADAN anlatır: "gönderildi" yalnızca gerçekten
// iletilen kayıt varsa geçer (pkg/notify ile aynı ilke).
func summarize(r *RunReport) string {
	var created, sent, pending, dup, failed, orphan int
	for _, j := range r.Jobs {
		created += j.Sent + j.Pending + j.Suppressed
		sent += j.Sent
		pending += j.Pending
		dup += j.Duplicate
		failed += j.Failed + j.SiteErrors
		orphan += j.NoRecipients
	}
	s := fmt.Sprintf("%d site tarandı; %d yeni bildirim kaydı oluştu", r.Sites, created)
	if sent > 0 {
		s += fmt.Sprintf(", %d tanesi iletildi", sent)
	}
	if pending > 0 {
		s += fmt.Sprintf(", %d tanesi sağlayıcı olmadığı için kuyrukta BEKLİYOR (GÖNDERİLMEDİ)", pending)
	}
	if dup > 0 {
		s += fmt.Sprintf("; %d tanesi daha önce oluşturulduğu için atlandı", dup)
	}
	if orphan > 0 {
		s += fmt.Sprintf("; %d konunun alıcısı yok", orphan)
	}
	if failed > 0 {
		s += fmt.Sprintf("; %d HATA", failed)
	}
	return s + "."
}

func envDuration(key string, def time.Duration) time.Duration {
	if v := os.Getenv(key); v != "" {
		d, err := time.ParseDuration(v)
		if err != nil || d < time.Minute {
			log.Fatalf("%s geçersiz (%q): en az 1m olmalı, ör. 15m", key, v)
		}
		return d
	}
	return def
}

func main() {
	once := flag.Bool("once", false, "tek tur çalış, raporu yaz ve çık")
	flag.Parse()
	interval := envDuration("SCHEDULER_INTERVAL", 15*time.Minute)

	pool, err := database.Connect(database.NewConfigFromEnv())
	if err != nil {
		log.Fatalf("Veritabanı bağlantısı başarısız: %v", err)
	}
	defer database.Close()

	s := &Scheduler{pool: pool, notifier: notify.New(pool, notify.SendersFromEnv()...), jobs: jobs()}

	if *once {
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
		defer cancel()
		rep, err := s.RunOnce(ctx)
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "  ")
		_ = enc.Encode(rep)
		if err != nil {
			log.Printf("[scheduler] tur başarısız: %v", err)
			os.Exit(1)
		}
		if rep.Failed() {
			os.Exit(1)
		}
		return
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	port := os.Getenv("PORT")
	if port == "" {
		port = "8110"
	}
	mux := http.NewServeMux()
	mux.HandleFunc("/health", func(w http.ResponseWriter, _ *http.Request) {
		s.mu.Lock()
		last := s.last
		s.mu.Unlock()
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{
			"status": "healthy", "service": "scheduler",
			"interval": interval.String(), "last_run": last,
		})
	})
	srv := &http.Server{Addr: ":" + port, Handler: mux, ReadHeaderTimeout: 5 * time.Second}
	go func() {
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("sağlık ucu açılamadı: %v", err)
		}
	}()
	log.Printf("Scheduler başlatıldı: her %s, sağlık :%s", interval, port)

	tick := time.NewTicker(interval)
	defer tick.Stop()
	for {
		runCtx, cancel := context.WithTimeout(ctx, interval)
		rep, err := s.RunOnce(runCtx)
		cancel()
		if err != nil {
			log.Printf("[scheduler] tur başarısız: %v", err)
		} else {
			log.Printf("[scheduler] %s", rep.Note)
		}
		select {
		case <-ctx.Done():
			shutdown, c := context.WithTimeout(context.Background(), 5*time.Second)
			_ = srv.Shutdown(shutdown)
			c()
			return
		case <-tick.C:
		}
	}
}
