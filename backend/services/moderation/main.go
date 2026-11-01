// moderation-service — fotoğraf denetimi (FAZ M13.4, migration 082).
//
// Pazaryerine yüklenen hizmet ve talep fotoğrafları kuyruğa girer. Bu servis kuyruğu işler: önce OCR (Tesseract) ile
// görseldeki yazıyı okur, telefon/e-posta/web adresi varsa fotoğrafı reddeder; yoksa platformun açtığı yapay zekâ
// sağlayıcısına sorar (temiz: onay; sakıncalı ya da hata: platformun elle onay kuyruğu). Yapay zekâ kapalıysa her
// fotoğraf elle onaya düşer. Platform yöneticisi fotoğrafları görür, onaylar ya da gerekçeyle reddeder.
package main

import (
	"errors"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/pkg/pii"
	"github.com/siteeksen/backend/pkg/storage"
)

func main() {
	pool, err := database.Connect(database.NewConfigFromEnv())
	if err != nil {
		log.Fatalf("Veritabanı bağlantısı başarısız: %v", err)
	}
	defer database.Close()

	files, ferr := storage.FromEnv()
	if errors.Is(ferr, storage.ErrNotConfigured) && os.Getenv("STORAGE_BACKEND") == "" {
		log.Printf("[moderation] dosya deposu yapılandırılmamış: fotoğraflar okunamaz, kuyruk elle onaya düşer (STORAGE_BACKEND)")
		files = nil
	} else if ferr != nil {
		log.Fatalf("Dosya deposu yapılandırması hatalı: %v", ferr)
	}
	// Sağlayıcı API anahtarı ve parolası şifreli saklanır. Anahtar yoksa servis açılır ama gizli değer kaydedilemez.
	vault, verr := pii.FromEnv()
	if verr != nil {
		log.Printf("[moderation] şifreleme anahtarı yok (%s): yapay zekâ sağlayıcısının gizli değerleri kaydedilemez", pii.EnvKey)
		vault = nil
	}
	ocr := OCR{Command: envOr("OCR_COMMAND", "tesseract"), Langs: envOr("OCR_LANGS", "tur+eng"), Timeout: 60 * time.Second}
	_, lookErr := exec.LookPath(ocr.Command)
	if lookErr != nil {
		log.Printf("[moderation] OCR aracı bulunamadı (%s): fotoğraflar denenip elle onaya düşer", ocr.Command)
	}
	interval, err := time.ParseDuration(envOr("MODERATION_INTERVAL", "15s"))
	if err != nil || interval <= 0 {
		log.Fatalf("geçersiz MODERATION_INTERVAL")
	}

	app := &App{store: &Store{pool: pool, vault: vault}, files: files, ocr: ocr, ai: newAIClient(), notifier: notify.FromEnvOrNil(pool)}
	app.startWorker(interval)

	r := middleware.NewRouter("moderation")
	r.Use(middleware.UUIDParams())
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "healthy", "service": "moderation", "storage": files != nil, "ocr": lookErr == nil,
			"encryption": vault != nil})
	})
	api := r.Group("/api/v1/moderation")
	api.Use(middleware.AuthMiddleware(pool), middleware.RequireRole(middleware.RolePlatformAdmin), middleware.AuditLog(pool, "moderation"))
	api.GET("/photos", app.list)
	api.GET("/photos/:id/image", app.image)
	api.POST("/photos/:id/approve", app.decide(true))
	api.POST("/photos/:id/reject", app.decide(false))
	api.POST("/photos/:id/recheck", app.recheck)
	api.GET("/ai-settings", app.aiSettings)
	api.PUT("/ai-settings", app.saveAISettings)
	api.POST("/ai-settings/test", app.testAI)

	port := envOr("PORT", "8112")
	log.Printf("Moderation Service başlatıldı: :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

func envOr(k, def string) string {
	if v := strings.TrimSpace(os.Getenv(k)); v != "" {
		return v
	}
	return def
}
