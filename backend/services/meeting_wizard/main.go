package main

import (
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// AI-Powered Meeting Wizard Service
// Toplantı transkripsiyon, özet çıkarma, karar takibi

type Meeting struct {
	ID               string     `json:"id"`
	PropertyID       string     `json:"property_id"`
	Title            string     `json:"title"`
	MeetingType      string     `json:"meeting_type"` // GENERAL_ASSEMBLY, BOARD, COMMITTEE, OTHER
	ScheduledAt      time.Time  `json:"scheduled_at"`
	StartedAt        *time.Time `json:"started_at,omitempty"`
	EndedAt          *time.Time `json:"ended_at,omitempty"`
	DurationMinutes  int        `json:"duration_minutes,omitempty"`
	Location         string     `json:"location,omitempty"`
	Attendees        []Attendee `json:"attendees,omitempty"`
	AttendeeCount    int        `json:"attendee_count"`
	Quorum           bool       `json:"quorum"`
	Status           string     `json:"status"` // SCHEDULED, IN_PROGRESS, COMPLETED, CANCELLED
	RecordingURL     string     `json:"recording_url,omitempty"`
	TranscriptStatus string     `json:"transcript_status,omitempty"` // PENDING, PROCESSING, COMPLETED
	CreatedAt        time.Time  `json:"created_at"`
}

type Attendee struct {
	ID         string  `json:"id"`
	MeetingID  string  `json:"meeting_id"`
	ResidentID string  `json:"resident_id,omitempty"`
	Name       string  `json:"name"`
	UnitNumber string  `json:"unit_number,omitempty"`
	Role       string  `json:"role,omitempty"`  // CHAIR, SECRETARY, MEMBER
	Votes      float64 `json:"votes,omitempty"` // m² bazlı oy
	Attended   bool    `json:"attended"`
	ProxyFor   string  `json:"proxy_for,omitempty"`
}

type MeetingTranscript struct {
	ID            string              `json:"id"`
	MeetingID     string              `json:"meeting_id"`
	Segments      []TranscriptSegment `json:"segments"`
	FullText      string              `json:"full_text,omitempty"`
	WordCount     int                 `json:"word_count"`
	Language      string              `json:"language"`
	AIProcessedAt time.Time           `json:"ai_processed_at"`
}

type TranscriptSegment struct {
	StartTime  float64 `json:"start_time"`
	EndTime    float64 `json:"end_time"`
	Speaker    string  `json:"speaker,omitempty"`
	Text       string  `json:"text"`
	Confidence float64 `json:"confidence"`
}

type MeetingSummary struct {
	ID               string       `json:"id"`
	MeetingID        string       `json:"meeting_id"`
	ExecutiveSummary string       `json:"executive_summary"`
	KeyPoints        []string     `json:"key_points"`
	Decisions        []Decision   `json:"decisions"`
	ActionItems      []ActionItem `json:"action_items"`
	NextMeeting      string       `json:"next_meeting,omitempty"`
	AIConfidence     float64      `json:"ai_confidence"`
	GeneratedAt      time.Time    `json:"generated_at"`
}

type Decision struct {
	ID           string `json:"id"`
	Title        string `json:"title"`
	Description  string `json:"description"`
	Result       string `json:"result"` // APPROVED, REJECTED, DEFERRED
	VotesFor     int    `json:"votes_for"`
	VotesAgainst int    `json:"votes_against"`
	VotesAbstain int    `json:"votes_abstain"`
}

type ActionItem struct {
	ID          string `json:"id"`
	Title       string `json:"title"`
	Description string `json:"description"`
	AssignedTo  string `json:"assigned_to,omitempty"`
	DueDate     string `json:"due_date,omitempty"`
	Status      string `json:"status"` // PENDING, IN_PROGRESS, COMPLETED
	Priority    string `json:"priority"`
}

func main() {
	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "healthy", "service": "meeting-wizard", "ai_enabled": true})
	})

	v1 := r.Group("/api/v1")
	{
		meetings := v1.Group("/meetings")
		{
			meetings.GET("", listMeetings)
			meetings.GET("/stats", getMeetingStats)
			meetings.GET("/:id", getMeeting)
			meetings.POST("", createMeeting)
			meetings.PUT("/:id", updateMeeting)
			meetings.DELETE("/:id", deleteMeeting)
			meetings.POST("/:id/start", startMeeting)
			meetings.POST("/:id/end", endMeeting)

			// Attendees
			meetings.GET("/:id/attendees", getAttendees)
			meetings.POST("/:id/attendees", addAttendee)
			meetings.POST("/:id/attendance", recordAttendance)

			// AI Features
			meetings.POST("/:id/transcribe", transcribeMeeting)
			meetings.GET("/:id/transcript", getTranscript)
			meetings.POST("/:id/summarize", generateSummary)
			meetings.GET("/:id/summary", getSummary)
			meetings.GET("/:id/decisions", getDecisions)
			meetings.GET("/:id/action-items", getActionItems)
			meetings.POST("/:id/generate-minutes", generateMinutes)
		}

		// Action items across meetings
		v1.GET("/action-items", listAllActionItems)
		v1.PUT("/action-items/:id", updateActionItem)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8103"
	}
	log.Printf("Meeting Wizard Service starting on port %s", port)
	r.Run(":" + port)
}

