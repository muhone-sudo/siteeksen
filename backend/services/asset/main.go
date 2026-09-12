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

	r.GET("/health", stub.Health("asset"))

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
		maintenance := v1.Group("/assets/:id/maintenance")
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
func listCategories(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "asset")
}

func getCategory(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "asset")
}

func createCategory(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "asset")
}

func updateCategory(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "asset")
}

func deleteCategory(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "asset")
}

// Asset Handlers
func listAssets(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "asset")
}

func getAssetStats(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "asset")
}

func getDueMaintenance(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "asset")
}

func getAssetByQR(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "asset")
}

func getAsset(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "asset")
}

func createAsset(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "asset")
}

func updateAsset(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "asset")
}

func deleteAsset(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "asset")
}

func assignAsset(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "asset")
}

func disposeAsset(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "asset")
}

func generateQR(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "asset")
}

// Maintenance Handlers
func getAssetMaintenance(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "asset")
}

func createMaintenance(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "asset")
}

func getMaintenanceRecord(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "asset")
}

func updateMaintenance(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "asset")
}

func getDepreciationReport(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "asset")
}
