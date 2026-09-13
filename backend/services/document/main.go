// document-service — Site belgelerinin arşivi (yönetim planı, karar tutanağı,
// işletme projesi, sigorta poliçesi, fatura, dava evrakı…).
//
// DURUM DEĞİŞİKLİĞİ (2026-09-13): Bu servis mock'tu; sabit belge listesi
// döndürüyor, yükleme ucuna 2xx dönüp DOSYAYI HİÇBİR YERE YAZMIYORDU.
// Artık gerçek veri katmanına ve gerçek nesne deposuna bağlıdır (FAZ 5 — 8/22).
//
// Hukuki çerçeve:
//   - KMK m.36: yönetici, belgeleri kat maliklerinin incelemesine hazır bulundurur.
//     Bu yüzden hesap belgeleri kat maliklerine açıktır (visibility=OWNERS).
//   - KVKK m.4: veri minimizasyonu. Özlük dosyası, sözleşme ve dava evrakı
//     yalnızca yönetim ve denetçiye açıktır (visibility=MANAGEMENT).
//   - KVKK m.12: belgeye kimin, ne zaman eriştiği kayda geçer
//     (document_access_logs; salt-ekleme, veritabanı tetikleyicisiyle korunur).
//
// Dosya saklama sağlayıcısı ortam değişkenleriyle seçilir (pkg/storage):
// yerel dosya sistemi ya da S3 uyumlu (Oracle / Cloudflare R2 / AWS).
// Yapılandırma eksikse servis SESSİZCE ÇALIŞMAYA DEVAM ETMEZ; açılışta durur.
package main

import (
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/storage"
	"github.com/siteeksen/backend/services/document/repository"
)

