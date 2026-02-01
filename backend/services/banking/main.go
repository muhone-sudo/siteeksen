package main

import (
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// =====================================================
// MODELS
// =====================================================

type BankAccount struct {
	ID             string     `json:"id"`
	PropertyID     string     `json:"property_id"`
	BankCode       string     `json:"bank_code"`
	BankName       string     `json:"bank_name"`
	BranchCode     string     `json:"branch_code,omitempty"`
	BranchName     string     `json:"branch_name,omitempty"`
	IBAN           string     `json:"iban"`
	AccountNumber  string     `json:"account_number,omitempty"`
	AccountName    string     `json:"account_name"`
	Currency       string     `json:"currency"`
	APIEnabled     bool       `json:"api_enabled"`
	LastSyncAt     *time.Time `json:"last_sync_at,omitempty"`
	LastSyncStatus string     `json:"last_sync_status,omitempty"`
	IsPrimary      bool       `json:"is_primary"`
	IsCollection   bool       `json:"is_collection_account"`
	IsExpense      bool       `json:"is_expense_account"`
	IsActive       bool       `json:"is_active"`
	Balance        float64    `json:"balance,omitempty"`
}

type BankTransaction struct {
	ID               string     `json:"id"`
	PropertyID       string     `json:"property_id"`
	BankAccountID    string     `json:"bank_account_id"`
	TransactionID    string     `json:"transaction_id,omitempty"`
	TransactionDate  string     `json:"transaction_date"`
	ValueDate        string     `json:"value_date,omitempty"`
	Amount           float64    `json:"amount"`
	Currency         string     `json:"currency"`
	Direction        string     `json:"direction"` // IN, OUT
	CounterpartyName string     `json:"counterparty_name,omitempty"`
	CounterpartyIBAN string     `json:"counterparty_iban,omitempty"`
	CounterpartyBank string     `json:"counterparty_bank,omitempty"`
	Description      string     `json:"description,omitempty"`
	ReferenceNumber  string     `json:"reference_number,omitempty"`
	IsMatched        bool       `json:"is_matched"`
	MatchedType      string     `json:"matched_type,omitempty"` // PAYMENT, EXPENSE
	MatchedID        string     `json:"matched_id,omitempty"`
	MatchedAt        *time.Time `json:"matched_at,omitempty"`
	MatchedBy        string     `json:"matched_by,omitempty"`
	MatchMethod      string     `json:"match_method,omitempty"` // AUTO, MANUAL
	MatchConfidence  float64    `json:"match_confidence,omitempty"`
	CreatedAt        time.Time  `json:"created_at"`
}

type MatchSuggestion struct {
	TransactionID     string  `json:"transaction_id"`
	PaymentID         string  `json:"payment_id"`
	ResidentName      string  `json:"resident_name"`
	UnitNumber        string  `json:"unit_number"`
	ExpectedAmount    float64 `json:"expected_amount"`
	TransactionAmount float64 `json:"transaction_amount"`
	Confidence        float64 `json:"confidence"`
	MatchReason       string  `json:"match_reason"`
}

type BankAccountRequest struct {
	BankCode      string `json:"bank_code" binding:"required"`
	BankName      string `json:"bank_name" binding:"required"`
	IBAN          string `json:"iban" binding:"required"`
	AccountName   string `json:"account_name" binding:"required"`
	BranchCode    string `json:"branch_code"`
	BranchName    string `json:"branch_name"`
	AccountNumber string `json:"account_number"`
	IsPrimary     bool   `json:"is_primary"`
	IsCollection  bool   `json:"is_collection_account"`
	IsExpense     bool   `json:"is_expense_account"`
}

type MatchRequest struct {
	TransactionID string `json:"transaction_id" binding:"required"`
	PaymentID     string `json:"payment_id" binding:"required"`
	Notes         string `json:"notes"`
}

type SyncRequest struct {
	FromDate string `json:"from_date"`
	ToDate   string `json:"to_date"`
}

type BankingStats struct {
	TotalAccounts         int     `json:"total_accounts"`
	TotalBalance          float64 `json:"total_balance"`
	TodayIncoming         float64 `json:"today_incoming"`
	TodayOutgoing         float64 `json:"today_outgoing"`
	UnmatchedTransactions int     `json:"unmatched_transactions"`
	PendingMatches        int     `json:"pending_matches"`
}

// Supported banks
var supportedBanks = []map[string]string{
	{"code": "0010", "name": "Ziraat Bankası"},
	{"code": "0012", "name": "Halkbank"},
	{"code": "0015", "name": "Vakıfbank"},
	{"code": "0064", "name": "İş Bankası"},
	{"code": "0046", "name": "Akbank"},
	{"code": "0062", "name": "Garanti BBVA"},
	{"code": "0067", "name": "Yapı Kredi"},
	{"code": "0111", "name": "QNB Finansbank"},
	{"code": "0134", "name": "Denizbank"},
	{"code": "0032", "name": "TEB"},
	{"code": "0099", "name": "ING Bank"},
	{"code": "0123", "name": "HSBC"},
}

// =====================================================
// HANDLERS
// =====================================================

func main() {
	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "banking",
			"version": "1.0.0",
		})
	})

	v1 := r.Group("/api/v1")
	{
		// Bank Accounts
		accounts := v1.Group("/bank-accounts")
		{
			accounts.GET("", listBankAccounts)
			accounts.GET("/banks", getSupportedBanks)
			accounts.GET("/stats", getBankingStats)
			accounts.GET("/:id", getBankAccount)
			accounts.POST("", createBankAccount)
			accounts.PUT("/:id", updateBankAccount)
			accounts.DELETE("/:id", deleteBankAccount)
			accounts.POST("/:id/sync", syncBankAccount)
			accounts.GET("/:id/balance", getAccountBalance)
			accounts.GET("/:id/transactions", getAccountTransactions)
		}

		// Transactions
		transactions := v1.Group("/bank-transactions")
		{
			transactions.GET("", listTransactions)
			transactions.GET("/unmatched", getUnmatchedTransactions)
			transactions.GET("/suggestions", getMatchSuggestions)
			transactions.GET("/:id", getTransaction)
			transactions.POST("/:id/match", matchTransaction)
			transactions.POST("/:id/unmatch", unmatchTransaction)
			transactions.POST("/auto-match", autoMatchTransactions)
		}

		// Reports
		v1.GET("/banking/report", getBankingReport)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8093"
	}

	log.Printf("Banking Service starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

// Bank Account Handlers
func listBankAccounts(c *gin.Context) {
	now := time.Now()
	accounts := []BankAccount{
		{
			ID:             uuid.New().String(),
			PropertyID:     "prop-1",
			BankCode:       "0010",
			BankName:       "Ziraat Bankası",
			BranchCode:     "1234",
			BranchName:     "Kadıköy Şubesi",
			IBAN:           "TR12 0001 0012 3456 7890 1234 56",
			AccountName:    "ABC Sitesi Yönetimi",
			Currency:       "TRY",
			APIEnabled:     true,
			LastSyncAt:     &now,
			LastSyncStatus: "SUCCESS",
			IsPrimary:      true,
			IsCollection:   true,
			IsExpense:      true,
			IsActive:       true,
			Balance:        125000.50,
		},
		{
			ID:           uuid.New().String(),
			PropertyID:   "prop-1",
			BankCode:     "0064",
			BankName:     "İş Bankası",
			IBAN:         "TR98 0006 4000 0012 3456 7890 12",
			AccountName:  "ABC Sitesi - Yedek Hesap",
			Currency:     "TRY",
			APIEnabled:   false,
			IsPrimary:    false,
			IsCollection: true,
			IsExpense:    false,
			IsActive:     true,
			Balance:      45000.00,
		},
	}
	c.JSON(http.StatusOK, gin.H{"accounts": accounts, "total": len(accounts)})
}

func getSupportedBanks(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"banks": supportedBanks})
}

