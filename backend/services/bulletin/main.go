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

type BulletinPost struct {
	ID              string     `json:"id"`
	PropertyID      string     `json:"property_id"`
	UnitID          string     `json:"unit_id"`
	AuthorID        string     `json:"author_id"`
	AuthorName      string     `json:"author_name,omitempty"`
	UnitNumber      string     `json:"unit_number,omitempty"`
	Category        string     `json:"category"` // SALE, RENT, LOST_FOUND, HELP, SUGGESTION, CARPOOL, SERVICE, EVENT
	Title           string     `json:"title"`
	Content         string     `json:"content"`
	PhotoURLs       []string   `json:"photo_urls,omitempty"`
	Price           float64    `json:"price,omitempty"`
	PriceNegotiable bool       `json:"price_negotiable,omitempty"`
	IsAnonymous     bool       `json:"is_anonymous"`
	Status          string     `json:"status"` // PENDING, APPROVED, REJECTED, EXPIRED, CLOSED
	RejectionReason string     `json:"rejection_reason,omitempty"`
	ExpiresAt       *time.Time `json:"expires_at,omitempty"`
	ViewCount       int        `json:"view_count"`
	ContactCount    int        `json:"contact_count"`
	CommentCount    int        `json:"comment_count"`
	IsPinned        bool       `json:"is_pinned"`
	CreatedAt       time.Time  `json:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at"`
}

type BulletinComment struct {
	ID          string            `json:"id"`
	PostID      string            `json:"post_id"`
	AuthorID    string            `json:"author_id"`
	AuthorName  string            `json:"author_name,omitempty"`
	ParentID    string            `json:"parent_id,omitempty"`
	Content     string            `json:"content"`
	IsAnonymous bool              `json:"is_anonymous"`
	CreatedAt   time.Time         `json:"created_at"`
	Replies     []BulletinComment `json:"replies,omitempty"`
}

type BulletinMessage struct {
	ID         string     `json:"id"`
	PostID     string     `json:"post_id"`
	SenderID   string     `json:"sender_id"`
	SenderName string     `json:"sender_name,omitempty"`
	ReceiverID string     `json:"receiver_id"`
	Content    string     `json:"content"`
	IsRead     bool       `json:"is_read"`
	ReadAt     *time.Time `json:"read_at,omitempty"`
	CreatedAt  time.Time  `json:"created_at"`
}

type PostRequest struct {
	Category        string   `json:"category" binding:"required"`
	Title           string   `json:"title" binding:"required"`
	Content         string   `json:"content" binding:"required"`
	PhotoURLs       []string `json:"photo_urls"`
	Price           float64  `json:"price"`
	PriceNegotiable bool     `json:"price_negotiable"`
	IsAnonymous     bool     `json:"is_anonymous"`
}

type CommentRequest struct {
	Content     string `json:"content" binding:"required"`
	ParentID    string `json:"parent_id"`
	IsAnonymous bool   `json:"is_anonymous"`
}

type MessageRequest struct {
	Content string `json:"content" binding:"required"`
}

type ReviewRequest struct {
	Action string `json:"action" binding:"required"` // APPROVE, REJECT
	Reason string `json:"reason"`
}

var categories = []map[string]interface{}{
	{"code": "SALE", "name": "Satılık", "icon": "shopping_cart", "color": "#4CAF50"},
	{"code": "RENT", "name": "Kiralık", "icon": "home", "color": "#2196F3"},
	{"code": "LOST_FOUND", "name": "Kayıp/Buluntu", "icon": "search", "color": "#FF9800"},
	{"code": "HELP", "name": "Yardımlaşma", "icon": "handshake", "color": "#9C27B0"},
	{"code": "SUGGESTION", "name": "Öneri/Şikayet", "icon": "lightbulb", "color": "#FFC107"},
	{"code": "CARPOOL", "name": "Araç Paylaşımı", "icon": "directions_car", "color": "#00BCD4"},
	{"code": "SERVICE", "name": "Hizmet", "icon": "build", "color": "#795548"},
	{"code": "EVENT", "name": "Etkinlik", "icon": "event", "color": "#E91E63"},
}

// =====================================================
// HANDLERS
// =====================================================

func main() {
	r := gin.Default()

	r.GET("/health", stub.Health("bulletin"))

	v1 := r.Group("/api/v1")
	{
		// Categories
		v1.GET("/bulletin/categories", getCategories)

		// Posts
		posts := v1.Group("/bulletin/posts")
		{
			posts.GET("", listPosts)
			posts.GET("/pending", getPendingPosts)
			posts.GET("/my", getMyPosts)
			posts.GET("/:id", getPost)
			posts.POST("", createPost)
			posts.PUT("/:id", updatePost)
			posts.DELETE("/:id", deletePost)
			posts.POST("/:id/review", reviewPost)
			posts.POST("/:id/close", closePost)
			posts.POST("/:id/pin", pinPost)
			posts.POST("/:id/view", recordView)
		}

		// Comments
		comments := v1.Group("/bulletin/posts/:id/comments")
		{
			comments.GET("", getComments)
			comments.POST("", createComment)
			comments.DELETE("/:comment_id", deleteComment)
		}

		// Messages
		messages := v1.Group("/bulletin/messages")
		{
			messages.GET("", getMyMessages)
			messages.GET("/post/:post_id", getPostMessages)
			messages.POST("/post/:post_id", sendMessage)
			messages.POST("/:id/read", markAsRead)
		}
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8089"
	}

	log.Printf("Bulletin Service starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

func getCategories(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "bulletin")
}

// Post Handlers
func listPosts(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "bulletin")
}

func getPendingPosts(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "bulletin")
}

func getMyPosts(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "bulletin")
}

func getPost(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "bulletin")
}

func createPost(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "bulletin")
}

func updatePost(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "bulletin")
}

func deletePost(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "bulletin")
}

func reviewPost(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "bulletin")
}

func closePost(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "bulletin")
}

func pinPost(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "bulletin")
}

func recordView(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "bulletin")
}

// Comment Handlers
func getComments(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "bulletin")
}

func createComment(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "bulletin")
}

func deleteComment(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "bulletin")
}

// Message Handlers
func getMyMessages(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "bulletin")
}

func getPostMessages(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "bulletin")
}

func sendMessage(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "bulletin")
}

func markAsRead(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "bulletin")
}
