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

type Asset struct {
	ID                      string    `json:"id"`
	PropertyID              string    `json:"property_id"`
	CategoryID              string    `json:"category_id,omitempty"`
	CategoryName            string    `json:"category_name,omitempty"`
	Name                    string    `json:"name"`
	Description             string    `json:"description,omitempty"`
	AssetCode               string    `json:"asset_code,omitempty"`
	SerialNumber            string    `json:"serial_number,omitempty"`
	Barcode                 string    `json:"barcode,omitempty"`
	QRCode                  string    `json:"qr_code,omitempty"`
	PhotoURLs               []string  `json:"photo_urls,omitempty"`
	Location                string    `json:"location,omitempty"`
	Building                string    `json:"building,omitempty"`
	Floor                   string    `json:"floor,omitempty"`
	Room                    string    `json:"room,omitempty"`
	PurchaseDate            string    `json:"purchase_date,omitempty"`
	PurchasePrice           float64   `json:"purchase_price,omitempty"`
	PurchaseInvoice         string    `json:"purchase_invoice,omitempty"`
	Vendor                  string    `json:"vendor,omitempty"`
	WarrantyStart           string    `json:"warranty_start,omitempty"`
	WarrantyEnd             string    `json:"warranty_end,omitempty"`
	DepreciationMethod      string    `json:"depreciation_method,omitempty"`
	DepreciationYears       int       `json:"depreciation_years,omitempty"`
	ResidualValue           float64   `json:"residual_value,omitempty"`
	CurrentValue            float64   `json:"current_value,omitempty"`
	AccumulatedDepreciation float64   `json:"accumulated_depreciation,omitempty"`
	Condition               string    `json:"condition"` // NEW, GOOD, FAIR, POOR, DISPOSED
	Status                  string    `json:"status"`    // ACTIVE, IN_MAINTENANCE, RESERVED, DISPOSED
	AssignedTo              string    `json:"assigned_to,omitempty"`
	AssignedToID            string    `json:"assigned_to_id,omitempty"`
	AssignedAt              string    `json:"assigned_at,omitempty"`
	LastMaintenanceDate     string    `json:"last_maintenance_date,omitempty"`
	NextMaintenanceDate     string    `json:"next_maintenance_date,omitempty"`
	MaintenanceIntervalDays int       `json:"maintenance_interval_days,omitempty"`
	Notes                   string    `json:"notes,omitempty"`
	CreatedAt               time.Time `json:"created_at"`
	UpdatedAt               time.Time `json:"updated_at"`
}

type AssetCategory struct {
	ID                string `json:"id"`
	PropertyID        string `json:"property_id,omitempty"`
	Name              string `json:"name"`
	Description       string `json:"description,omitempty"`
	DepreciationYears int    `json:"depreciation_years"`
	ParentID          string `json:"parent_id,omitempty"`
	AssetCount        int    `json:"asset_count,omitempty"`
}

type AssetMaintenance struct {
	ID              string    `json:"id"`
	AssetID         string    `json:"asset_id"`
	AssetName       string    `json:"asset_name,omitempty"`
	MaintenanceType string    `json:"maintenance_type"` // PREVENTIVE, CORRECTIVE, INSPECTION
	Description     string    `json:"description"`
	LaborCost       float64   `json:"labor_cost"`
	PartsCost       float64   `json:"parts_cost"`
	TotalCost       float64   `json:"total_cost"`
	PerformedBy     string    `json:"performed_by,omitempty"`
	Vendor          string    `json:"vendor,omitempty"`
	ScheduledDate   string    `json:"scheduled_date,omitempty"`
	PerformedAt     string    `json:"performed_at,omitempty"`
	NextDue         string    `json:"next_due,omitempty"`
	Status          string    `json:"status"` // SCHEDULED, COMPLETED, CANCELLED
	DocumentURLs    []string  `json:"document_urls,omitempty"`
	Notes           string    `json:"notes,omitempty"`
	CreatedAt       time.Time `json:"created_at"`
}

