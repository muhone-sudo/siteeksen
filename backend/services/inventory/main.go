package main

import (
	"log"
	"os"
	"time"

	"github.com/siteeksen/backend/pkg/stub"

	"github.com/gin-gonic/gin"
)

type InventoryItem struct {
	ID           string     `json:"id"`
	PropertyID   string     `json:"property_id"`
	CategoryID   string     `json:"category_id,omitempty"`
	CategoryName string     `json:"category_name,omitempty"`
	Name         string     `json:"name"`
	SKU          string     `json:"sku,omitempty"`
	Description  string     `json:"description,omitempty"`
	Unit         string     `json:"unit"` // ADET, KG, LT, PAKET
	CurrentStock float64    `json:"current_stock"`
	MinStock     float64    `json:"min_stock"`
	MaxStock     float64    `json:"max_stock,omitempty"`
	Location     string     `json:"location,omitempty"`
	UnitPrice    float64    `json:"unit_price,omitempty"`
	TotalValue   float64    `json:"total_value,omitempty"`
	IsLowStock   bool       `json:"is_low_stock"`
	LastMovement *time.Time `json:"last_movement,omitempty"`
	CreatedAt    time.Time  `json:"created_at"`
}

type StockMovement struct {
	ID           string    `json:"id"`
	ItemID       string    `json:"item_id"`
	ItemName     string    `json:"item_name,omitempty"`
	MovementType string    `json:"movement_type"` // IN, OUT, ADJUST
	Quantity     float64   `json:"quantity"`
	UnitPrice    float64   `json:"unit_price,omitempty"`
	Reason       string    `json:"reason,omitempty"`
	Reference    string    `json:"reference,omitempty"` // Fatura no, iş emri no
	PerformedBy  string    `json:"performed_by,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
}

func main() {
	r := gin.Default()

	r.GET("/health", stub.Health("inventory"))

	v1 := r.Group("/api/v1")
	{
		items := v1.Group("/inventory")
		{
			items.GET("", listItems)
			items.GET("/stats", getInventoryStats)
			items.GET("/low-stock", getLowStockItems)
			items.GET("/:id", getItem)
			items.POST("", createItem)
			items.PUT("/:id", updateItem)
			items.DELETE("/:id", deleteItem)
			items.GET("/:id/movements", getItemMovements)
		}

		movements := v1.Group("/stock-movements")
		{
			movements.GET("", listMovements)
			movements.POST("/in", stockIn)
			movements.POST("/out", stockOut)
			movements.POST("/adjust", stockAdjust)
		}

		v1.GET("/inventory/categories", getCategories)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8094"
	}
	log.Printf("Inventory Service starting on port %s", port)
	r.Run(":" + port)
}

func listItems(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "inventory")
}

func getInventoryStats(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "inventory")
}

func getLowStockItems(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "inventory")
}

func getItem(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "inventory")
}

func createItem(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "inventory")
}

func updateItem(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "inventory")
}

func deleteItem(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "inventory")
}

func getItemMovements(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "inventory")
}

func listMovements(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "inventory")
}

func stockIn(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "inventory")
}

func stockOut(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "inventory")
}

func stockAdjust(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "inventory")
}

func getCategories(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "inventory")
}
