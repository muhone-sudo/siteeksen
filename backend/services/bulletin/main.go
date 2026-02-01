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

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "bulletin",
			"version": "1.0.0",
		})
	})

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
		comments := v1.Group("/bulletin/posts/:post_id/comments")
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
		port = "8094"
	}

	log.Printf("Bulletin Service starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

func getCategories(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"categories": categories})
}

// Post Handlers
func listPosts(c *gin.Context) {
	// Query params: category, status, search
	now := time.Now()
	expiry := now.Add(14 * 24 * time.Hour)

	posts := []BulletinPost{
		{
			ID:              uuid.New().String(),
			PropertyID:      "prop-1",
			UnitID:          "unit-101",
			AuthorName:      "Ali V.",
			UnitNumber:      "D.101",
			Category:        "SALE",
			Title:           "IKEA Koltuk Takımı - Az Kullanılmış",
			Content:         "3+2+1 koltuk takımı, gri renk, 2 yıllık, çok temiz kullanılmış. Taşınma nedeniyle satılıktır.",
			PhotoURLs:       []string{"/images/couch1.jpg", "/images/couch2.jpg"},
			Price:           8500,
			PriceNegotiable: true,
			Status:          "APPROVED",
			ExpiresAt:       &expiry,
			ViewCount:       45,
			ContactCount:    3,
			CommentCount:    2,
			CreatedAt:       now.Add(-48 * time.Hour),
		},
		{
			ID:           uuid.New().String(),
			PropertyID:   "prop-1",
			UnitID:       "unit-205",
			AuthorName:   "Ayşe K.",
			UnitNumber:   "D.205",
			Category:     "LOST_FOUND",
			Title:        "Siyah Cüzdan Bulundu",
			Content:      "B Blok girişinde siyah deri cüzdan bulunmuştur. Sahibi güvenliğe başvurabilir.",
			Status:       "APPROVED",
			ViewCount:    120,
			CommentCount: 5,
			CreatedAt:    now.Add(-24 * time.Hour),
		},
		{
			ID:           uuid.New().String(),
			PropertyID:   "prop-1",
			UnitID:       "unit-301",
			AuthorName:   "Mehmet D.",
			UnitNumber:   "D.301",
			Category:     "CARPOOL",
			Title:        "İTÜ Maslak - Hafta içi sabah",
			Content:      "Hafta içi her sabah 08:00'de İTÜ Maslak'a gidiyorum. Yol arkadaşı arıyorum.",
			Status:       "APPROVED",
			ViewCount:    35,
			ContactCount: 2,
			CreatedAt:    now.Add(-72 * time.Hour),
		},
		{
			ID:           uuid.New().String(),
			PropertyID:   "prop-1",
			AuthorName:   "Anonim",
			Category:     "SUGGESTION",
			Title:        "Otopark aydınlatması yetersiz",
			Content:      "B Blok otoparkının aydınlatması çok yetersiz. Akşam saatlerinde güvenlik sorunu oluşturuyor. Lütfen ek aydınlatma yapılsın.",
			IsAnonymous:  true,
			Status:       "APPROVED",
			ViewCount:    85,
			CommentCount: 8,
			IsPinned:     true,
			CreatedAt:    now.Add(-12 * time.Hour),
		},
	}

	c.JSON(http.StatusOK, gin.H{"posts": posts, "total": len(posts)})
}

func getPendingPosts(c *gin.Context) {
	now := time.Now()
	posts := []BulletinPost{
		{
			ID:         uuid.New().String(),
			AuthorName: "Zeynep Y.",
			UnitNumber: "D.405",
			Category:   "SERVICE",
			Title:      "Temizlik Hizmeti Önerisi",
			Content:    "Güvenilir ev temizliği yapan birini arıyorum. Önerilerinizi bekliyorum.",
			Status:     "PENDING",
			CreatedAt:  now.Add(-1 * time.Hour),
		},
	}
	c.JSON(http.StatusOK, gin.H{"posts": posts, "count": len(posts)})
}

func getMyPosts(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"posts": []BulletinPost{}, "total": 0})
}

func getPost(c *gin.Context) {
	id := c.Param("id")
	now := time.Now()
	expiry := now.Add(14 * 24 * time.Hour)

	post := BulletinPost{
		ID:              id,
		PropertyID:      "prop-1",
		UnitID:          "unit-101",
		AuthorName:      "Ali V.",
		UnitNumber:      "D.101",
		Category:        "SALE",
		Title:           "IKEA Koltuk Takımı - Az Kullanılmış",
		Content:         "3+2+1 koltuk takımı, gri renk, 2 yıllık, çok temiz kullanılmış. Taşınma nedeniyle satılıktır.",
		PhotoURLs:       []string{"/images/couch1.jpg", "/images/couch2.jpg"},
		Price:           8500,
		PriceNegotiable: true,
		Status:          "APPROVED",
		ExpiresAt:       &expiry,
		ViewCount:       45,
		ContactCount:    3,
		CommentCount:    2,
		CreatedAt:       now.Add(-48 * time.Hour),
	}
	c.JSON(http.StatusOK, post)
}

