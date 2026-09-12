package main

import (
	"log"
	"os"
	"time"

	"github.com/siteeksen/backend/pkg/stub"

	"github.com/gin-gonic/gin"
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

	r.GET("/health", stub.Health("patrol"))

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

func listRoutes(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "patrol")
}

func getRoute(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "patrol")
}

func createRoute(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "patrol")
}

func updateRoute(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "patrol")
}

func deleteRoute(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "patrol")
}

func addCheckpoint(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "patrol")
}

func listSessions(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "patrol")
}

func getActiveSessions(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "patrol")
}

func getPatrolStats(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "patrol")
}

func getSession(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "patrol")
}

func startSession(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "patrol")
}

func scanCheckpoint(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "patrol")
}

func completeSession(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "patrol")
}