func listMeetings(c *gin.Context) {
	now := time.Now()
	ended := now.Add(-2 * time.Hour)
	meetings := []Meeting{
		{ID: uuid.New().String(), Title: "2026 Ocak Genel Kurul Toplantısı", MeetingType: "GENERAL_ASSEMBLY", ScheduledAt: now.Add(-48 * time.Hour), StartedAt: &ended, EndedAt: &now, DurationMinutes: 120, AttendeeCount: 85, Quorum: true, Status: "COMPLETED", TranscriptStatus: "COMPLETED", CreatedAt: now},
		{ID: uuid.New().String(), Title: "Yönetim Kurulu Toplantısı", MeetingType: "BOARD", ScheduledAt: now.Add(24 * time.Hour), AttendeeCount: 0, Status: "SCHEDULED", CreatedAt: now},
	}
	c.JSON(http.StatusOK, gin.H{"meetings": meetings})
}

func getMeetingStats(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"total_meetings": 24, "this_month": 2, "pending_action_items": 5, "avg_attendance_rate": 68.5})
}

func getMeeting(c *gin.Context) {
	now := time.Now()
	c.JSON(http.StatusOK, Meeting{ID: c.Param("id"), Title: "Genel Kurul Toplantısı", Status: "COMPLETED", CreatedAt: now})
}

func createMeeting(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": uuid.New().String(), "message": "Toplantı oluşturuldu"})
}

func updateMeeting(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"id": c.Param("id"), "message": "Toplantı güncellendi"})
}

func deleteMeeting(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"id": c.Param("id"), "message": "Toplantı silindi"})
}

func startMeeting(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"id": c.Param("id"), "status": "IN_PROGRESS", "started_at": time.Now()})
}

func endMeeting(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"id": c.Param("id"), "status": "COMPLETED", "ended_at": time.Now()})
}

func getAttendees(c *gin.Context) {
	attendees := []Attendee{
		{ID: uuid.New().String(), MeetingID: c.Param("id"), Name: "Ali Veli", UnitNumber: "D.101", Role: "CHAIR", Votes: 95.5, Attended: true},
		{ID: uuid.New().String(), MeetingID: c.Param("id"), Name: "Ayşe Kaya", UnitNumber: "D.205", Role: "SECRETARY", Votes: 120.0, Attended: true},
	}
	c.JSON(http.StatusOK, gin.H{"attendees": attendees})
}

func addAttendee(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": uuid.New().String(), "message": "Katılımcı eklendi"})
}

func recordAttendance(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"meeting_id": c.Param("id"), "attendance_recorded": true})
}

func transcribeMeeting(c *gin.Context) {
	c.JSON(http.StatusAccepted, gin.H{
		"meeting_id":             c.Param("id"),
		"status":                 "PROCESSING",
		"estimated_time_minutes": 15,
		"message":                "Transkripsiyon işlemi başlatıldı (AI Whisper)",
	})
}