func createPost(c *gin.Context) {
	var req PostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	now := time.Now()
	expiry := now.Add(14 * 24 * time.Hour)

	post := BulletinPost{
		ID:              uuid.New().String(),
		PropertyID:      "prop-1",
		UnitID:          "unit-101",
		AuthorID:        "user-1",
		Category:        req.Category,
		Title:           req.Title,
		Content:         req.Content,
		PhotoURLs:       req.PhotoURLs,
		Price:           req.Price,
		PriceNegotiable: req.PriceNegotiable,
		IsAnonymous:     req.IsAnonymous,
		Status:          "PENDING",
		ExpiresAt:       &expiry,
		CreatedAt:       now,
		UpdatedAt:       now,
	}

	c.JSON(http.StatusCreated, post)
}

func updatePost(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{"id": id, "message": "İlan güncellendi"})
}

func deletePost(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{"id": id, "message": "İlan silindi"})
}

func reviewPost(c *gin.Context) {
	id := c.Param("id")
	var req ReviewRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	status := "APPROVED"
	if req.Action == "REJECT" {
		status = "REJECTED"
	}

	c.JSON(http.StatusOK, gin.H{
		"id":      id,
		"status":  status,
		"message": "İlan değerlendirildi",
	})
}

func closePost(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{
		"id":      id,
		"status":  "CLOSED",
		"message": "İlan kapatıldı",
	})
}

func pinPost(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{
		"id":        id,
		"is_pinned": true,
		"message":   "İlan sabitlendi",
	})
}

func recordView(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{"id": id, "view_count": 46})
}

// Comment Handlers
func getComments(c *gin.Context) {
	postID := c.Param("post_id")
	now := time.Now()

	comments := []BulletinComment{
		{
			ID:         uuid.New().String(),
			PostID:     postID,
			AuthorName: "Zeynep K.",
			Content:    "İlgileniyorum, hala satılık mı?",
			CreatedAt:  now.Add(-12 * time.Hour),
			Replies: []BulletinComment{
				{
					ID:         uuid.New().String(),
					PostID:     postID,
					AuthorName: "Ali V.",
					Content:    "Evet, hala satılık. Görüşmek isterseniz mesaj atabilirsiniz.",
					CreatedAt:  now.Add(-10 * time.Hour),
				},
			},
		},
	}
	c.JSON(http.StatusOK, gin.H{"comments": comments})
}

func createComment(c *gin.Context) {
	postID := c.Param("post_id")
	var req CommentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	comment := BulletinComment{
		ID:          uuid.New().String(),
		PostID:      postID,
		AuthorID:    "user-1",
		Content:     req.Content,
		ParentID:    req.ParentID,
		IsAnonymous: req.IsAnonymous,
		CreatedAt:   time.Now(),
	}

	c.JSON(http.StatusCreated, comment)
}

func deleteComment(c *gin.Context) {
	commentID := c.Param("comment_id")
	c.JSON(http.StatusOK, gin.H{"id": commentID, "message": "Yorum silindi"})
}

// Message Handlers
func getMyMessages(c *gin.Context) {
	now := time.Now()
	messages := []BulletinMessage{
		{
			ID:         uuid.New().String(),
			PostID:     "post-1",
			SenderName: "Mehmet D.",
			Content:    "Merhaba, koltuk takımı için pazarlık yapabilir miyiz?",
			IsRead:     false,
			CreatedAt:  now.Add(-2 * time.Hour),
		},
	}
	c.JSON(http.StatusOK, gin.H{"messages": messages, "unread_count": 1})
}

func getPostMessages(c *gin.Context) {
	postID := c.Param("post_id")
	c.JSON(http.StatusOK, gin.H{"post_id": postID, "messages": []BulletinMessage{}})
}

func sendMessage(c *gin.Context) {
	postID := c.Param("post_id")
	var req MessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	message := BulletinMessage{
		ID:        uuid.New().String(),
		PostID:    postID,
		SenderID:  "user-1",
		Content:   req.Content,
		CreatedAt: time.Now(),
	}

	c.JSON(http.StatusCreated, message)
}

func markAsRead(c *gin.Context) {
	id := c.Param("id")
	now := time.Now()
	c.JSON(http.StatusOK, gin.H{
		"id":      id,
		"is_read": true,
		"read_at": now,
	})
}
