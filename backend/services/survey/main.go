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

	r.GET("/health", stub.Health("survey"))

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
func listSurveys(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "survey")
}

func getActiveSurveys(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "survey")
}

func getSurveyStats(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "survey")
}

func getSurvey(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "survey")
}

func getSurveyResults(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "survey")
}

func getSurveyVotes(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "survey")
}

func createSurvey(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "survey")
}

func updateSurvey(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "survey")
}

func deleteSurvey(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "survey")
}

func publishSurvey(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "survey")
}

func endSurvey(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "survey")
}

func voteSurvey(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "survey")
}

func getMyVote(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "survey")
}

func getMySurveys(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "survey")
}

func getPendingVotes(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "survey")
}