func main() {
	dbConfig := database.NewConfigFromEnv()
	pool, err := database.Connect(dbConfig)
	if err != nil {
		log.Fatalf("Veritabanı bağlantısı başarısız: %v", err)
	}
	defer database.Close()

	store, err := storage.FromEnv()
	if err != nil {
		// Depolama olmadan bu servis belge saklıyormuş gibi davranamaz.
		log.Fatalf("Dosya depolama yapılandırılamadı: %v", err)
	}
	log.Printf("Dosya depolama: %s", store.Backend())

	repo := repository.New(pool)

	r := gin.Default()
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy", "service": "document", "persistent": true,
			"storage": store.Describe(),
		})
	})

	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "document"))

	api.GET("/documents", func(c *gin.Context) {
		allowed := allowedVisibilities(c)
		list, err := repo.List(c.Request.Context(), c.GetString("property_id"),
			repository.ListFilter{
				Category:            c.Query("category"),
				RelatedType:         c.Query("related_type"),
				RelatedID:           c.Query("related_id"),
				IncludeOldVer:       c.Query("include_versions") == "true",
				IncludeArchiv:       c.Query("include_archived") == "true" && isManagement(c),
				AllowedVisibilities: allowed,
			})
		if err != nil {
			fail(c, err, "listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list, "visible_levels": allowed})
	})

	api.GET("/documents-summary", func(c *gin.Context) {
		s, err := repo.Summary(c.Request.Context(), c.GetString("property_id"), allowedVisibilities(c))
		if err != nil {
			fail(c, err, "özet")
			return
		}
		c.JSON(http.StatusOK, s)
	})

	api.GET("/documents/:id", func(c *gin.Context) {
		propertyID := c.GetString("property_id")
		d, err := repo.Get(c.Request.Context(), propertyID, c.Param("id"), allowedVisibilities(c))
		if err != nil {
			logAccessAttempt(c, repo, propertyID, "DENIED")
			fail(c, err, "okuma")
			return
		}
		if err := repo.LogAccess(c.Request.Context(), propertyID, d.ID,
			c.GetString("user_id"), "VIEW", c.ClientIP(), c.Request.UserAgent()); err != nil {
			// KVKK erişim kaydı yazılamıyorsa belge de verilmez: eksik denetim
			// izi, belgenin kimin eline geçtiğinin kanıtlanamaması demektir.
			log.Printf("[document] erişim kaydı yazılamadı: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Erişim kaydı tutulamadığı için belge açılamadı"})
			return
		}
		c.JSON(http.StatusOK, d)
	})

	// Dosyanın kendisini indirir. Nesne deposundan okunur; istemciye depo
	// anahtarı ya da imzalı adres verilmez.
	api.GET("/documents/:id/download", func(c *gin.Context) {
		propertyID := c.GetString("property_id")
		d, err := repo.Get(c.Request.Context(), propertyID, c.Param("id"), allowedVisibilities(c))
		if err != nil {
			logAccessAttempt(c, repo, propertyID, "DENIED")
			fail(c, err, "indirme")
			return
		}
		if err := repo.LogAccess(c.Request.Context(), propertyID, d.ID,
			c.GetString("user_id"), "DOWNLOAD", c.ClientIP(), c.Request.UserAgent()); err != nil {
			log.Printf("[document] erişim kaydı yazılamadı: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Erişim kaydı tutulamadığı için belge indirilemedi"})
			return
		}

		rc, obj, err := store.Get(c.Request.Context(), d.StorageKey)
		if err != nil {
			fail(c, err, "depodan okuma")
			return
		}
		defer rc.Close() //nolint:errcheck

		c.Header("Content-Disposition",
			fmt.Sprintf("attachment; filename=%q", d.FileName))
		c.Header("X-Document-SHA256", d.SHA256)
		c.DataFromReader(http.StatusOK, obj.Size, d.ContentType, rc, nil)
	})

	// --- Yazma: yönetim ---
	write := api.Group("")
	write.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
	{
		write.POST("/documents", func(c *gin.Context) {
			propertyID := c.GetString("property_id")

			fileHeader, err := c.FormFile("file")
			if err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "multipart/form-data içinde 'file' alanı zorunludur"})
				return
			}
			title := strings.TrimSpace(c.PostForm("title"))
			if title == "" {
				title = fileHeader.Filename
			}
			category := c.PostForm("category")
			if strings.TrimSpace(category) == "" {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "category zorunludur", "valid": repository.Categories})
				return
			}

			var retention *time.Time
			if v := strings.TrimSpace(c.PostForm("retention_until")); v != "" {
				t, perr := time.Parse("2006-01-02", v)
				if perr != nil {
					c.JSON(http.StatusBadRequest, gin.H{
						"error": "retention_until YYYY-AA-GG biçiminde olmalıdır"})
					return
				}
				retention = &t
			}

			src, err := fileHeader.Open()
			if err != nil {
				fail(c, err, "dosya okuma")
				return
			}
			defer src.Close() //nolint:errcheck

			// Anahtar site kimliğiyle başlar: bir sitenin belgeleri başka bir
			// sitenin ön ekine yazılamaz.
			key := fmt.Sprintf("properties/%s/documents/%s%s",
				propertyID, uuid.NewString(), safeExt(fileHeader.Filename))

			obj, err := store.Put(c.Request.Context(), key,
				fileHeader.Header.Get("Content-Type"), src)
			if err != nil {
				fail(c, err, "depoya yazma")
				return
			}

			id, err := repo.Create(c.Request.Context(), propertyID, c.GetString("user_id"),
				repository.CreateInput{
					Category:       category,
					Title:          title,
					Description:    c.PostForm("description"),
					Visibility:     c.PostForm("visibility"),
					StorageBackend: store.Backend(),
					StorageKey:     key,
					FileName:       filepath.Base(fileHeader.Filename),
					ContentType:    obj.ContentType,
					SizeBytes:      obj.Size,
					SHA256:         obj.SHA256,
					RelatedType:    c.PostForm("related_type"),
					RelatedID:      c.PostForm("related_id"),
					ReplacesID:     c.PostForm("replaces_id"),
					RetentionUntil: retention,
					Notes:          c.PostForm("notes"),
				})
			if err != nil {
				// Üst veri yazılamadıysa depoda öksüz dosya bırakmayız.
				if derr := store.Delete(c.Request.Context(), key); derr != nil {
					log.Printf("[document] öksüz dosya silinemedi (%s): %v", key, derr)
				}
				fail(c, err, "kayıt")
				return
			}

			c.JSON(http.StatusCreated, gin.H{
				"id": id, "sha256": obj.SHA256, "size_bytes": obj.Size,
				"storage_backend": store.Backend(),
				"note": "Dosya gerçekten saklandı. SHA-256 özeti, belgenin sonradan " +
					"değişmediğini kanıtlamak için saklanır.",
			})
		})

		write.POST("/documents/:id/archive", func(c *gin.Context) {
			var in struct {
				Reason string `json:"reason" binding:"required"`
			}
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Arşivden çıkarma gerekçesi zorunludur"})
				return
			}
			if err := repo.Archive(c.Request.Context(), c.GetString("property_id"),
				c.Param("id"), c.GetString("user_id"), strings.TrimSpace(in.Reason)); err != nil {
				fail(c, err, "arşivleme")
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"message": "Belge arşivden çıkarıldı",
				"note": "Kayıt ve dosya SİLİNMEDİ; hukuki saklama yükümlülüğü ve " +
					"denetim izi için korunur.",
			})
		})
	}

	// Erişim kayıtları yalnızca yönetim ve denetçiye açıktır.
	audit := api.Group("")
	audit.Use(middleware.RequireRole(
		middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleAuditor))
	{
		audit.GET("/documents/:id/access-log", func(c *gin.Context) {
			list, err := repo.AccessLog(c.Request.Context(),
				c.GetString("property_id"), c.Param("id"))
			if err != nil {
				fail(c, err, "erişim kaydı")
				return
			}
			c.JSON(http.StatusOK, gin.H{"data": list})
		})
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8091" // kong/kong.yml ile aynı olmalı
	}
	log.Printf("Document Service başlatıldı: :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

// allowedVisibilities, isteği yapanın görebileceği görünürlük kademelerini verir.
//
// Kademeler geniş → dar: RESIDENTS ⊂ OWNERS ⊂ MANAGEMENT.
//   - Yönetim ve denetçi: hepsi
//   - Kat maliki (OWNER): RESIDENTS + OWNERS — KMK m.36 inceleme hakkı
//   - Kiracı/diğer sakin: yalnızca RESIDENTS
//
// Hiçbir rol yoksa boş liste döner ve hiçbir belge görünmez (fail-closed).
func allowedVisibilities(c *gin.Context) []string {
	if isManagement(c) {
		return []string{"RESIDENTS", "OWNERS", "MANAGEMENT"}
	}
	if hasRole(c, middleware.RoleOwner) {
		return []string{"RESIDENTS", "OWNERS"}
	}
	if hasRole(c, middleware.RoleResident, middleware.RoleTenant) {
		return []string{"RESIDENTS"}
	}
	return nil
}

func isManagement(c *gin.Context) bool {
	return hasRole(c, middleware.RoleManager, middleware.RoleBoardMember,
		middleware.RoleAuditor, middleware.RoleSuperAdmin)
}

func hasRole(c *gin.Context, want ...string) bool {
	value, _ := c.Get("roles")
	roles, _ := value.([]string)
	for _, r := range roles {
		for _, w := range want {
			if r == w {
				return true
			}
		}
	}
	return false
}

// logAccessAttempt, başarısız erişim denemesini kayda geçirmeye çalışır.
// Belge kimliği geçerli bir UUID değilse ya da kayıt yoksa yazılamaz; bu
// durumda audit_logs zaten isteği DENIED olarak tutar.
func logAccessAttempt(c *gin.Context, repo *repository.Repository, propertyID, action string) {
	id := c.Param("id")
	if _, err := uuid.Parse(id); err != nil {
		return
	}
	if err := repo.LogAccess(c.Request.Context(), propertyID, id,
		c.GetString("user_id"), action, c.ClientIP(), c.Request.UserAgent()); err != nil {
		log.Printf("[document] reddedilen erişim kaydedilemedi: %v", err)
	}
}

// safeExt, dosya uzantısını güvenli biçimde alır. Uzantı yalnızca depo
// anahtarını okunur kılmak içindir; içerik türü belirlemede kullanılmaz.
func safeExt(name string) string {
	ext := strings.ToLower(filepath.Ext(name))
	if len(ext) > 10 {
		return ""
	}
	for _, r := range ext {
		if !(r == '.' || (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9')) {
			return ""
		}
	}
	return ext
}

func fail(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, repository.ErrNotFound), errors.Is(err, storage.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Belge bulunamadı"})
	case errors.Is(err, repository.ErrInvalidCategory):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Geçersiz belge kategorisi", "valid": repository.Categories})
	case errors.Is(err, repository.ErrInvalidVisible):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Geçersiz görünürlük", "valid": repository.Visibilities})
	case errors.Is(err, repository.ErrAlreadyArchived):
		c.JSON(http.StatusConflict, gin.H{"error": "Belge zaten arşivden çıkarılmış"})
	case errors.Is(err, repository.ErrDuplicateKey):
		c.JSON(http.StatusConflict, gin.H{"error": "Bu dosya zaten kayıtlı"})
	case errors.Is(err, storage.ErrTooLarge):
		c.JSON(http.StatusRequestEntityTooLarge, gin.H{
			"error": "Dosya izin verilen boyutu aşıyor"})
	case errors.Is(err, storage.ErrInvalidKey):
		c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz dosya adı"})
	default:
		log.Printf("[document] %s başarısız: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}
