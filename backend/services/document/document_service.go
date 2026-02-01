package document

import (
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"
)

// DocumentType belge türü
type DocumentType string

const (
	TypeGeneral  DocumentType = "general"  // Genel belgeler (tüm sakinler)
	TypeResident DocumentType = "resident" // Sakine özel belgeler
	TypeContract DocumentType = "contract" // Firma sözleşmeleri
)

// DocumentCategory belge kategorisi
type DocumentCategory string

const (
	CategoryOfficial DocumentCategory = "resmi"    // Resmi belgeler
	CategoryLegal    DocumentCategory = "yasal"    // Yasal belgeler
	CategoryRules    DocumentCategory = "kurallar" // Kurallar
	CategorySecurity DocumentCategory = "guvenlik" // Güvenlik
	CategoryContract DocumentCategory = "sozlesme" // Sözleşme
	CategoryDelivery DocumentCategory = "teslim"   // Teslim
	CategoryProperty DocumentCategory = "mulkiyet" // Mülkiyet
	CategoryAuth     DocumentCategory = "yetki"    // Yetki belgeleri
)

// Document belge modeli
type Document struct {
	ID          string           `json:"id"`
	Title       string           `json:"title"`
	Description string           `json:"description,omitempty"`
	Type        DocumentType     `json:"type"`
	Category    DocumentCategory `json:"category"`

	// Dosya bilgileri
	FileName string `json:"file_name"`
	FileType string `json:"file_type"` // pdf, docx, jpg, png
	FileSize int64  `json:"file_size"` // bytes
	FilePath string `json:"-"`         // Sunucu path (dışarıya açık değil)

	// Sakin bilgileri (sadece resident type için)
	ResidentID   *string `json:"resident_id,omitempty"`
	ResidentName *string `json:"resident_name,omitempty"`
	UnitNumber   *string `json:"unit_number,omitempty"`

	// Metadata
	UploadedBy string    `json:"uploaded_by"`
	UploadedAt time.Time `json:"uploaded_at"`
	UpdatedAt  time.Time `json:"updated_at"`
	ViewCount  int       `json:"view_count"`
	IsActive   bool      `json:"is_active"`

	// Yayın kontrolü
	PublishDate *time.Time `json:"publish_date,omitempty"`
	ExpireDate  *time.Time `json:"expire_date,omitempty"`
}

// UploadRequest belge yükleme isteği
type UploadRequest struct {
	Title       string           `json:"title" validate:"required"`
	Description string           `json:"description,omitempty"`
	Type        DocumentType     `json:"type" validate:"required"`
	Category    DocumentCategory `json:"category" validate:"required"`
	ResidentID  *string          `json:"resident_id,omitempty"` // Sadece resident type için
}

// DocumentFilter filtreleme parametreleri
type DocumentFilter struct {
	Type       DocumentType     `json:"type,omitempty"`
	Category   DocumentCategory `json:"category,omitempty"`
	ResidentID *string          `json:"resident_id,omitempty"`
	Search     string           `json:"search,omitempty"`
	Limit      int              `json:"limit,omitempty"`
	Offset     int              `json:"offset,omitempty"`
}

// DocumentStats istatistikler
type DocumentStats struct {
	TotalCount int                      `json:"total_count"`
	TotalSize  int64                    `json:"total_size"`
	TotalViews int                      `json:"total_views"`
	ByCategory map[DocumentCategory]int `json:"by_category"`
}

// ===================================
// SERVICE
// ===================================

// Service belge yönetim servisi
type Service struct {
	storagePath string
	// db connection would go here
}

// NewService yeni servis oluşturur
func NewService(storagePath string) (*Service, error) {
	// Storage klasörünü oluştur
	if err := os.MkdirAll(storagePath, 0755); err != nil {
		return nil, fmt.Errorf("storage klasörü oluşturulamadı: %w", err)
	}

	// Alt klasörleri oluştur
	subDirs := []string{"general", "resident", "contract"}
	for _, dir := range subDirs {
		if err := os.MkdirAll(filepath.Join(storagePath, dir), 0755); err != nil {
			return nil, err
		}
	}

	return &Service{
		storagePath: storagePath,
	}, nil
}

// ===================================
// CRUD İŞLEMLERİ
// ===================================

