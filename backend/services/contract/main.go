package main

import (
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type Contract struct {
	ID              string    `json:"id"`
	PropertyID      string    `json:"property_id"`
	ContractType    string    `json:"contract_type"`
	Title           string    `json:"title"`
	PartyName       string    `json:"party_name"`
	StartDate       string    `json:"start_date"`
	EndDate         string    `json:"end_date,omitempty"`
	AutoRenew       bool      `json:"auto_renew"`
	PaymentType     string    `json:"payment_type,omitempty"`
	MonthlyAmount   float64   `json:"monthly_amount,omitempty"`
	Currency        string    `json:"currency"`
	Status          string    `json:"status"`
	DaysUntilExpiry int       `json:"days_until_expiry,omitempty"`
	DocumentURLs    []string  `json:"document_urls,omitempty"`
	CreatedAt       time.Time `json:"created_at"`
}

func main() {
	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "healthy", "service": "contract"})
	})

	v1 := r.Group("/api/v1")
	{
		contracts := v1.Group("/contracts")
		{
			contracts.GET("", listContracts)
			contracts.GET("/stats", getContractStats)
			contracts.GET("/expiring", getExpiringContracts)
			contracts.GET("/:id", getContract)
			contracts.POST("", createContract)
			contracts.PUT("/:id", updateContract)
			contracts.DELETE("/:id", deleteContract)
			contracts.POST("/:id/renew", renewContract)
			contracts.POST("/:id/terminate", terminateContract)
		}
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8098"
	}
	log.Printf("Contract Service starting on port %s", port)
	r.Run(":" + port)
}

func listContracts(c *gin.Context) {
	contracts := []Contract{
		{ID: uuid.New().String(), ContractType: "SERVICE", Title: "Bina Temizlik", PartyName: "Temiz A.Ş.", StartDate: "2025-01-01", EndDate: "2025-12-31", MonthlyAmount: 8000, Status: "ACTIVE", DaysUntilExpiry: 334, CreatedAt: time.Now()},
		{ID: uuid.New().String(), ContractType: "MAINTENANCE", Title: "Asansör Bakım", PartyName: "Asansör Ltd.", StartDate: "2024-06-01", EndDate: "2026-05-31", MonthlyAmount: 2000, Status: "ACTIVE", DaysUntilExpiry: 120, CreatedAt: time.Now()},
	}
	c.JSON(http.StatusOK, gin.H{"contracts": contracts, "total": len(contracts)})
}

func getContractStats(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"total_contracts": 12, "active_contracts": 10, "expiring_in_30_days": 2, "total_monthly_value": 35000.00})
}

func getExpiringContracts(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"contracts": []Contract{}, "count": 0})
}

func getContract(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, Contract{ID: id, Title: "Sözleşme", Status: "ACTIVE"})
}

func createContract(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": uuid.New().String(), "message": "Sözleşme oluşturuldu"})
}

func updateContract(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"id": c.Param("id"), "message": "Sözleşme güncellendi"})
}

func deleteContract(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"id": c.Param("id"), "message": "Sözleşme silindi"})
}

func renewContract(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"id": c.Param("id"), "status": "RENEWED", "message": "Sözleşme yenilendi"})
}

func terminateContract(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"id": c.Param("id"), "status": "TERMINATED", "message": "Sözleşme feshedildi"})
}