type AssetRequest struct {
	CategoryID        string   `json:"category_id"`
	Name              string   `json:"name" binding:"required"`
	Description       string   `json:"description"`
	AssetCode         string   `json:"asset_code"`
	SerialNumber      string   `json:"serial_number"`
	Location          string   `json:"location"`
	Building          string   `json:"building"`
	Floor             string   `json:"floor"`
	Room              string   `json:"room"`
	PurchaseDate      string   `json:"purchase_date"`
	PurchasePrice     float64  `json:"purchase_price"`
	Vendor            string   `json:"vendor"`
	WarrantyEnd       string   `json:"warranty_end"`
	DepreciationYears int      `json:"depreciation_years"`
	Condition         string   `json:"condition"`
	PhotoURLs         []string `json:"photo_urls"`
}

type MaintenanceRequest struct {
	MaintenanceType string  `json:"maintenance_type" binding:"required"`
	Description     string  `json:"description" binding:"required"`
	LaborCost       float64 `json:"labor_cost"`
	PartsCost       float64 `json:"parts_cost"`
	PerformedBy     string  `json:"performed_by"`
	Vendor          string  `json:"vendor"`
	PerformedAt     string  `json:"performed_at"`
	NextDue         string  `json:"next_due"`
}

type AssetStats struct {
	TotalAssets         int     `json:"total_assets"`
	TotalValue          float64 `json:"total_value"`
	ActiveAssets        int     `json:"active_assets"`
	InMaintenance       int     `json:"in_maintenance"`
	DisposedAssets      int     `json:"disposed_assets"`
	UpcomingMaintenance int     `json:"upcoming_maintenance"`
	OverdueMaintenance  int     `json:"overdue_maintenance"`
}

// =====================================================
// HANDLERS
// =====================================================

func main() {
	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "asset",
			"version": "1.0.0",
		})
	})

	v1 := r.Group("/api/v1")
	{
		// Categories
		categories := v1.Group("/asset-categories")
		{
			categories.GET("", listCategories)
			categories.GET("/:id", getCategory)
			categories.POST("", createCategory)
			categories.PUT("/:id", updateCategory)
			categories.DELETE("/:id", deleteCategory)
		}

		// Assets
		assets := v1.Group("/assets")
		{
			assets.GET("", listAssets)
			assets.GET("/stats", getAssetStats)
			assets.GET("/due-maintenance", getDueMaintenance)
			assets.GET("/qr/:code", getAssetByQR)
			assets.GET("/:id", getAsset)
			assets.POST("", createAsset)
			assets.PUT("/:id", updateAsset)
			assets.DELETE("/:id", deleteAsset)
			assets.POST("/:id/assign", assignAsset)
			assets.POST("/:id/dispose", disposeAsset)
			assets.POST("/:id/generate-qr", generateQR)
		}

		// Maintenance
		maintenance := v1.Group("/assets/:asset_id/maintenance")
		{
			maintenance.GET("", getAssetMaintenance)
			maintenance.POST("", createMaintenance)
			maintenance.GET("/:id", getMaintenanceRecord)
			maintenance.PUT("/:id", updateMaintenance)
		}

		// Depreciation
		v1.GET("/assets/depreciation-report", getDepreciationReport)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8097"
	}

	log.Printf("Asset Service starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

// Category Handlers
func listCategories(c *gin.Context) {
	categories := []AssetCategory{
		{ID: "cat-1", Name: "Mobilya", DepreciationYears: 10, AssetCount: 45},
		{ID: "cat-2", Name: "Elektronik", DepreciationYears: 5, AssetCount: 23},
		{ID: "cat-3", Name: "Bahçe Ekipmanları", DepreciationYears: 7, AssetCount: 12},
		{ID: "cat-4", Name: "Temizlik Ekipmanları", DepreciationYears: 5, AssetCount: 18},
		{ID: "cat-5", Name: "Güvenlik Sistemleri", DepreciationYears: 8, AssetCount: 8},
		{ID: "cat-6", Name: "Asansör", DepreciationYears: 15, AssetCount: 2},
		{ID: "cat-7", Name: "HVAC Sistemleri", DepreciationYears: 12, AssetCount: 6},
	}
	c.JSON(http.StatusOK, gin.H{"categories": categories})
}

func getCategory(c *gin.Context) {
	id := c.Param("id")
	category := AssetCategory{
		ID:                id,
		Name:              "Mobilya",
		DepreciationYears: 10,
		AssetCount:        45,
	}
	c.JSON(http.StatusOK, category)
}

func createCategory(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": uuid.New().String(), "message": "Kategori oluşturuldu"})
}

func updateCategory(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{"id": id, "message": "Kategori güncellendi"})
}

