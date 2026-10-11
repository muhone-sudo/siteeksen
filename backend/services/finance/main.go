package main

import (
	"errors"
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/iyzico"
	"github.com/siteeksen/backend/pkg/legalparams"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/pkg/storage"
	"github.com/siteeksen/backend/services/finance/handlers"
	"github.com/siteeksen/backend/services/finance/repository"
	"github.com/siteeksen/backend/services/finance/service"
)

func main() {
	// Veritabanı bağlantısı
	dbConfig := database.NewConfigFromEnv()
	pool, err := database.Connect(dbConfig)
	if err != nil {
		log.Fatalf("Veritabanı bağlantısı başarısız: %v", err)
	}
	defer database.Close()

	// Repository ve Service
	financeRepo := repository.NewFinanceRepository(pool)
	// Mevzuata bağlı oranlar (gecikme tazminatı vb.) veritabanından okunur; koda gömülmez.
	params := legalparams.New(pool)
	financeService := service.NewFinanceService(financeRepo, params)
	// Kartla ödeme (060): iyzico yapılandırması yarımsa servis açılmaz; hiç yoksa kart ödemesi
	// "sağlayıcı bağlı değil" yanıtıyla döner (payment_gateway_ready:false).
	card, err := iyzico.FromEnv()
	if err != nil {
		log.Fatalf("Kart ödeme yapılandırması hatalı: %v", err)
	}
	financeService.SetCardGateway(card)
	startCardReconcile(financeService)
	// Yeni borç bildirimi (beşinci tur B1): tahakkuk ve devir kaydında daire sakinlerine.
	notifier := notify.FromEnvOrNil(pool)
	// Havale dekontu deposu (064, B9). Yapılandırılmamışsa servis açılır, dekont yüklemesi 503
	// döner; yapılandırma HATALIYSA servis açılmaz (sessiz dosya kaybı olmasın).
	store, serr := storage.FromEnv()
	if errors.Is(serr, storage.ErrNotConfigured) && os.Getenv("STORAGE_BACKEND") == "" {
		log.Printf("[finance] dosya deposu yapılandırılmamış: havale dekontu saklanamaz (STORAGE_BACKEND)")
		store = nil
	} else if serr != nil {
		log.Fatalf("Dosya deposu yapılandırması hatalı: %v", serr)
	}

	// Gin router
	r := middleware.NewRouter("finance")
	// Biçimi bozuk kimlik 500 değil 404 döner (pkg/middleware/params.go).
	r.Use(middleware.UUIDParams())

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok", "service": "finance"})
	})

	// -----------------------------------------------------------------------
	// Korumalı uçlar
	//
	// YETKİLENDİRME (2026-09-13, todo 2.9 / gap-analizi B28):
	// Bu servis daha önce yalnızca "giriş yapmış olma" şartı arıyordu. Sonuç:
	// herhangi bir sakin, sitedeki TÜM DAİRELERİN borç listesini (`/debtors`),
	// tüm ödemeleri (`/payments`) ve dönem özetlerini görebiliyordu. Bunlar
	// yönetim bilgisidir; KVKK açısından da gereğinden fazla veri paylaşımıdır.
	//
	// Ayrım:
	//   - SAKİN uçları: kişinin KENDİ borcu, KENDİ tahakkukları, KENDİ ödemesi.
	//   - YÖNETİM uçları: site geneli listeler ve tahakkuk oluşturma.
	//     MANAGER (yönetici), BOARD_MEMBER (yönetim kurulu) ve AUDITOR (denetçi)
	//     erişebilir; AUDITOR yalnızca okuma uçlarında yer alır (KMK m.41 denetim
	//     görevi okumayı gerektirir, tahakkuk oluşturmayı değil).
	// -----------------------------------------------------------------------
	// Borcu yoktur belgesinin kimliksiz doğrulaması (055): banka/tapu memuru karekodu okutur.
	r.GET("/api/v1/public/clearance/:code", verifyClearance(pool))
	// iyzico 3D Secure / ödeme formu geri dönüşü (060): kimliksiz; sonuç sağlayıcıdan yeniden sorgulanır.
	r.POST("/api/v1/public/payments/iyzico/callback", cardCallback(financeService))

	api := r.Group("/api/v1/finance")
	api.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "finance"))
	{
		// --- Sakinin kendi verisi ---
		api.GET("/debt-status", handlers.GetDebtStatus(financeService))
		api.GET("/assessments", handlers.GetAssessments(financeService))
		api.GET("/assessments/:id", handlers.GetAssessmentDetails(financeService))
		api.POST("/payments", handlers.CreatePayment(financeService))
		api.GET("/my-payments", handlers.GetMyPayments(financeService))
		api.GET("/payments/:id/status", cardStatus(financeService))
		// Havale bildirimine dekont dosyası (064, B9): bildirimi yapan sakin ekler; sakin ve yönetim görür.
		api.POST("/payments/:id/receipts", uploadReceipt(financeRepo, store))
		api.GET("/payments/:id/receipts", listReceipts(financeRepo))
		api.GET("/payments/:id/receipts/:receiptId/download", downloadReceipt(financeRepo, store))
		api.GET("/ledger/verify", handlers.VerifyLedger(financeService))
		// Borcu yoktur belgesi (055): bölümün sakini ya da yönetim.
		// Malikin kiracılı dairesindeki kiracı borcu özeti — site görünürlük politikasına bağlı (071, D6).
		api.GET("/tenant-debt-summary", tenantDebtSummary(pool))
		api.POST("/clearance-certificates", createClearance(pool))
		api.GET("/clearance-certificates/:id/pdf", clearancePDF(pool))
		api.GET("/consumption/summary", handlers.GetConsumptionSummary(financeService))
		// Alacak dekontları (059): sakin kendi dairesininkini, yönetim tümünü görür.
		api.GET("/credit-notes", listCreditNotes(financeRepo))
		api.GET("/credit-notes/:id/pdf", creditNotePDF(financeRepo, pool))

		// --- Yönetim: site geneli okuma ---
		mgmtRead := api.Group("")
		mgmtRead.Use(middleware.RequireRole(
			middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleAuditor))
		{
			mgmtRead.GET("/debtors", handlers.GetDebtors(financeService))
			mgmtRead.GET("/payments", handlers.GetPaymentHistory(financeService))
			mgmtRead.GET("/assessments/overview", handlers.GetAssessmentOverview(financeService))
			mgmtRead.GET("/expense-categories", handlers.GetExpenseCategories(financeService))
			mgmtRead.GET("/payments/pending", handlers.ListPendingPayments(financeService))
			mgmtRead.GET("/opening-balances", handlers.ListOpeningBalances(financeService))
			// PDF / Excel dökümleri (TEST_RAPORU 2.6)
			mgmtRead.GET("/reports/debtors", debtorsReport(financeService, pool))
			mgmtRead.GET("/ledger", handlers.ListLedger(financeService))
			mgmtRead.GET("/reports/collections", collectionReport(financeService, pool))
			mgmtRead.GET("/units/:id/open-assessments", openAssessments(financeRepo))
			mgmtRead.GET("/bank-statements", listBankImports(financeRepo))
			mgmtRead.GET("/bank-statements/:id", getBankImport(financeRepo))
		}

		// --- Yönetim: yazma (denetçi hariç) ---
		mgmtWrite := api.Group("")
		mgmtWrite.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
		{
			mgmtWrite.POST("/assessments", handlers.CreateAssessment(financeService, notifier, pool))
			// Tahsilat onayı: ödeme sağlayıcısı entegrasyonu olmadığı için havale/EFT/nakit
			// tahsilatını yönetici onaylar. Onay, tahakkukların paid_amount değerini artırır.
			mgmtWrite.POST("/payments/:id/confirm", handlers.ConfirmPayment(financeService))
			mgmtWrite.POST("/payments/:id/reverse", handlers.ReversePayment(financeService))
			mgmtWrite.POST("/payments/:id/reject", handlers.RejectPayment(financeService))
			// Gecikme tazminatı (KMK m.20/2). İşlem idempotenttir; zamanlanmış görev
			// ya da yönetici tarafından elle çalıştırılabilir.
			mgmtWrite.POST("/late-fees/accrue", handlers.AccrueLateFees(financeService))
			// Açılış (devir) bakiyesi: önceki yönetimden devreden borçlar (FAZ 8.1, 034).
			mgmtWrite.POST("/opening-balances", handlers.CreateOpeningBalances(financeService, notifier, pool))
			mgmtWrite.POST("/opening-balances/:id/cancel", handlers.CancelOpeningBalance(financeService))
			// Alacak dekontu ve banka ekstresi mutabakatı (059, Apsiyon BUG-12).
			mgmtWrite.POST("/credit-notes", createCreditNote(financeRepo))
			mgmtWrite.POST("/credit-notes/:id/reverse", reverseCreditNote(financeRepo))
			mgmtWrite.POST("/bank-statements", importBankStatement(financeRepo))
			mgmtWrite.POST("/bank-statements/lines/:id/confirm", confirmBankLine(financeRepo))
			mgmtWrite.POST("/bank-statements/lines/:id/ignore", ignoreBankLine(financeRepo))
			// Yönetimin tahsilat girişi (061, beşinci tur B2): bildirimsiz havale / elden ödeme ve
			// eşleşmeyen ekstre satırı doğrudan bölümün borçlarına işlenir.
			mgmtWrite.POST("/collections", recordCollection(financeService, notifier, pool))
			mgmtWrite.POST("/bank-statements/lines/:id/collect", collectBankLine(financeService, notifier, pool))
		}
	}

	// Sunucuyu başlat
	port := os.Getenv("PORT")
	if port == "" {
		port = "8082"
	}
	log.Printf("Finance Service başlatıldı: :%s", port)
	r.Run(":" + port)
}