func getTranscript(c *gin.Context) {
	transcript := MeetingTranscript{
		ID:        uuid.New().String(),
		MeetingID: c.Param("id"),
		Segments: []TranscriptSegment{
			{StartTime: 0, EndTime: 45.5, Speaker: "Başkan Ali Veli", Text: "Toplantımıza hoş geldiniz. Gündemimizde 5 madde bulunmaktadır.", Confidence: 0.95},
			{StartTime: 45.5, EndTime: 120.0, Speaker: "Başkan Ali Veli", Text: "İlk gündem maddesi olarak 2025 yılı faaliyet raporunu görüşeceğiz.", Confidence: 0.92},
		},
		WordCount:     8500,
		Language:      "tr",
		AIProcessedAt: time.Now(),
	}
	c.JSON(http.StatusOK, transcript)
}

func generateSummary(c *gin.Context) {
	c.JSON(http.StatusAccepted, gin.H{
		"meeting_id": c.Param("id"),
		"status":     "PROCESSING",
		"message":    "AI özet çıkarma işlemi başlatıldı",
	})
}

func getSummary(c *gin.Context) {
	summary := MeetingSummary{
		ID:               uuid.New().String(),
		MeetingID:        c.Param("id"),
		ExecutiveSummary: "2026 Ocak Genel Kurul toplantısında 5 gündem maddesi görüşüldü. 2025 faaliyet raporu ve mali rapor oybirliğiyle kabul edildi. 2026 bütçesi %12 artışla onaylandı. Havuz renovasyonu projesi 2 ay ertelendi. Elektrik tasarruf tedbirleri için komisyon kuruldu.",
		KeyPoints: []string{
			"2025 faaliyet raporu oybirliğiyle kabul edildi",
			"2026 bütçesi 2.4 milyon TL olarak onaylandı",
			"Aidat artışı %15 olarak belirlendi",
			"Havuz renovasyonu yaz aylarına ertelendi",
			"Enerji tasarruf komisyonu kuruldu",
		},
		Decisions: []Decision{
			{ID: "d-1", Title: "2025 Faaliyet Raporu", Result: "APPROVED", VotesFor: 82, VotesAgainst: 0, VotesAbstain: 3},
			{ID: "d-2", Title: "2026 Bütçesi", Result: "APPROVED", VotesFor: 75, VotesAgainst: 8, VotesAbstain: 2},
			{ID: "d-3", Title: "Havuz Renovasyonu", Result: "DEFERRED", VotesFor: 45, VotesAgainst: 35, VotesAbstain: 5},
		},
		ActionItems: []ActionItem{
			{ID: "a-1", Title: "Enerji tasarruf komisyonu oluşturma", AssignedTo: "Yönetim Kurulu", DueDate: "2026-02-15", Status: "PENDING", Priority: "HIGH"},
			{ID: "a-2", Title: "Havuz renovasyon tekliflerini toplama", AssignedTo: "Site Yöneticisi", DueDate: "2026-05-01", Status: "PENDING", Priority: "MEDIUM"},
		},
		NextMeeting:  "2026-04-15 (Olağan Genel Kurul)",
		AIConfidence: 0.89,
		GeneratedAt:  time.Now(),
	}
	c.JSON(http.StatusOK, summary)
}

func getDecisions(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"decisions": []Decision{}})
}

func getActionItems(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"action_items": []ActionItem{}})
}

func generateMinutes(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"meeting_id":  c.Param("id"),
		"minutes_url": "/documents/minutes_2026_01.pdf",
		"message":     "Toplantı tutanağı oluşturuldu",
	})
}

func listAllActionItems(c *gin.Context) {
	items := []ActionItem{
		{ID: "a-1", Title: "Enerji tasarruf komisyonu oluşturma", AssignedTo: "Yönetim Kurulu", DueDate: "2026-02-15", Status: "PENDING", Priority: "HIGH"},
		{ID: "a-2", Title: "Havuz renovasyon tekliflerini toplama", AssignedTo: "Site Yöneticisi", DueDate: "2026-05-01", Status: "PENDING", Priority: "MEDIUM"},
	}
	c.JSON(http.StatusOK, gin.H{"action_items": items})
}

func updateActionItem(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"id": c.Param("id"), "message": "Aksiyon maddesi güncellendi"})
}
