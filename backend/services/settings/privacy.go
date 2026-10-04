package main

// Kamera ve biyometrik sistem envanteri (FAZ 7.8, migration 046).
//
// Kamera listesi bütün site üyelerine açıktır: sakin, nerede ve ne amaçla kayıt
// yapıldığını, kaydın ne kadar saklandığını öğrenebilmelidir (KVKK m.10 aydınlatma).
// Uygunluk sorunları (levha yok, karar yok, maskeleme yok, yoğun özellik) yönetime listelenir.

import (
	"net/http"
	"slices"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/middleware"
)

var cameraAreas = []string{"ENTRANCE", "PERIMETER", "PARKING", "GARDEN", "LOBBY", "CORRIDOR", "ELEVATOR", "OTHER"}
var biometricMethods = []string{"FINGERPRINT", "FACE", "PALM", "IRIS", "OTHER"}

// prohibitedPlaces: kamera konulamayacak yerler (KVK Kurumu duyurusu 08/06/2026).
var prohibitedPlaces = []string{"tuvalet", "wc", "soyunma", "mescit", "ibadet", "duş", "banyo", "daire içi", "kapı önü"}

type camera struct {
	ID                     string    `json:"id"`
	Location               string    `json:"location"`
	AreaType               string    `json:"area_type"`
	Purpose                string    `json:"purpose"`
	RetentionDays          int       `json:"retention_days"`
	NoticePosted           bool      `json:"notice_posted"`
	Masked                 bool      `json:"masked"`
	AudioRecording         bool      `json:"audio_recording"`
	FaceRecognition        bool      `json:"face_recognition"`
	IntensiveJustification string    `json:"intensive_justification,omitempty"`
	DecisionRef            string    `json:"decision_ref,omitempty"`
	AccessNote             string    `json:"access_note,omitempty"`
	IsActive               bool      `json:"is_active"`
	Issues                 []string  `json:"issues,omitempty"`
	CreatedAt              time.Time `json:"created_at"`
}

func cameraIssues(c camera) []string {
	var out []string
	if !c.NoticePosted {
		out = append(out, "Aydınlatma levhası asılı değil (KVKK m.10)")
	}
	if strings.TrimSpace(c.DecisionRef) == "" {
		out = append(out, "Kat malikleri kurulu kararı kaydedilmemiş")
	}
	if !c.Masked {
		out = append(out, "Gereksiz alanların maskelendiği teyit edilmemiş")
	}
	if c.AudioRecording {
		out = append(out, "Ses kaydı yoğun müdahaledir; kaçınılması önerilir")
	}
	if c.FaceRecognition {
		out = append(out, "Yüz tanıma biyometrik veri işler; kaçınılması önerilir (açık rıza gerekir)")
	}
	if strings.TrimSpace(c.AccessNote) == "" {
		out = append(out, "Kayıtlara kimlerin erişebileceği belirtilmemiş")
	}
	return out
}

func listCameras(pool *pgxpool.Pool, mgmt func(*gin.Context) bool) gin.HandlerFunc {
	return func(c *gin.Context) {
		rows, err := dbscope.For(pool, c.GetString("property_id")).Query(c.Request.Context(), `
			SELECT id::text, location, area_type, purpose, retention_days, notice_posted, masked, audio_recording,
			       face_recognition, COALESCE(intensive_justification,''), COALESCE(decision_ref,''), COALESCE(access_note,''),
			       is_active, created_at
			FROM camera_devices WHERE property_id = $1 AND (is_active OR $2)
			ORDER BY is_active DESC, area_type, location`, c.GetString("property_id"), mgmt(c))
		if err != nil {
			failRetention(c, err, "kamera listesi")
			return
		}
		defer rows.Close()
		out := []camera{}
		open := 0
		for rows.Next() {
			var x camera
			if err := rows.Scan(&x.ID, &x.Location, &x.AreaType, &x.Purpose, &x.RetentionDays, &x.NoticePosted, &x.Masked,
				&x.AudioRecording, &x.FaceRecognition, &x.IntensiveJustification, &x.DecisionRef, &x.AccessNote, &x.IsActive, &x.CreatedAt); err != nil {
				failRetention(c, err, "kamera listesi")
				return
			}
			if mgmt(c) && x.IsActive {
				x.Issues = cameraIssues(x)
				open += len(x.Issues)
			} else if !mgmt(c) {
				// Sakine aydınlatma için gereken bilgi yeter; iç not ve karar referansı gösterilmez.
				x.AccessNote, x.DecisionRef, x.IntensiveJustification = "", "", ""
			}
			out = append(out, x)
		}
		resp := gin.H{"data": out}
		if mgmt(c) {
			resp["open_issues"] = open
		} else {
			resp["note"] = "Ortak alanlardaki kameralar, amaçları ve kayıtların saklama süresi. Kayıtlarla ilgili haklarınız için KVKK başvurusu yapabilirsiniz (m.11)."
		}
		c.JSON(http.StatusOK, resp)
	}
}

