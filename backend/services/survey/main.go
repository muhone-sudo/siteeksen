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

type Survey struct {
	ID                   string         `json:"id"`
	PropertyID           string         `json:"property_id"`
	Title                string         `json:"title"`
	Description          string         `json:"description,omitempty"`
	SurveyType           string         `json:"survey_type"` // POLL, SURVEY, VOTE, GENERAL_ASSEMBLY
	IsAnonymous          bool           `json:"is_anonymous"`
	IsWeighted           bool           `json:"is_weighted"` // m² bazlı
	AllowMultiple        bool           `json:"allow_multiple"`
	AllowComments        bool           `json:"allow_comments"`
	ShowResultsBeforeEnd bool           `json:"show_results_before_end"`
	StartsAt             time.Time      `json:"starts_at"`
	EndsAt               *time.Time     `json:"ends_at,omitempty"`
	Status               string         `json:"status"` // DRAFT, ACTIVE, ENDED, CANCELLED
	TotalEligibleVoters  int            `json:"total_eligible_voters"`
	TotalVotes           int            `json:"total_votes"`
	ParticipationRate    float64        `json:"participation_rate"`
	Options              []SurveyOption `json:"options,omitempty"`
	CreatedBy            string         `json:"created_by"`
	CreatedAt            time.Time      `json:"created_at"`
}

type SurveyOption struct {
	ID                string  `json:"id"`
	SurveyID          string  `json:"survey_id"`
	OptionText        string  `json:"option_text"`
	Description       string  `json:"description,omitempty"`
	DisplayOrder      int     `json:"display_order"`
	VoteCount         int     `json:"vote_count"`
	WeightedVoteCount float64 `json:"weighted_vote_count"`
	Percentage        float64 `json:"percentage"`
}

type SurveyVote struct {
	ID         string    `json:"id"`
	SurveyID   string    `json:"survey_id"`
	OptionID   string    `json:"option_id"`
	VoterID    string    `json:"voter_id"`
	VoterName  string    `json:"voter_name,omitempty"`
	UnitID     string    `json:"unit_id,omitempty"`
	UnitNumber string    `json:"unit_number,omitempty"`
	Weight     float64   `json:"weight"`
	Comment    string    `json:"comment,omitempty"`
	VotedAt    time.Time `json:"voted_at"`
}

type SurveyRequest struct {
	Title                string   `json:"title" binding:"required"`
	Description          string   `json:"description"`
	SurveyType           string   `json:"survey_type" binding:"required"`
	IsAnonymous          bool     `json:"is_anonymous"`
	IsWeighted           bool     `json:"is_weighted"`
	AllowMultiple        bool     `json:"allow_multiple"`
	AllowComments        bool     `json:"allow_comments"`
	ShowResultsBeforeEnd bool     `json:"show_results_before_end"`
	StartsAt             string   `json:"starts_at"`
	EndsAt               string   `json:"ends_at"`
	Options              []string `json:"options" binding:"required,min=2"`
}

type VoteRequest struct {
	OptionIDs []string `json:"option_ids" binding:"required"`
	Comment   string   `json:"comment"`
}

type SurveyStats struct {
	TotalSurveys     int `json:"total_surveys"`
	ActiveSurveys    int `json:"active_surveys"`
	PendingVotes     int `json:"pending_votes"`
	CompletedSurveys int `json:"completed_surveys"`
}

// =====================================================
// HANDLERS
// =====================================================

