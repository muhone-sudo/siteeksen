// marketplace-service — "Usta & Hizmet" tedarikçi pazaryeri (FAZ M, docs/usta-hizmet/plan.md, migration 076–077).
//
// Tedarikçiler (esnaf, dükkân, hizmet veren) kendi hesaplarıyla kayıt olur, işletmelerini ve hizmetlerini tanıtır;
// site sakini ve yönetimi talep açar, yakındaki tedarikçiler talebi ücret karşılığı kabul eder ve teklif verir.
// Gelir, tedarikçi müşteri adayını aldığı anda önceden yüklenmiş bakiyeden alınır (sızıntıya dayanıklı).
//
// Üç kapsam (pkg/dbscope): site (alıcı), tedarikçi hesabı, platform. Kimin neyi görebileceğini veritabanı
// politikaları belirler (077); bu servis ayrıca rol ve sahiplik denetler.
package main

import (
	"errors"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/iyzico"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/pkg/storage"
	"github.com/siteeksen/backend/services/marketplace/store"
)

func main() {
	pool, err := database.Connect(database.NewConfigFromEnv())
	if err != nil {
		log.Fatalf("Veritabanı bağlantısı başarısız: %v", err)
	}
	defer database.Close()

	// Belge ve fotoğraf deposu. Yapılandırılmamışsa servis açılır, dosya uçları 503 döner;
	// yapılandırma HATALIYSA servis açılmaz (sessiz dosya kaybı olmasın).
	files, ferr := storage.FromEnv()
	if errors.Is(ferr, storage.ErrNotConfigured) && os.Getenv("STORAGE_BACKEND") == "" {
		log.Printf("[marketplace] dosya deposu yapılandırılmamış: tedarikçi belgeleri ve fotoğraflar yüklenemez (STORAGE_BACKEND)")
		files = nil
	} else if ferr != nil {
		log.Fatalf("Dosya deposu yapılandırması hatalı: %v", ferr)
	}

	// Kartla bakiye yükleme (iyzico): finans servisiyle aynı anahtarlar; dönüş adresi pazaryerinin kendi ucudur.
	card, err := iyzico.FromEnv()
	if err != nil {
		log.Fatalf("iyzico yapılandırması hatalı: %v", err)
	}
	if card != nil {
		cb := strings.TrimSpace(os.Getenv("MARKET_IYZICO_CALLBACK_URL"))
		if cb == "" {
			log.Fatalf("iyzico yapılandırılmış ama MARKET_IYZICO_CALLBACK_URL yok (bakiye yükleme dönüşü …/api/v1/public/market/topups/iyzico/callback)")
		}
		card.CallbackURL = cb
	} else {
		log.Printf("[marketplace] iyzico yapılandırılmamış: bakiye yüklenemez (IYZICO_*)")
	}

	app := &App{store: store.New(pool), notifier: notify.FromEnvOrNil(pool), files: files, card: card}
	app.startJobs()

	r := middleware.NewRouter("marketplace")
	// Biçimi bozuk kimlik 500 değil 404 döner (pkg/middleware/params.go).
	r.Use(middleware.UUIDParams())
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "healthy", "service": "marketplace", "persistent": true, "storage": files != nil,
			"card_payments": card != nil})
	})
	// Kimliksiz: iyzico tarayıcıyı jetonla gönderir; sonuç sağlayıcıdan yeniden sorgulanır (M5).
	r.POST("/api/v1/public/market/topups/iyzico/callback", app.topupCallback)

	api := r.Group("/api/v1/market")
	api.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "marketplace"))
	// Ortak: ayarlar, kategoriler, paketler (oturum açmış herkes okur); vitrindeki hizmet fotoğrafı.
	api.GET("/meta", app.meta)
	api.GET("/services/:id/photo", app.servicePhoto)

	// Talep (M6): sakin kendi dairesi için, yönetici site adına açar; site oturumu gerekir.
	// Vitrin (M8): sitenin hizmet alanındaki yayındaki işletmeler; telefon yalnız paketi izin veriyorsa.
	api.GET("/showcase", app.showcase)
	api.GET("/showcase/:id", app.showcaseBusiness)
	api.GET("/requests/match-count", app.matchCount)
	api.GET("/requests", app.buyerRequests)
	api.POST("/requests", app.createRequest)
	api.GET("/requests/:id", app.buyerRequest)
	api.POST("/requests/:id/photos", app.addRequestPhoto)
	api.GET("/requests/:id/photos/:n", app.requestPhoto(false))
	// Teklif, mesaj, iş, puan (M7): alıcı tarafı.
	api.GET("/requests/:id/offers", app.buyerOffers)
	api.POST("/requests/:id/offers/:offerId/select", app.selectOffer)
	api.POST("/requests/:id/close", app.closeRequest)
	api.GET("/requests/:id/messages/:dispatchId", app.buyerMessages)
	api.POST("/requests/:id/messages/:dispatchId", app.buyerSend)
	api.GET("/requests/:id/job", app.buyerJob)
	api.POST("/requests/:id/job/confirm", app.jobDecision(true))
	api.POST("/requests/:id/job/dispute", app.jobDecision(false))
	api.POST("/requests/:id/review", app.addReview)

	supplier := api.Group("/supplier")
	supplier.Use(middleware.RequireRole(middleware.RoleSupplier))
	supplier.GET("/me", app.supplierMe)
	supplier.POST("/account", app.createAccount)
	supplier.PUT("/account", app.updateAccount)
	supplier.POST("/account/submit", app.submitAccount)
	supplier.GET("/documents", app.listDocuments)
	supplier.POST("/documents", app.uploadDocument)
	supplier.GET("/documents/:id/file", app.downloadDocument)
	supplier.DELETE("/documents/:id", app.deleteDocument)
	supplier.GET("/businesses", app.listBusinesses)
	supplier.POST("/businesses", app.saveBusiness)
	supplier.GET("/businesses/:id", app.getBusiness)
	supplier.PUT("/businesses/:id", app.saveBusiness)
	supplier.POST("/businesses/:id/submit", app.businessAction("submit"))
	supplier.POST("/businesses/:id/close", app.businessAction("close"))
	supplier.GET("/businesses/:id/services", app.listServices)
	supplier.POST("/businesses/:id/services", app.saveService)
	supplier.PUT("/services/:id", app.saveService)
	supplier.DELETE("/services/:id", app.deleteService)
	supplier.POST("/services/:id/photo", app.uploadServicePhoto)
	supplier.GET("/notifications", app.supplierNotifications)
	supplier.POST("/notifications/read", app.readSupplierNotifications)
	supplier.GET("/requests", app.supplierRequests)
	supplier.GET("/requests/:id", app.supplierRequest)
	supplier.POST("/requests/:id/accept", app.acceptRequest)
	supplier.GET("/requests/:id/photos/:n", app.requestPhoto(true))
	supplier.GET("/requests/:id/deal", app.supplierDeal)
	supplier.POST("/requests/:id/offers", app.saveOffer)
	supplier.POST("/offers/:id/withdraw", app.withdrawOffer)
	supplier.GET("/requests/:id/messages", app.supplierMessages)
	supplier.POST("/requests/:id/messages", app.supplierSend)
	supplier.POST("/requests/:id/dispute", app.openDispute)
	supplier.POST("/jobs/:id/done", app.supplierDone)
	supplier.GET("/reviews", app.supplierReviews)
	supplier.POST("/reviews/:id/reply", app.replyReview)
	supplier.GET("/wallet", app.wallet)
	supplier.POST("/topups", app.startTopup)
	supplier.GET("/topups/:id", app.topupStatus)
	supplier.POST("/package", app.changePackage)

	platform := api.Group("/platform")
	platform.Use(middleware.RequireRole(middleware.RolePlatformAdmin))
	platform.GET("/accounts", app.platformAccounts)
	platform.GET("/accounts/:id", app.platformAccount)
	platform.POST("/accounts/:id/approve", app.reviewAccount("approve"))
	platform.POST("/accounts/:id/reject", app.reviewAccount("reject"))
	platform.POST("/accounts/:id/suspend", app.reviewAccount("suspend"))
	platform.POST("/accounts/:id/reinstate", app.reviewAccount("reinstate"))
	platform.POST("/accounts/:id/close", app.closeAccount)
	platform.GET("/documents/:id/file", app.platformDocument)
	platform.GET("/businesses", app.platformBusinesses)
	platform.POST("/businesses/:id/approve", app.reviewBusiness("approve"))
	platform.POST("/businesses/:id/reject", app.reviewBusiness("reject"))
	platform.GET("/categories", app.platformCategories)
	platform.POST("/categories", app.saveCategory)
	platform.PUT("/categories/:id", app.saveCategory)
	platform.GET("/packages", app.platformPackages)
	platform.POST("/packages", app.savePackage)
	platform.PUT("/packages/:id", app.savePackage)
	platform.PUT("/settings/:key", app.saveSetting)
	platform.GET("/disputes", app.platformDisputes)
	platform.POST("/disputes/:id/approve", app.decideDispute(true))
	platform.POST("/disputes/:id/reject", app.decideDispute(false))
	platform.GET("/reviews", app.platformReviews)
	platform.POST("/reviews/:id/hide", app.hideReview)
	platform.GET("/revenue", app.revenue)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8111"
	}
	log.Printf("Marketplace Service başlatıldı: :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}