func getBankingStats(c *gin.Context) {
	stats := BankingStats{
		TotalAccounts:         2,
		TotalBalance:          170000.50,
		TodayIncoming:         15200.00,
		TodayOutgoing:         8500.00,
		UnmatchedTransactions: 5,
		PendingMatches:        3,
	}
	c.JSON(http.StatusOK, stats)
}

func getBankAccount(c *gin.Context) {
	id := c.Param("id")
	now := time.Now()
	account := BankAccount{
		ID:          id,
		BankCode:    "0010",
		BankName:    "Ziraat Bankası",
		IBAN:        "TR12 0001 0012 3456 7890 1234 56",
		AccountName: "ABC Sitesi Yönetimi",
		Currency:    "TRY",
		APIEnabled:  true,
		LastSyncAt:  &now,
		IsPrimary:   true,
		IsActive:    true,
		Balance:     125000.50,
	}
	c.JSON(http.StatusOK, account)
}

func createBankAccount(c *gin.Context) {
	var req BankAccountRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	account := BankAccount{
		ID:           uuid.New().String(),
		PropertyID:   "prop-1",
		BankCode:     req.BankCode,
		BankName:     req.BankName,
		IBAN:         req.IBAN,
		AccountName:  req.AccountName,
		Currency:     "TRY",
		IsPrimary:    req.IsPrimary,
		IsCollection: req.IsCollection,
		IsExpense:    req.IsExpense,
		IsActive:     true,
	}

	c.JSON(http.StatusCreated, account)
}

