package main

import (
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
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

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "healthy", "service": "inventory"})
	})

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
		port = "8101"
	}
	log.Printf("Inventory Service starting on port %s", port)
	r.Run(":" + port)
}

func listItems(c *gin.Context) {
	now := time.Now()
	items := []InventoryItem{
		{ID: uuid.New().String(), CategoryName: "Temizlik", Name: "Çöp Poşeti (Büyük)", SKU: "TEM-001", Unit: "PAKET", CurrentStock: 45, MinStock: 20, UnitPrice: 50, TotalValue: 2250, IsLowStock: false, LastMovement: &now, CreatedAt: now},
		{ID: uuid.New().String(), CategoryName: "Temizlik", Name: "Çamaşır Suyu 5L", SKU: "TEM-002", Unit: "ADET", CurrentStock: 8, MinStock: 10, UnitPrice: 75, TotalValue: 600, IsLowStock: true, LastMovement: &now, CreatedAt: now},
		{ID: uuid.New().String(), CategoryName: "Elektrik", Name: "LED Ampul 12W", SKU: "ELK-001", Unit: "ADET", CurrentStock: 25, MinStock: 15, UnitPrice: 45, TotalValue: 1125, IsLowStock: false, LastMovement: &now, CreatedAt: now},
		{ID: uuid.New().String(), CategoryName: "Bahçe", Name: "Gübre 25kg", SKU: "BAH-001", Unit: "ADET", CurrentStock: 3, MinStock: 5, UnitPrice: 250, TotalValue: 750, IsLowStock: true, LastMovement: &now, CreatedAt: now},
	}
	c.JSON(http.StatusOK, gin.H{"items": items, "total": len(items)})
}

func getInventoryStats(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"total_items": 45, "total_value": 25000.00, "low_stock_items": 5, "out_of_stock": 1, "categories": 6})
}

func getLowStockItems(c *gin.Context) {
	now := time.Now()
	items := []InventoryItem{
		{ID: uuid.New().String(), Name: "Çamaşır Suyu 5L", CurrentStock: 8, MinStock: 10, IsLowStock: true, CreatedAt: now},
		{ID: uuid.New().String(), Name: "Gübre 25kg", CurrentStock: 3, MinStock: 5, IsLowStock: true, CreatedAt: now},
	}
	c.JSON(http.StatusOK, gin.H{"items": items, "count": len(items)})
}

func getItem(c *gin.Context) {
	c.JSON(http.StatusOK, InventoryItem{ID: c.Param("id"), Name: "Stok Ürünü", CurrentStock: 10, CreatedAt: time.Now()})
}

func createItem(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": uuid.New().String(), "message": "Stok kalemi oluşturuldu"})
}

func updateItem(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"id": c.Param("id"), "message": "Stok kalemi güncellendi"})
}

func deleteItem(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"id": c.Param("id"), "message": "Stok kalemi silindi"})
}

func getItemMovements(c *gin.Context) {
	now := time.Now()
	movements := []StockMovement{
		{ID: uuid.New().String(), ItemID: c.Param("id"), MovementType: "IN", Quantity: 50, UnitPrice: 50, Reason: "Satın alma", PerformedBy: "Yönetici", CreatedAt: now.Add(-48 * time.Hour)},
		{ID: uuid.New().String(), ItemID: c.Param("id"), MovementType: "OUT", Quantity: 5, Reason: "Günlük kullanım", PerformedBy: "Temizlik", CreatedAt: now.Add(-24 * time.Hour)},
	}
	c.JSON(http.StatusOK, gin.H{"movements": movements})
}

func listMovements(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"movements": []StockMovement{}})
}

func stockIn(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": uuid.New().String(), "movement_type": "IN", "message": "Stok girişi yapıldı"})
}

func stockOut(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": uuid.New().String(), "movement_type": "OUT", "message": "Stok çıkışı yapıldı"})
}

func stockAdjust(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": uuid.New().String(), "movement_type": "ADJUST", "message": "Stok düzeltmesi yapıldı"})
}

func getCategories(c *gin.Context) {
	categories := []gin.H{
		{"id": "cat-1", "name": "Temizlik Malzemeleri", "item_count": 15},
		{"id": "cat-2", "name": "Elektrik Malzemeleri", "item_count": 12},
		{"id": "cat-3", "name": "Bahçe Malzemeleri", "item_count": 8},
		{"id": "cat-4", "name": "Ofis Malzemeleri", "item_count": 6},
		{"id": "cat-5", "name": "Tesisat Malzemeleri", "item_count": 4},
	}
	c.JSON(http.StatusOK, gin.H{"categories": categories})
}