type cameraInput struct {
	Location               string `json:"location"`
	AreaType               string `json:"area_type"`
	Purpose                string `json:"purpose"`
	RetentionDays          int    `json:"retention_days"`
	NoticePosted           bool   `json:"notice_posted"`
	Masked                 bool   `json:"masked"`
	AudioRecording         bool   `json:"audio_recording"`
	FaceRecognition        bool   `json:"face_recognition"`
	IntensiveJustification string `json:"intensive_justification"`
	DecisionRef            string `json:"decision_ref"`
	AccessNote             string `json:"access_note"`
	IsActive               *bool  `json:"is_active"`
}

func validateCamera(c *gin.Context, in *cameraInput) bool {
	in.AreaType = strings.ToUpper(strings.TrimSpace(in.AreaType))
	in.Location, in.Purpose = strings.TrimSpace(in.Location), strings.TrimSpace(in.Purpose)
	in.IntensiveJustification = strings.TrimSpace(in.IntensiveJustification)
	low := strings.ToLower(in.Location)
	for _, p := range prohibitedPlaces {
		if strings.Contains(low, p) {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Bu konuma kamera konulamaz: bağımsız bölüm içi/kapı önü, tuvalet, soyunma ve ibadet yerleri " +
				"mahremiyet alanıdır (KVK Kurumu apartman kamera duyurusu, 08/06/2026)"})
			return false
		}
	}
	if !slices.Contains(cameraAreas, in.AreaType) || in.Location == "" || in.Purpose == "" || in.RetentionDays < 1 || in.RetentionDays > 365 {
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Konum, alan türü, amaç ve 1-365 gün saklama süresi zorunludur", "valid": cameraAreas})
		return false
	}
	if (in.AudioRecording || in.FaceRecognition || in.AreaType == "ELEVATOR") && in.IntensiveJustification == "" {
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Ses kaydı, yüz tanıma ve asansör kamerası yoğun müdahaledir; somut gerekçe zorunludur " +
			"(KVK Kurumu duyurusu: bu özelliklerden kaçınılmalı, asansör için somut gerekçe aranır)"})
		return false
	}
	return true
}

func createCamera(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in cameraInput
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		if !validateCamera(c, &in) {
			return
		}
		var id string
		if err := dbscope.For(pool, c.GetString("property_id")).QueryRow(c.Request.Context(), `
			INSERT INTO camera_devices (property_id, location, area_type, purpose, retention_days, notice_posted, masked,
			    audio_recording, face_recognition, intensive_justification, decision_ref, access_note)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NULLIF($10,''), NULLIF($11,''), NULLIF($12,'')) RETURNING id::text`,
			c.GetString("property_id"), in.Location, in.AreaType, in.Purpose, in.RetentionDays, in.NoticePosted, in.Masked,
			in.AudioRecording, in.FaceRecognition, in.IntensiveJustification, strings.TrimSpace(in.DecisionRef), strings.TrimSpace(in.AccessNote)).Scan(&id); err != nil {
			failRetention(c, err, "kamera kaydı")
			return
		}
		c.JSON(http.StatusCreated, gin.H{"id": id, "issues": cameraIssues(camera{NoticePosted: in.NoticePosted, Masked: in.Masked,
			AudioRecording: in.AudioRecording, FaceRecognition: in.FaceRecognition, DecisionRef: in.DecisionRef, AccessNote: in.AccessNote})})
	}
}

