package main

import (
	"log"
	"os"
	"time"

	"github.com/siteeksen/backend/pkg/stub"

	"github.com/gin-gonic/gin"
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

	r.GET("/health", stub.Health("contract"))

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

func listContracts(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "contract")
}

func getContractStats(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "contract")
}

func getExpiringContracts(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "contract")
}

func getContract(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "contract")
}

func createContract(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "contract")
}

func updateContract(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "contract")
}

func deleteContract(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "contract")
}

func renewContract(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "contract")
}

func terminateContract(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "contract")
}
