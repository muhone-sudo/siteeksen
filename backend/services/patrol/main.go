package main

import (
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type PatrolRoute struct {
	ID           string       `json:"id"`
	PropertyID   string       `json:"property_id"`
	Name         string       `json:"name"`
	Description  string       `json:"description,omitempty"`
	Checkpoints  []Checkpoint `json:"checkpoints"`
	EstimatedMin int          `json:"estimated_minutes"`
	IsActive     bool         `json:"is_active"`
}

type Checkpoint struct {
	ID        string  `json:"id"`
	RouteID   string  `json:"route_id"`
	Name      string  `json:"name"`
	Location  string  `json:"location"`
	NFCCode   string  `json:"nfc_code,omitempty"`
	QRCode    string  `json:"qr_code,omitempty"`
	SortOrder int     `json:"sort_order"`
	Latitude  float64 `json:"latitude,omitempty"`
	Longitude float64 `json:"longitude,omitempty"`
}

type PatrolSession struct {
	ID          string      `json:"id"`
	PropertyID  string      `json:"property_id"`
	RouteID     string      `json:"route_id"`
	RouteName   string      `json:"route_name,omitempty"`
	GuardID     string      `json:"guard_id"`
	GuardName   string      `json:"guard_name,omitempty"`
	StartedAt   time.Time   `json:"started_at"`
	CompletedAt *time.Time  `json:"completed_at,omitempty"`
	Status      string      `json:"status"` // IN_PROGRESS, COMPLETED, INCOMPLETE
	TotalPoints int         `json:"total_points"`
	ScannedPts  int         `json:"scanned_points"`
	Logs        []PatrolLog `json:"logs,omitempty"`
}

type PatrolLog struct {
	ID             string    `json:"id"`
	SessionID      string    `json:"session_id"`
	CheckpointID   string    `json:"checkpoint_id"`
	CheckpointName string    `json:"checkpoint_name,omitempty"`
	ScannedAt      time.Time `json:"scanned_at"`
	ScanMethod     string    `json:"scan_method"` // NFC, QR
	PhotoURL       string    `json:"photo_url,omitempty"`
	Note           string    `json:"note,omitempty"`
	IssueReported  bool      `json:"issue_reported"`
}

func main() {
	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "healthy", "service": "patrol"})
	})

	v1 := r.Group("/api/v1")
	{
		routes := v1.Group("/patrol-routes")
		{
			routes.GET("", listRoutes)
			routes.GET("/:id", getRoute)
			routes.POST("", createRoute)
			routes.PUT("/:id", updateRoute)
			routes.DELETE("/:id", deleteRoute)
			routes.POST("/:id/checkpoints", addCheckpoint)
		}

		sessions := v1.Group("/patrol-sessions")
		{
			sessions.GET("", listSessions)
			sessions.GET("/active", getActiveSessions)
			sessions.GET("/stats", getPatrolStats)
			sessions.GET("/:id", getSession)
			sessions.POST("", startSession)
			sessions.POST("/:id/scan", scanCheckpoint)
			sessions.POST("/:id/complete", completeSession)
		}
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8099"
	}
	log.Printf("Patrol Service starting on port %s", port)
	r.Run(":" + port)
}

func listRoutes(c *gin.Context) {
	routes := []PatrolRoute{
		{ID: uuid.New().String(), Name: "Gece Devriyesi", EstimatedMin: 45, IsActive: true, Checkpoints: []Checkpoint{
			{ID: "cp-1", Name: "A Blok Giriş", Location: "A Blok", SortOrder: 1, NFCCode: "NFC001"},
			{ID: "cp-2", Name: "B Blok Giriş", Location: "B Blok", SortOrder: 2, NFCCode: "NFC002"},
			{ID: "cp-3", Name: "Otopark", Location: "Otopark", SortOrder: 3, NFCCode: "NFC003"},
		}},
		{ID: uuid.New().String(), Name: "Gündüz Devriyesi", EstimatedMin: 30, IsActive: true},
	}
	c.JSON(http.StatusOK, gin.H{"routes": routes})
}

func getRoute(c *gin.Context) {
	c.JSON(http.StatusOK, PatrolRoute{ID: c.Param("id"), Name: "Gece Devriyesi"})
}

func createRoute(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": uuid.New().String(), "message": "Rota oluşturuldu"})
}

func updateRoute(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"id": c.Param("id"), "message": "Rota güncellendi"})
}

func deleteRoute(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"id": c.Param("id"), "message": "Rota silindi"})
}

func addCheckpoint(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": uuid.New().String(), "message": "Kontrol noktası eklendi"})
}

func listSessions(c *gin.Context) {
	now := time.Now()
	completed := now.Add(-30 * time.Minute)
	sessions := []PatrolSession{
		{ID: uuid.New().String(), RouteName: "Gece Devriyesi", GuardName: "Hasan Güvenlik", StartedAt: now.Add(-45 * time.Minute), CompletedAt: &completed, Status: "COMPLETED", TotalPoints: 8, ScannedPts: 8},
		{ID: uuid.New().String(), RouteName: "Gece Devriyesi", GuardName: "Ahmet Güvenlik", StartedAt: now.Add(-15 * time.Minute), Status: "IN_PROGRESS", TotalPoints: 8, ScannedPts: 3},
	}
	c.JSON(http.StatusOK, gin.H{"sessions": sessions})
}

func getActiveSessions(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"sessions": []PatrolSession{}, "count": 0})
}

func getPatrolStats(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"today_patrols": 8, "completed": 7, "in_progress": 1, "issues_reported": 2, "avg_completion_rate": 97.5})
}

func getSession(c *gin.Context) {
	c.JSON(http.StatusOK, PatrolSession{ID: c.Param("id"), Status: "COMPLETED"})
}

func startSession(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": uuid.New().String(), "status": "IN_PROGRESS", "message": "Devriye başladı"})
}

func scanCheckpoint(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"session_id": c.Param("id"), "checkpoint_scanned": true, "scanned_at": time.Now()})
}

func completeSession(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"id": c.Param("id"), "status": "COMPLETED", "message": "Devriye tamamlandı"})
}