// Upload belge yükler
func (s *Service) Upload(ctx context.Context, req *UploadRequest, file io.Reader, fileName string, uploadedBy string) (*Document, error) {
	// Validasyon
	if req.Type == TypeResident && req.ResidentID == nil {
		return nil, errors.New("sakine özel belge için sakin ID gereklidir")
	}

	// Dosya türü kontrolü
	ext := strings.ToLower(filepath.Ext(fileName))
	allowedExts := map[string]bool{".pdf": true, ".docx": true, ".doc": true, ".jpg": true, ".jpeg": true, ".png": true}
	if !allowedExts[ext] {
		return nil, errors.New("desteklenmeyen dosya türü")
	}

	// Benzersiz ID ve dosya adı
	docID := uuid.New().String()
	safeFileName := fmt.Sprintf("%s%s", docID, ext)

	// Hedef klasör
	targetDir := filepath.Join(s.storagePath, string(req.Type))
	targetPath := filepath.Join(targetDir, safeFileName)

	// Dosyayı kaydet
	outFile, err := os.Create(targetPath)
	if err != nil {
		return nil, fmt.Errorf("dosya oluşturulamadı: %w", err)
	}
	defer outFile.Close()

	written, err := io.Copy(outFile, file)
	if err != nil {
		os.Remove(targetPath) // Temizlik
		return nil, fmt.Errorf("dosya yazılamadı: %w", err)
	}

	// Belge oluştur
	doc := &Document{
		ID:          docID,
		Title:       req.Title,
		Description: req.Description,
		Type:        req.Type,
		Category:    req.Category,
		FileName:    fileName,
		FileType:    strings.TrimPrefix(ext, "."),
		FileSize:    written,
		FilePath:    targetPath,
		ResidentID:  req.ResidentID,
		UploadedBy:  uploadedBy,
		UploadedAt:  time.Now(),
		UpdatedAt:   time.Now(),
		ViewCount:   0,
		IsActive:    true,
	}

	// TODO: Veritabanına kaydet

	return doc, nil
}

// GetByID ID ile belge getirir
func (s *Service) GetByID(ctx context.Context, id string) (*Document, error) {
	// TODO: Veritabanından al
	return nil, nil
}

// Delete belge siler
func (s *Service) Delete(ctx context.Context, id string) error {
	// TODO: Veritabanından ve diskten sil
	return nil
}

// List belgeleri listeler
func (s *Service) List(ctx context.Context, filter *DocumentFilter) ([]Document, error) {
	// TODO: Veritabanından filtreli liste al
	return nil, nil
}

// ===================================
// ERİŞİM KONTROLÜ
// ===================================

// CanAccess sakin belgeye erişebilir mi?
func (s *Service) CanAccess(ctx context.Context, documentID, residentID string) (bool, error) {
	doc, err := s.GetByID(ctx, documentID)
	if err != nil {
		return false, err
	}

	if doc == nil {
		return false, errors.New("belge bulunamadı")
	}

	// Genel belgeler herkese açık
	if doc.Type == TypeGeneral {
		return true, nil
	}

	// Sakine özel belgeler sadece o sakine açık
	if doc.Type == TypeResident {
		if doc.ResidentID == nil || *doc.ResidentID != residentID {
			return false, nil
		}
		return true, nil
	}

	// Firma sözleşmeleri sadece yöneticilere açık
	return false, nil
}

// GetForResident sakin için erişilebilir belgeleri getirir
func (s *Service) GetForResident(ctx context.Context, residentID string) ([]Document, []Document, error) {
	// Genel belgeler
	generalDocs, err := s.List(ctx, &DocumentFilter{Type: TypeGeneral})
	if err != nil {
		return nil, nil, err
	}

	// Sakine özel belgeler
	residentDocs, err := s.List(ctx, &DocumentFilter{
		Type:       TypeResident,
		ResidentID: &residentID,
	})
	if err != nil {
		return nil, nil, err
	}

	return generalDocs, residentDocs, nil
}

// ===================================
// DOWNLOAD
// ===================================

// GetFilePath belge dosya yolunu döner (erişim kontrolü sonrası)
func (s *Service) GetFilePath(ctx context.Context, id string) (string, string, error) {
	doc, err := s.GetByID(ctx, id)
	if err != nil {
		return "", "", err
	}

	if doc == nil {
		return "", "", errors.New("belge bulunamadı")
	}

	// Görüntüleme sayısını artır
	doc.ViewCount++
	// TODO: Veritabanına kaydet

	return doc.FilePath, doc.FileName, nil
}

// ===================================
// İSTATİSTİKLER
// ===================================

// GetStats belge istatistiklerini döner
func (s *Service) GetStats(ctx context.Context, docType DocumentType) (*DocumentStats, error) {
	// TODO: Veritabanından al
	return &DocumentStats{
		TotalCount: 0,
		TotalSize:  0,
		TotalViews: 0,
		ByCategory: make(map[DocumentCategory]int),
	}, nil
}

// ===================================
// YARDIMCI FONKSİYONLAR
// ===================================

// FormatFileSize dosya boyutunu okunabilir formata çevirir
func FormatFileSize(bytes int64) string {
	const (
		KB = 1024
		MB = KB * 1024
		GB = MB * 1024
	)

	switch {
	case bytes >= GB:
		return fmt.Sprintf("%.1f GB", float64(bytes)/GB)
	case bytes >= MB:
		return fmt.Sprintf("%.1f MB", float64(bytes)/MB)
	case bytes >= KB:
		return fmt.Sprintf("%.1f KB", float64(bytes)/KB)
	default:
		return fmt.Sprintf("%d B", bytes)
	}
}