func updateCamera(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in cameraInput
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		if !validateCamera(c, &in) {
			return
		}
		active := true
		if in.IsActive != nil {
			active = *in.IsActive
		}
		tag, err := dbscope.For(pool, c.GetString("property_id")).Exec(c.Request.Context(), `
			UPDATE camera_devices SET location = $3, area_type = $4, purpose = $5, retention_days = $6, notice_posted = $7,
			    masked = $8, audio_recording = $9, face_recognition = $10, intensive_justification = NULLIF($11,''),
			    decision_ref = NULLIF($12,''), access_note = NULLIF($13,''), is_active = $14, updated_at = now()
			WHERE id = $1 AND property_id = $2`,
			c.Param("id"), c.GetString("property_id"), in.Location, in.AreaType, in.Purpose, in.RetentionDays, in.NoticePosted,
			in.Masked, in.AudioRecording, in.FaceRecognition, in.IntensiveJustification, strings.TrimSpace(in.DecisionRef),
			strings.TrimSpace(in.AccessNote), active)
		if err != nil {
			failRetention(c, err, "kamera güncelleme")
			return
		}
		if tag.RowsAffected() == 0 {
			c.JSON(http.StatusNotFound, gin.H{"error": "Kamera bulunamadı"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Kamera kaydı güncellendi"})
	}
}

func listBiometrics(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		rows, err := dbscope.For(pool, c.GetString("property_id")).Query(c.Request.Context(), `
			SELECT id::text, name, method, purpose, alternative_method, consent_based, COALESCE(retention_note,''), is_active, created_at
			FROM biometric_systems WHERE property_id = $1 ORDER BY is_active DESC, name`, c.GetString("property_id"))
		if err != nil {
			failRetention(c, err, "biyometrik liste")
			return
		}
		defer rows.Close()
		type item struct {
			ID                string    `json:"id"`
			Name              string    `json:"name"`
			Method            string    `json:"method"`
			Purpose           string    `json:"purpose"`
			AlternativeMethod string    `json:"alternative_method"`
			ConsentBased      bool      `json:"consent_based"`
			RetentionNote     string    `json:"retention_note,omitempty"`
			IsActive          bool      `json:"is_active"`
			CreatedAt         time.Time `json:"created_at"`
		}
		out := []item{}
		for rows.Next() {
			var x item
			if err := rows.Scan(&x.ID, &x.Name, &x.Method, &x.Purpose, &x.AlternativeMethod, &x.ConsentBased, &x.RetentionNote, &x.IsActive, &x.CreatedAt); err != nil {
				failRetention(c, err, "biyometrik liste")
				return
			}
			out = append(out, x)
		}
		c.JSON(http.StatusOK, gin.H{"data": out})
	}
}

func createBiometric(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Name              string `json:"name"`
			Method            string `json:"method"`
			Purpose           string `json:"purpose"`
			AlternativeMethod string `json:"alternative_method"`
			ConsentBased      bool   `json:"consent_based"`
			RetentionNote     string `json:"retention_note"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		in.Method = strings.ToUpper(strings.TrimSpace(in.Method))
		if !slices.Contains(biometricMethods, in.Method) || strings.TrimSpace(in.Name) == "" || strings.TrimSpace(in.Purpose) == "" {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Ad, yöntem ve amaç zorunludur", "valid": biometricMethods})
			return
		}
		if !in.ConsentBased || strings.TrimSpace(in.AlternativeMethod) == "" {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Biyometrik veri özel nitelikli kişisel veridir: açık rızaya dayanmalı (KVKK m.6/3-a) ve " +
				"rıza vermeyen için alternatif geçiş yöntemi (kart, şifre, görevli) sunulmalıdır; aksi hâlde rıza özgür olmaz"})
			return
		}
		var id string
		if err := dbscope.For(pool, c.GetString("property_id")).QueryRow(c.Request.Context(), `
			INSERT INTO biometric_systems (property_id, name, method, purpose, alternative_method, consent_based, retention_note)
			VALUES ($1, $2, $3, $4, $5, true, NULLIF($6,'')) RETURNING id::text`,
			c.GetString("property_id"), strings.TrimSpace(in.Name), in.Method, strings.TrimSpace(in.Purpose),
			strings.TrimSpace(in.AlternativeMethod), strings.TrimSpace(in.RetentionNote)).Scan(&id); err != nil {
			failRetention(c, err, "biyometrik kayıt")
			return
		}
		c.JSON(http.StatusCreated, gin.H{"id": id})
	}
}

// isPrivacyManager: uygunluk notlarını ve iç bilgileri görecek roller.
func isPrivacyManager(c *gin.Context) bool {
	v, _ := c.Get("roles")
	roles, _ := v.([]string)
	for _, r := range roles {
		if r == middleware.RoleManager || r == middleware.RoleBoardMember || r == middleware.RoleAuditor {
			return true
		}
	}
	return false
}