func updateBankAccount(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{"id": id, "message": "Banka hesabı güncellendi"})
}

func deleteBankAccount(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{"id": id, "message": "Banka hesabı silindi"})
}

func syncBankAccount(c *gin.Context) {
	id := c.Param("id")
	var req SyncRequest
	c.ShouldBindJSON(&req)

	c.JSON(http.StatusOK, gin.H{
		"id":                   id,
		"sync_started_at":      time.Now(),
		"transactions_fetched": 25,
		"new_transactions":     5,
		"auto_matched":         3,
		"message":              "Senkronizasyon tamamlandı",
	})
}

func getAccountBalance(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{
		"id":       id,
		"balance":  125000.50,
		"currency": "TRY",
		"as_of":    time.Now(),
	})
}

func getAccountTransactions(c *gin.Context) {
	id := c.Param("id")
	transactions := []BankTransaction{}
	c.JSON(http.StatusOK, gin.H{"account_id": id, "transactions": transactions})
}

// Transaction Handlers
func listTransactions(c *gin.Context) {
	now := time.Now()
	transactions := []BankTransaction{
		{
			ID:               uuid.New().String(),
			BankAccountID:    "acc-1",
			TransactionDate:  now.Format("2006-01-02"),
			Amount:           850.00,
			Currency:         "TRY",
			Direction:        "IN",
			CounterpartyName: "ALI VELI",
			Description:      "OCAK 2026 AIDAT D.101",
			IsMatched:        true,
			MatchedType:      "PAYMENT",
			MatchMethod:      "AUTO",
			MatchConfidence:  0.95,
			CreatedAt:        now,
		},
		{
			ID:               uuid.New().String(),
			BankAccountID:    "acc-1",
			TransactionDate:  now.Format("2006-01-02"),
			Amount:           1200.00,
			Currency:         "TRY",
			Direction:        "IN",
			CounterpartyName: "MEHMET DEMIR",
			Description:      "EFT HAVALE",
			IsMatched:        false,
			CreatedAt:        now,
		},
		{
			ID:               uuid.New().String(),
			BankAccountID:    "acc-1",
			TransactionDate:  now.Format("2006-01-02"),
			Amount:           5000.00,
			Currency:         "TRY",
			Direction:        "OUT",
			CounterpartyName: "TEMIZLIK A.Ş.",
			Description:      "OCAK AYI TEMIZLIK UCRETI",
			IsMatched:        true,
			MatchedType:      "EXPENSE",
			MatchMethod:      "MANUAL",
			CreatedAt:        now,
		},
	}
	c.JSON(http.StatusOK, gin.H{"transactions": transactions, "total": len(transactions)})
}

