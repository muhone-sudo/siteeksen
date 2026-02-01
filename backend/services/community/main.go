package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "healthy", "service": "community"})
	})

	// Announcements
	announcements := r.Group("/api/v1/announcements")
	{
		announcements.GET("", listAnnouncements)
		announcements.GET("/:id", getAnnouncement)
		announcements.POST("", createAnnouncement)
		announcements.PUT("/:id", updateAnnouncement)
		announcements.DELETE("/:id", deleteAnnouncement)
		announcements.POST("/:id/pin", pinAnnouncement)
		announcements.POST("/:id/read", markAsRead)
	}

	// Surveys
	surveys := r.Group("/api/v1/surveys")
	{
		surveys.GET("", listSurveys)
		surveys.GET("/:id", getSurvey)
		surveys.POST("", createSurvey)
		surveys.POST("/:id/vote", submitVote)
		surveys.GET("/:id/results", getSurveyResults)
	}

	// Bulletin Board
	bulletins := r.Group("/api/v1/bulletins")
	{
		bulletins.GET("", listBulletins)
		bulletins.POST("", createBulletin)
		bulletins.DELETE("/:id", deleteBulletin)
	}

	// Reservations
	reservations := r.Group("/api/v1/reservations")
	{
		reservations.GET("/facilities", listFacilities)
		reservations.GET("/facilities/:id/slots", getAvailableSlots)
		reservations.POST("", createReservation)
		reservations.GET("", listMyReservations)
		reservations.DELETE("/:id", cancelReservation)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8083"
	}

	log.Printf("Community Service starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

// ============ ANNOUNCEMENTS ============

func listAnnouncements(c *gin.Context) {
	// Mock response
	c.JSON(http.StatusOK, gin.H{
		"data": []gin.H{
			{
				"id":         "ann-001",
				"title":      "Asansör Bakımı",
				"content":    "5 Şubat tarihinde asansör bakımı yapılacaktır.",
				"category":   "MAINTENANCE",
				"priority":   "HIGH",
				"is_pinned":  true,
				"created_at": "2026-01-30T10:00:00Z",
				"read_count": 87,
			},
		},
		"total": 1,
	})
}

func getAnnouncement(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"id": c.Param("id")})
}

func createAnnouncement(c *gin.Context) {
	var input struct {
		Title    string `json:"title" binding:"required"`
		Content  string `json:"content" binding:"required"`
		Category string `json:"category"`
		Priority string `json:"priority"`
		IsPinned bool   `json:"is_pinned"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"id": "ann-new", "message": "Duyuru oluşturuldu"})
}

func updateAnnouncement(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Duyuru güncellendi"})
}

func deleteAnnouncement(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Duyuru silindi"})
}

func pinAnnouncement(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Duyuru sabitlendi"})
}

func markAsRead(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Okundu olarak işaretlendi"})
}

// ============ SURVEYS ============

func listSurveys(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"data": []gin.H{
			{
				"id":          "survey-001",
				"title":       "Bahçe Düzenleme Anketi",
				"description": "Bahçe düzenlemesi için tercihleriniz",
				"status":      "ACTIVE",
				"ends_at":     "2026-02-15T23:59:59Z",
				"total_votes": 45,
			},
		},
	})
}

func getSurvey(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"id":    c.Param("id"),
		"title": "Bahçe Düzenleme Anketi",
		"options": []gin.H{
			{"id": "opt-1", "text": "Çim alan", "votes": 20},
			{"id": "opt-2", "text": "Oyun parkı", "votes": 15},
			{"id": "opt-3", "text": "Oturma alanı", "votes": 10},
		},
	})
}

func createSurvey(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": "survey-new", "message": "Anket oluşturuldu"})
}

func submitVote(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Oyunuz kaydedildi"})
}

func getSurveyResults(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"results": "..."})
}

// ============ BULLETINS ============

func listBulletins(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"data": []gin.H{
			{
				"id":          "bul-001",
				"title":       "Satılık Bisiklet",
				"description": "Az kullanılmış çocuk bisikleti",
				"category":    "SALE",
				"contact":     "A Blok Daire 12",
				"created_at":  "2026-01-28T14:00:00Z",
			},
		},
	})
}

func createBulletin(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": "bul-new", "message": "İlan oluşturuldu"})
}

func deleteBulletin(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "İlan silindi"})
}

// ============ RESERVATIONS ============

func listFacilities(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"data": []gin.H{
			{"id": "fac-001", "name": "Toplantı Salonu", "capacity": 20, "hourly_fee": 0},
			{"id": "fac-002", "name": "Spor Salonu", "capacity": 10, "hourly_fee": 50},
			{"id": "fac-003", "name": "Yüzme Havuzu", "capacity": 30, "hourly_fee": 100},
		},
	})
}

func getAvailableSlots(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"facility_id": c.Param("id"),
		"date":        c.Query("date"),
		"slots": []gin.H{
			{"start": "09:00", "end": "10:00", "available": true},
			{"start": "10:00", "end": "11:00", "available": false},
			{"start": "11:00", "end": "12:00", "available": true},
		},
	})
}

func createReservation(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": "res-new", "message": "Rezervasyon oluşturuldu"})
}

func listMyReservations(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"data": []gin.H{}})
}

func cancelReservation(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Rezervasyon iptal edildi"})
}
