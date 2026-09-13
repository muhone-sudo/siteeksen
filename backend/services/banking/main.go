package main

import (
	"log"
	"os"
	"time"

	"github.com/siteeksen/backend/pkg/stub"

	"github.com/gin-gonic/gin"
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

	r.GET("/health", stub.Health("banking"))

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
		port = "8106"
	}

	log.Printf("Banking Service starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

// Bank Account Handlers
func listBankAccounts(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "banking")
}

func getSupportedBanks(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "banking")
}

func getBankingStats(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "banking")
}

func getBankAccount(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "banking")
}

func createBankAccount(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "banking")
}

func updateBankAccount(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "banking")
}

func deleteBankAccount(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "banking")
}

func syncBankAccount(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "banking")
}

func getAccountBalance(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "banking")
}

func getAccountTransactions(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "banking")
}

// Transaction Handlers
func listTransactions(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "banking")
}

func getUnmatchedTransactions(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "banking")
}

func getMatchSuggestions(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "banking")
}

func getTransaction(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "banking")
}

func matchTransaction(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "banking")
}

func unmatchTransaction(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "banking")
}

func autoMatchTransactions(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "banking")
}

func getBankingReport(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "banking")
}