func getUnmatchedTransactions(c *gin.Context) {
	now := time.Now()
	transactions := []BankTransaction{
		{
			ID:               uuid.New().String(),
			TransactionDate:  now.Format("2006-01-02"),
			Amount:           1200.00,
			Currency:         "TRY",
			Direction:        "IN",
			CounterpartyName: "MEHMET DEMIR",
			Description:      "EFT HAVALE",
			IsMatched:        false,
			CreatedAt:        now,
		},
		{
			ID:               uuid.New().String(),
			TransactionDate:  now.Add(-24 * time.Hour).Format("2006-01-02"),
			Amount:           850.00,
			Currency:         "TRY",
			Direction:        "IN",
			CounterpartyName: "AYSE KAYA",
			Description:      "AIDAT OCAK",
			IsMatched:        false,
			CreatedAt:        now,
		},
	}
	c.JSON(http.StatusOK, gin.H{"transactions": transactions, "count": len(transactions)})
}

func getMatchSuggestions(c *gin.Context) {
	suggestions := []MatchSuggestion{
		{
			TransactionID:     "txn-1",
			PaymentID:         "pay-1",
			ResidentName:      "Mehmet Demir",
			UnitNumber:        "D.205",
			ExpectedAmount:    1200.00,
			TransactionAmount: 1200.00,
			Confidence:        0.92,
			MatchReason:       "Tutar ve isim eşleşmesi",
		},
		{
			TransactionID:     "txn-2",
			PaymentID:         "pay-2",
			ResidentName:      "Ayşe Kaya",
			UnitNumber:        "D.301",
			ExpectedAmount:    850.00,
			TransactionAmount: 850.00,
			Confidence:        0.88,
			MatchReason:       "Tutar eşleşmesi, açıklamada 'AIDAT' kelimesi",
		},
	}
	c.JSON(http.StatusOK, gin.H{"suggestions": suggestions})
}

func getTransaction(c *gin.Context) {
	id := c.Param("id")
	now := time.Now()
	transaction := BankTransaction{
		ID:               id,
		TransactionDate:  now.Format("2006-01-02"),
		Amount:           850.00,
		Direction:        "IN",
		CounterpartyName: "ALI VELI",
		Description:      "OCAK 2026 AIDAT D.101",
		IsMatched:        true,
		CreatedAt:        now,
	}
	c.JSON(http.StatusOK, transaction)
}

func matchTransaction(c *gin.Context) {
	id := c.Param("id")
	var req MatchRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"transaction_id": id,
		"payment_id":     req.PaymentID,
		"matched_at":     time.Now(),
		"match_method":   "MANUAL",
		"message":        "İşlem eşleştirildi",
	})
}

func unmatchTransaction(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{
		"transaction_id": id,
		"message":        "Eşleştirme kaldırıldı",
	})
}

func autoMatchTransactions(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"processed": 25,
		"matched":   18,
		"unmatched": 7,
		"message":   "Otomatik eşleştirme tamamlandı",
	})
}

func getBankingReport(c *gin.Context) {
	// Query params: start_date, end_date
	c.JSON(http.StatusOK, gin.H{
		"period": gin.H{
			"start": c.Query("start_date"),
			"end":   c.Query("end_date"),
		},
		"summary": gin.H{
			"total_incoming":    125000.00,
			"total_outgoing":    85000.00,
			"net_change":        40000.00,
			"transaction_count": 150,
		},
		"by_category": []gin.H{
			{"category": "Aidat Tahsilatı", "amount": 100000.00},
			{"category": "Gider Ödemeleri", "amount": 75000.00},
			{"category": "Diğer Gelirler", "amount": 25000.00},
			{"category": "Diğer Giderler", "amount": 10000.00},
		},
	})
}