func main() {
	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "survey",
			"version": "1.0.0",
		})
	})

	v1 := r.Group("/api/v1")
	{
		// Surveys
		surveys := v1.Group("/surveys")
		{
			surveys.GET("", listSurveys)
			surveys.GET("/active", getActiveSurveys)
			surveys.GET("/stats", getSurveyStats)
			surveys.GET("/:id", getSurvey)
			surveys.GET("/:id/results", getSurveyResults)
			surveys.GET("/:id/votes", getSurveyVotes)
			surveys.POST("", createSurvey)
			surveys.PUT("/:id", updateSurvey)
			surveys.DELETE("/:id", deleteSurvey)
			surveys.POST("/:id/publish", publishSurvey)
			surveys.POST("/:id/end", endSurvey)
			surveys.POST("/:id/vote", voteSurvey)
			surveys.GET("/:id/my-vote", getMyVote)
		}

		// Resident surveys
		v1.GET("/my-surveys", getMySurveys)
		v1.GET("/pending-votes", getPendingVotes)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8095"
	}

	log.Printf("Survey Service starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

// Survey Handlers
func listSurveys(c *gin.Context) {
	now := time.Now()
	endDate := now.Add(7 * 24 * time.Hour)

	surveys := []Survey{
		{
			ID:                  uuid.New().String(),
			PropertyID:          "prop-1",
			Title:               "2026 Yılı Bütçe Oylaması",
			Description:         "2026 yılı için önerilen site bütçesini onaylıyor musunuz?",
			SurveyType:          "GENERAL_ASSEMBLY",
			IsAnonymous:         false,
			IsWeighted:          true,
			AllowMultiple:       false,
			StartsAt:            now.Add(-24 * time.Hour),
			EndsAt:              &endDate,
			Status:              "ACTIVE",
			TotalEligibleVoters: 124,
			TotalVotes:          78,
			ParticipationRate:   62.9,
			Options: []SurveyOption{
				{ID: "opt-1", OptionText: "Onaylıyorum", VoteCount: 65, WeightedVoteCount: 7250.5, Percentage: 83.3},
				{ID: "opt-2", OptionText: "Onaylamıyorum", VoteCount: 13, WeightedVoteCount: 1420.0, Percentage: 16.7},
			},
			CreatedAt: now.Add(-48 * time.Hour),
		},
		{
			ID:                  uuid.New().String(),
			PropertyID:          "prop-1",
			Title:               "Havuz Çalışma Saatleri",
			Description:         "Yaz döneminde havuzun çalışma saatlerini belirleyelim.",
			SurveyType:          "POLL",
			IsAnonymous:         true,
			AllowMultiple:       false,
			StartsAt:            now.Add(-12 * time.Hour),
			EndsAt:              &endDate,
			Status:              "ACTIVE",
			TotalEligibleVoters: 124,
			TotalVotes:          45,
			ParticipationRate:   36.3,
			Options: []SurveyOption{
				{ID: "opt-1", OptionText: "08:00 - 20:00", VoteCount: 12, Percentage: 26.7},
				{ID: "opt-2", OptionText: "09:00 - 21:00", VoteCount: 25, Percentage: 55.6},
				{ID: "opt-3", OptionText: "10:00 - 22:00", VoteCount: 8, Percentage: 17.8},
			},
			CreatedAt: now.Add(-24 * time.Hour),
		},
		{
			ID:                  uuid.New().String(),
			PropertyID:          "prop-1",
			Title:               "Elektrikli Araç Şarj İstasyonu",
			Description:         "Otoparka elektrikli araç şarj istasyonu kurulmasını onaylıyor musunuz?",
			SurveyType:          "VOTE",
			IsAnonymous:         false,
			IsWeighted:          true,
			AllowComments:       true,
			StartsAt:            now.Add(-72 * time.Hour),
			Status:              "ENDED",
			TotalEligibleVoters: 124,
			TotalVotes:          98,
			ParticipationRate:   79.0,
			Options: []SurveyOption{
				{ID: "opt-1", OptionText: "Evet", VoteCount: 72, Percentage: 73.5},
				{ID: "opt-2", OptionText: "Hayır", VoteCount: 26, Percentage: 26.5},
			},
			CreatedAt: now.Add(-96 * time.Hour),
		},
	}

	c.JSON(http.StatusOK, gin.H{"surveys": surveys, "total": len(surveys)})
}

func getActiveSurveys(c *gin.Context) {
	now := time.Now()
	endDate := now.Add(7 * 24 * time.Hour)

	surveys := []Survey{
		{
			ID:                uuid.New().String(),
			Title:             "Havuz Çalışma Saatleri",
			SurveyType:        "POLL",
			IsAnonymous:       true,
			Status:            "ACTIVE",
			TotalVotes:        45,
			ParticipationRate: 36.3,
			EndsAt:            &endDate,
			Options: []SurveyOption{
				{OptionText: "08:00 - 20:00", Percentage: 26.7},
				{OptionText: "09:00 - 21:00", Percentage: 55.6},
				{OptionText: "10:00 - 22:00", Percentage: 17.8},
			},
		},
	}
	c.JSON(http.StatusOK, gin.H{"surveys": surveys})
}

func getSurveyStats(c *gin.Context) {
	stats := SurveyStats{
		TotalSurveys:     15,
		ActiveSurveys:    2,
		PendingVotes:     2,
		CompletedSurveys: 13,
	}
	c.JSON(http.StatusOK, stats)
}

func getSurvey(c *gin.Context) {
	id := c.Param("id")
	now := time.Now()
	endDate := now.Add(7 * 24 * time.Hour)

	survey := Survey{
		ID:                  id,
		PropertyID:          "prop-1",
		Title:               "Havuz Çalışma Saatleri",
		Description:         "Yaz döneminde havuzun çalışma saatlerini belirleyelim.",
		SurveyType:          "POLL",
		IsAnonymous:         true,
		AllowMultiple:       false,
		StartsAt:            now.Add(-12 * time.Hour),
		EndsAt:              &endDate,
		Status:              "ACTIVE",
		TotalEligibleVoters: 124,
		TotalVotes:          45,
		ParticipationRate:   36.3,
		Options: []SurveyOption{
			{ID: "opt-1", OptionText: "08:00 - 20:00", VoteCount: 12, Percentage: 26.7, DisplayOrder: 1},
			{ID: "opt-2", OptionText: "09:00 - 21:00", VoteCount: 25, Percentage: 55.6, DisplayOrder: 2},
			{ID: "opt-3", OptionText: "10:00 - 22:00", VoteCount: 8, Percentage: 17.8, DisplayOrder: 3},
		},
		CreatedAt: now.Add(-24 * time.Hour),
	}
	c.JSON(http.StatusOK, survey)
}

func getSurveyResults(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{
		"survey_id": id,
		"results": []SurveyOption{
			{ID: "opt-1", OptionText: "08:00 - 20:00", VoteCount: 12, Percentage: 26.7},
			{ID: "opt-2", OptionText: "09:00 - 21:00", VoteCount: 25, Percentage: 55.6},
			{ID: "opt-3", OptionText: "10:00 - 22:00", VoteCount: 8, Percentage: 17.8},
		},
		"total_votes":        45,
		"participation_rate": 36.3,
	})
}