func deleteCategory(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{"id": id, "message": "Kategori silindi"})
}

// Asset Handlers
func listAssets(c *gin.Context) {
	now := time.Now()
	assets := []Asset{
		{
			ID:                  uuid.New().String(),
			PropertyID:          "prop-1",
			CategoryName:        "Mobilya",
			Name:                "Lobi Koltuk Takımı",
			AssetCode:           "MOB-001",
			SerialNumber:        "SN123456",
			Location:            "A Blok Lobi",
			PurchaseDate:        "2023-05-15",
			PurchasePrice:       25000.00,
			CurrentValue:        20000.00,
			Condition:           "GOOD",
			Status:              "ACTIVE",
			NextMaintenanceDate: "2026-05-15",
			CreatedAt:           now,
		},
		{
			ID:                  uuid.New().String(),
			PropertyID:          "prop-1",
			CategoryName:        "Elektronik",
			Name:                "Güvenlik Kamera Sistemi",
			AssetCode:           "ELK-001",
			Location:            "Tüm Bloklar",
			PurchaseDate:        "2022-01-10",
			PurchasePrice:       85000.00,
			CurrentValue:        51000.00,
			Condition:           "GOOD",
			Status:              "ACTIVE",
			LastMaintenanceDate: "2025-12-01",
			NextMaintenanceDate: "2026-06-01",
			CreatedAt:           now,
		},
		{
			ID:            uuid.New().String(),
			PropertyID:    "prop-1",
			CategoryName:  "Bahçe Ekipmanları",
			Name:          "Çim Biçme Makinesi",
			AssetCode:     "BAH-001",
			Location:      "Bahçe Deposu",
			PurchaseDate:  "2024-03-20",
			PurchasePrice: 15000.00,
			CurrentValue:  12857.00,
			Condition:     "GOOD",
			Status:        "ACTIVE",
			CreatedAt:     now,
		},
	}
	c.JSON(http.StatusOK, gin.H{"assets": assets, "total": len(assets)})
}

func getAssetStats(c *gin.Context) {
	stats := AssetStats{
		TotalAssets:         114,
		TotalValue:          850000.00,
		ActiveAssets:        108,
		InMaintenance:       3,
		DisposedAssets:      3,
		UpcomingMaintenance: 5,
		OverdueMaintenance:  1,
	}
	c.JSON(http.StatusOK, stats)
}

func getDueMaintenance(c *gin.Context) {
	now := time.Now()
	assets := []Asset{
		{
			ID:                  uuid.New().String(),
			Name:                "Asansör 1",
			CategoryName:        "Asansör",
			Location:            "A Blok",
			NextMaintenanceDate: now.Add(7 * 24 * time.Hour).Format("2006-01-02"),
			Status:              "ACTIVE",
		},
	}
	c.JSON(http.StatusOK, gin.H{"assets": assets, "count": len(assets)})
}

func getAssetByQR(c *gin.Context) {
	code := c.Param("code")
	now := time.Now()
	asset := Asset{
		ID:           uuid.New().String(),
		Name:         "Lobi Koltuk Takımı",
		QRCode:       code,
		CategoryName: "Mobilya",
		Location:     "A Blok Lobi",
		Condition:    "GOOD",
		Status:       "ACTIVE",
		CreatedAt:    now,
	}
	c.JSON(http.StatusOK, asset)
}

func getAsset(c *gin.Context) {
	id := c.Param("id")
	now := time.Now()
	asset := Asset{
		ID:                      id,
		PropertyID:              "prop-1",
		CategoryID:              "cat-1",
		CategoryName:            "Mobilya",
		Name:                    "Lobi Koltuk Takımı",
		Description:             "3+2+1 deri koltuk takımı, gri renk",
		AssetCode:               "MOB-001",
		SerialNumber:            "SN123456",
		Location:                "A Blok Lobi",
		PurchaseDate:            "2023-05-15",
		PurchasePrice:           25000.00,
		Vendor:                  "Mobilya A.Ş.",
		WarrantyEnd:             "2025-05-15",
		DepreciationYears:       10,
		CurrentValue:            20000.00,
		AccumulatedDepreciation: 5000.00,
		Condition:               "GOOD",
		Status:                  "ACTIVE",
		NextMaintenanceDate:     "2026-05-15",
		MaintenanceIntervalDays: 365,
		CreatedAt:               now,
		UpdatedAt:               now,
	}
	c.JSON(http.StatusOK, asset)
}