func getSurveyVotes(c *gin.Context) {
	id := c.Param("id")
	now := time.Now()

	votes := []SurveyVote{
		{
			ID:         uuid.New().String(),
			SurveyID:   id,
			OptionID:   "opt-2",
			VoterName:  "Ali V.",
			UnitNumber: "D.101",
			Weight:     95.5,
			VotedAt:    now.Add(-6 * time.Hour),
		},
		{
			ID:         uuid.New().String(),
			SurveyID:   id,
			OptionID:   "opt-1",
			VoterName:  "Ayşe K.",
			UnitNumber: "D.205",
			Weight:     120.0,
			VotedAt:    now.Add(-4 * time.Hour),
		},
	}
	c.JSON(http.StatusOK, gin.H{"votes": votes, "total": len(votes)})
}

func createSurvey(c *gin.Context) {
	var req SurveyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	now := time.Now()
	options := make([]SurveyOption, len(req.Options))
	for i, opt := range req.Options {
		options[i] = SurveyOption{
			ID:           uuid.New().String(),
			OptionText:   opt,
			DisplayOrder: i + 1,
		}
	}

	survey := Survey{
		ID:                   uuid.New().String(),
		PropertyID:           "prop-1",
		Title:                req.Title,
		Description:          req.Description,
		SurveyType:           req.SurveyType,
		IsAnonymous:          req.IsAnonymous,
		IsWeighted:           req.IsWeighted,
		AllowMultiple:        req.AllowMultiple,
		AllowComments:        req.AllowComments,
		ShowResultsBeforeEnd: req.ShowResultsBeforeEnd,
		StartsAt:             now,
		Status:               "DRAFT",
		Options:              options,
		CreatedBy:            "user-1",
		CreatedAt:            now,
	}

	c.JSON(http.StatusCreated, survey)
}

func updateSurvey(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{"id": id, "message": "Anket güncellendi"})
}

func deleteSurvey(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{"id": id, "message": "Anket silindi"})
}

func publishSurvey(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{
		"id":      id,
		"status":  "ACTIVE",
		"message": "Anket yayınlandı",
	})
}

func endSurvey(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{
		"id":      id,
		"status":  "ENDED",
		"message": "Anket sonlandırıldı",
	})
}

func voteSurvey(c *gin.Context) {
	id := c.Param("id")
	var req VoteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"survey_id":  id,
		"option_ids": req.OptionIDs,
		"voted_at":   time.Now(),
		"message":    "Oyunuz kaydedildi",
	})
}

func getMyVote(c *gin.Context) {
	id := c.Param("id")
	now := time.Now()

	vote := SurveyVote{
		ID:       uuid.New().String(),
		SurveyID: id,
		OptionID: "opt-2",
		VotedAt:  now.Add(-2 * time.Hour),
	}
	c.JSON(http.StatusOK, vote)
}

func getMySurveys(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"surveys": []Survey{}, "total": 0})
}

func getPendingVotes(c *gin.Context) {
	now := time.Now()
	endDate := now.Add(7 * 24 * time.Hour)

	surveys := []Survey{
		{
			ID:         uuid.New().String(),
			Title:      "Havuz Çalışma Saatleri",
			SurveyType: "POLL",
			Status:     "ACTIVE",
			EndsAt:     &endDate,
		},
	}
	c.JSON(http.StatusOK, gin.H{"surveys": surveys, "count": len(surveys)})
}