func createAsset(c *gin.Context) {
	var req AssetRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	now := time.Now()
	asset := Asset{
		ID:                uuid.New().String(),
		PropertyID:        "prop-1",
		CategoryID:        req.CategoryID,
		Name:              req.Name,
		Description:       req.Description,
		AssetCode:         req.AssetCode,
		SerialNumber:      req.SerialNumber,
		Location:          req.Location,
		PurchaseDate:      req.PurchaseDate,
		PurchasePrice:     req.PurchasePrice,
		CurrentValue:      req.PurchasePrice,
		Vendor:            req.Vendor,
		WarrantyEnd:       req.WarrantyEnd,
		DepreciationYears: req.DepreciationYears,
		Condition:         req.Condition,
		Status:            "ACTIVE",
		QRCode:            "AST-" + uuid.New().String()[:8],
		PhotoURLs:         req.PhotoURLs,
		CreatedAt:         now,
		UpdatedAt:         now,
	}

	c.JSON(http.StatusCreated, asset)
}

func updateAsset(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{"id": id, "message": "Demirbaş güncellendi"})
}

func deleteAsset(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{"id": id, "message": "Demirbaş silindi"})
}

func assignAsset(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{
		"id":          id,
		"assigned_to": "Güvenlik Hasan",
		"assigned_at": time.Now().Format("2006-01-02"),
		"message":     "Demirbaş zimmetlendi",
	})
}

func disposeAsset(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{
		"id":      id,
		"status":  "DISPOSED",
		"message": "Demirbaş hurda kaydedildi",
	})
}

func generateQR(c *gin.Context) {
	id := c.Param("id")
	qrCode := "AST-" + uuid.New().String()[:8]
	c.JSON(http.StatusOK, gin.H{
		"id":      id,
		"qr_code": qrCode,
		"qr_url":  "/assets/qr/" + qrCode + ".png",
		"message": "QR kod oluşturuldu",
	})
}

// Maintenance Handlers
func getAssetMaintenance(c *gin.Context) {
	assetID := c.Param("asset_id")
	now := time.Now()

	records := []AssetMaintenance{
		{
			ID:              uuid.New().String(),
			AssetID:         assetID,
			MaintenanceType: "PREVENTIVE",
			Description:     "Yıllık genel bakım",
			LaborCost:       500.00,
			PartsCost:       200.00,
			TotalCost:       700.00,
			PerformedBy:     "Bakım Ahmet",
			PerformedAt:     "2025-05-15",
			NextDue:         "2026-05-15",
			Status:          "COMPLETED",
			CreatedAt:       now,
		},
	}
	c.JSON(http.StatusOK, gin.H{"maintenance_records": records})
}

func createMaintenance(c *gin.Context) {
	assetID := c.Param("asset_id")
	var req MaintenanceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	record := AssetMaintenance{
		ID:              uuid.New().String(),
		AssetID:         assetID,
		MaintenanceType: req.MaintenanceType,
		Description:     req.Description,
		LaborCost:       req.LaborCost,
		PartsCost:       req.PartsCost,
		TotalCost:       req.LaborCost + req.PartsCost,
		PerformedBy:     req.PerformedBy,
		Vendor:          req.Vendor,
		PerformedAt:     req.PerformedAt,
		NextDue:         req.NextDue,
		Status:          "COMPLETED",
		CreatedAt:       time.Now(),
	}

	c.JSON(http.StatusCreated, record)
}

func getMaintenanceRecord(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{"id": id, "message": "Bakım kaydı"})
}

func updateMaintenance(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{"id": id, "message": "Bakım kaydı güncellendi"})
}

func getDepreciationReport(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"period":              c.Query("year"),
		"total_assets":        114,
		"total_book_value":    850000.00,
		"annual_depreciation": 95000.00,
		"by_category": []gin.H{
			{"category": "Mobilya", "book_value": 150000.00, "depreciation": 15000.00},
			{"category": "Elektronik", "book_value": 200000.00, "depreciation": 40000.00},
			{"category": "Asansör", "book_value": 300000.00, "depreciation": 20000.00},
		},
	})
}
