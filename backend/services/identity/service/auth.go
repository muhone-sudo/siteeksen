package service

import (
	"context"
	"errors"
	"fmt"
	"log"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/siteeksen/backend/pkg/revocation"
	"github.com/siteeksen/backend/services/identity/models"
	"github.com/siteeksen/backend/services/identity/repository"
	"golang.org/x/crypto/bcrypt"
)

// TokenPair JWT token çifti
type TokenPair struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int64  `json:"expires_in"`
}

// AuthService kimlik doğrulama servisi
type AuthService struct {
	userRepo  *repository.UserRepository
	jwtSecret []byte
	// revocations, jeton iptal denetimidir (FAZ 2.7). Yenileme akışında
	// kullanılır; nil bırakılırsa iptal denetimi YAPILMAZ.
	revocations *revocation.Checker
}

// NewAuthService yeni servis oluşturur
func NewAuthService(userRepo *repository.UserRepository, jwtSecret string) *AuthService {
	return &AuthService{
		userRepo:  userRepo,
		jwtSecret: []byte(jwtSecret),
	}
}

// Login kullanıcı girişi yapar
func (s *AuthService) Login(ctx context.Context, phone, password string) (*TokenPair, *models.UserResponse, error) {
	user, err := s.userRepo.GetByPhone(ctx, phone)
	if errors.Is(err, pgx.ErrNoRows) {
		_ = bcrypt.CompareHashAndPassword(dummyHash, []byte(password))
		return nil, nil, ErrInvalidCredentials
	}
	if err != nil {
		// Veritabanı arızası "yanlış şifre" gibi GÖSTERİLMEZ: kullanıcı doğru
		// şifreyi tekrar tekrar dener, yönetici arızayı fark etmez.
		return nil, nil, fmt.Errorf("kullanıcı okunamadı: %w", err)
	}

	// Giriş kilidi (migration 027): art arda 5 hatadan sonra 15 dakika. Önceden
	// deneme sınırı yoktu; bir telefon numarasına sınırsız şifre denenebiliyordu.
	// Kilitliyken de karşılaştırma YAPILIR (yanıt süresi kilit durumunu sızdırmasın)
	// ve aynı genel hata döner.
	lockedUntil, err := s.userRepo.LockState(ctx, user.ID)
	if err != nil {
		return nil, nil, fmt.Errorf("kilit durumu okunamadı: %w", err)
	}
	mismatch := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)) != nil
	if lockedUntil != nil && time.Now().Before(*lockedUntil) {
		return nil, nil, ErrInvalidCredentials
	}
	if mismatch {
		if err := s.userRepo.RecordLoginFailure(ctx, user.ID, loginFailureThreshold, loginLockDuration); err != nil {
			return nil, nil, fmt.Errorf("hatalı giriş kaydedilemedi: %w", err)
		}
		return nil, nil, ErrInvalidCredentials
	}
	if err := s.userRepo.ResetLoginFailures(ctx, user.ID); err != nil {
		return nil, nil, fmt.Errorf("giriş kaydı güncellenemedi: %w", err)
	}

	properties, err := s.ensureActiveProperty(ctx, user)
	if err != nil {
		return nil, nil, err
	}

	// Roller bir kez çözülür; hem jetona hem de yanıta AYNI küme yazılır.
	// Yanıta yazılmadığı sürece panel oturumunda rol bulunmuyordu ve giriş yapan
	// herkes yetkisiz sayılıyordu.
	roles, err := s.resolveRoles(ctx, user)
	if err != nil {
		return nil, nil, err
	}

	tokens, err := s.generateTokens(user, roles)
	if err != nil {
		return nil, nil, err
	}

	response := &models.UserResponse{
		ID:                  user.ID,
		FirstName:           user.FirstName,
		LastName:            user.LastName,
		Phone:               user.Phone,
		Email:               user.Email,
		ActivePropertyID:    user.ActivePropertyID,
		Roles:               roles,
		Properties:          properties,
		KVKKConsentRequired: user.KVKKConsentAt == nil,
	}

	return tokens, response, nil
}

// RefreshToken token yeniler
// ErrTokenRevoked, iptal edilmiş bir jetonla yenileme denendiğinde döner.
var ErrTokenRevoked = errors.New("jeton iptal edilmiş; yeniden giriş yapılmalı")

// ErrTokenReused, tüketilmiş yenileme jetonu yeniden sunulduğunda döner. Bu
// durumda kullanıcının BÜTÜN oturumları kapatılmıştır.
var ErrTokenReused = errors.New("yenileme jetonu daha önce kullanılmış; güvenlik için bütün oturumlar kapatıldı")

// refreshReuseGrace, aynı jetonun eşzamanlı ikinci kullanımına (iki sekme,
// ağ yeniden denemesi) tanınan süredir. Bu süreden sonra tekrar kullanım
// çalınma işareti sayılır.
const refreshReuseGrace = 30 * time.Second

// ErrInvalidCredentials, telefon ya da şifre yanlış, hesap yok, pasif ya da
// geçici olarak kilitli. Hepsi BİLEREK aynı hatadır: hangisi olduğunu söylemek
// hesap varlığını sızdırır.
var ErrInvalidCredentials = errors.New("geçersiz telefon veya şifre")

// ErrInvalidToken, yenileme jetonu geçersiz ya da kullanıcı artık yok/pasif.
var ErrInvalidToken = errors.New("geçersiz yenileme jetonu")

// ErrRevocationUnavailable, iptal denetimi yapılamadığında döner (fail-closed).
var ErrRevocationUnavailable = errors.New("jeton iptal denetimi yapılamadı")

// dummyHash, bulunamayan kullanıcı için de bcrypt karşılaştırması yapılmasını
// sağlar. Önceden kullanıcı yoksa karşılaştırma HİÇ yapılmıyor ve yanıt
// belirgin biçimde hızlı dönüyordu: yanıt süresinden bir telefon numarasının
// sistemde kayıtlı olup olmadığı anlaşılabiliyordu (kullanıcı sayımı).
var dummyHash, _ = bcrypt.GenerateFromPassword([]byte("zamanlama-esitleme"), bcrypt.DefaultCost)

// RefreshToken, yenileme jetonuyla yeni jeton çifti üretir.
//
// İPTAL DENETİMİ ŞART: çıkışta iptal edilmiş bir yenileme jetonu, denetlenmezse
// 7 gün boyunca yeni erişim jetonu üretmeye devam ederdi — yani çıkış hiçbir işe
// yaramazdı. Denetim yapılamıyorsa jeton KABUL EDİLMEZ (fail-closed).
func (s *AuthService) RefreshToken(ctx context.Context, refreshToken string) (*TokenPair, error) {
	claims := &jwt.RegisteredClaims{}
	token, err := jwt.ParseWithClaims(refreshToken, claims, func(t *jwt.Token) (interface{}, error) {
		return s.jwtSecret, nil
	})

	if err != nil || !token.Valid {
		return nil, ErrInvalidToken
	}

	// Çıkışta iptal edilen bir yenileme jetonu, denetlenmezse 7 GÜN boyunca yeni
	// erişim jetonu üretmeye devam eder — yani "çıkış yap" hiçbir işe yaramaz.
	// Ayrıca jeton TEK KULLANIMLIKTIR (rotation): kullanılınca tükenir.
	if s.revocations == nil {
		// Fail-closed: iptal ve tek kullanım denetimi olmadan yenileme yapılmaz.
		return nil, ErrRevocationUnavailable
	}
	if claims.ID == "" {
		return nil, ErrInvalidToken
	}
	var issuedAt time.Time
	if claims.IssuedAt != nil {
		issuedAt = claims.IssuedAt.Time
	}
	var expiresAt time.Time
	if claims.ExpiresAt != nil {
		expiresAt = claims.ExpiresAt.Time
	}
	use, rerr := s.revocations.ClaimRefresh(ctx, claims.ID, claims.Subject, expiresAt, refreshReuseGrace)
	if rerr != nil {
		// Fail-closed: denetim yapılamıyorsa jeton kabul edilmez. Aksi hâlde
		// iptal mekanizması, veritabanını yoran bir saldırganca kapatılabilirdi.
		return nil, fmt.Errorf("%w: %v", ErrRevocationUnavailable, rerr)
	}
	switch use {
	case revocation.RefreshRevoked:
		return nil, ErrTokenRevoked
	case revocation.RefreshReused:
		// Meşru istemci yeni jetonu çoktan aldı; eski jetonu sunan kişi
		// büyük olasılıkla onu ele geçirmiştir. Hangisinin saldırgan olduğu
		// bilinemediği için kullanıcının BÜTÜN oturumları kapatılır.
		if err := s.revocations.RevokeAll(ctx, claims.Subject, "REFRESH_REUSE"); err != nil {
			return nil, fmt.Errorf("%w: %v", ErrRevocationUnavailable, err)
		}
		log.Printf("[identity] GÜVENLİK: tüketilmiş yenileme jetonu yeniden kullanıldı; kullanıcının bütün oturumları kapatıldı (jti=%s)", claims.ID)
		return nil, ErrTokenReused
	}
	invalidated, rerr := s.revocations.UserInvalidated(ctx, claims.Subject, issuedAt)
	if rerr != nil {
		return nil, fmt.Errorf("%w: %v", ErrRevocationUnavailable, rerr)
	}
	if invalidated {
		return nil, ErrTokenRevoked
	}

	user, err := s.userRepo.GetByID(ctx, claims.Subject)
	if errors.Is(err, pgx.ErrNoRows) {
		// Hesap silinmiş ya da pasife alınmış: yenileme jetonu artık geçersizdir.
		return nil, ErrInvalidToken
	}
	if err != nil {
		return nil, err
	}
	// Siteden ayrılan kullanıcının jetonu eski siteyi taşımaya devam etmesin.
	if _, err := s.ensureActiveProperty(ctx, user); err != nil {
		return nil, err
	}

	roles, err := s.resolveRoles(ctx, user)
	if err != nil {
		return nil, err
	}

	return s.generateTokens(user, roles)
}

// GetUserByID ID ile kullanıcı getirir
func (s *AuthService) GetUserByID(ctx context.Context, userID string) (*models.UserResponse, error) {
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return nil, err
	}

	roles, err := s.resolveRoles(ctx, user)
	if err != nil {
		return nil, err
	}

	properties, _ := s.userRepo.GetUserProperties(ctx, user.ID)

	return &models.UserResponse{
		ID:                  user.ID,
		FirstName:           user.FirstName,
		LastName:            user.LastName,
		Phone:               user.Phone,
		Email:               user.Email,
		ActivePropertyID:    user.ActivePropertyID,
		Roles:               roles,
		Properties:          properties,
		KVKKConsentRequired: user.KVKKConsentAt == nil,
	}, nil
}

// SetKVKKConsent kullanıcının KVKK açık rıza onayını kaydeder
func (s *AuthService) SetKVKKConsent(ctx context.Context, userID string) error {
	return s.userRepo.SetKVKKConsent(ctx, userID)
}

// GetUserProperties kullanıcının sitelerini getirir
func (s *AuthService) GetUserProperties(ctx context.Context, userID string) ([]models.UserProperty, error) {
	return s.userRepo.GetUserProperties(ctx, userID)
}

// SetActiveProperty aktif siteyi değiştirir
func (s *AuthService) SetActiveProperty(ctx context.Context, userID, propertyID string) error {
	return s.userRepo.SetActiveProperty(ctx, userID, propertyID)
}

// validPropertyTypes geçerli site/taşınmaz türleri
var validPropertyTypes = map[string]bool{
	"SITE":      true,
	"APARTMENT": true,
	"BUILDING":  true,
}

// CreateProperty yeni site oluşturur; kurucu sitenin geçici yöneticisi olur (property_roles).
func (s *AuthService) CreateProperty(ctx context.Context, userID string, req models.CreatePropertyRequest) (*models.Property, error) {
	if !validPropertyTypes[req.Type] {
		req.Type = "SITE"
	}
	return s.userRepo.CreateProperty(ctx, userID, req)
}

// tokenIssuer — jetonların `iss` claim değeri. kong/kong.yml'deki consumer anahtarı
// ile birebir aynı olmak zorundadır.
const tokenIssuer = "siteeksen"

// resolveRoles kullanıcının AKTİF SİTEDEKİ rollerini çözer.
//
// GÜVENLİK (2026-09-13, todo 2.5): Roller AKTİF SİTEYE göre hesaplanır. Önceki
// sürüm `users.roles` kolonunu olduğu gibi jetona koyuyordu; bu kolon global
// olduğu için bir sitede MANAGER olan kişi TÜM sitelerde yönetici sayılıyordu
// (gap-analizi B22).
//
// Rol çözümlemesi başarısız olursa hata döner ve jeton ÜRETİLMEZ. Boş rol
// listesiyle devam etmek, yetki kontrollerini sessizce atlatan bir jeton
// üretmek demektir.
func (s *AuthService) resolveRoles(ctx context.Context, user *models.User) ([]string, error) {
	roles, err := s.userRepo.GetPropertyRoles(ctx, user.ID, user.ActivePropertyID)
	if err != nil {
		return nil, fmt.Errorf("kullanıcının site rolleri belirlenemedi: %w", err)
	}
	return roles, nil
}

// generateTokens verilen rol kümesiyle jeton çifti üretir.
//
// Roller BİLEREK dışarıdan alınır: çağıran taraf aynı kümeyi hem jetona hem de
// API yanıtına yazabilsin diye. Aksi halde yanıttaki roller ile jetondaki
// roller birbirinden ayrışabilirdi.
func (s *AuthService) generateTokens(user *models.User, roles []string) (*TokenPair, error) {
	now := time.Now()
	accessExpiry := now.Add(15 * time.Minute)
	refreshExpiry := now.Add(7 * 24 * time.Hour)

	// `iss` claim'i Kong'un jwt eklentisi için zorunludur: Kong, jetonun hangi
	// consumer'a ait olduğunu bu değerden (key_claim_name: iss) çözer.
	// kong/kong.yml içindeki consumer'ın jwt_secrets.key değeriyle aynı olmalıdır.
	accessClaims := jwt.MapClaims{
		"iss":         tokenIssuer,
		"sub":         user.ID,
		"property_id": user.ActivePropertyID,
		"roles":       roles,
		// iat milisaniye hassasiyetindedir (pkg/revocation.Precision): toplu
		// iptalden hemen sonra alınan jeton, iptalden ÖNCE üretilmiş sayılmasın.
		// exp tam saniye kalır; Kong'un jwt eklentisi ve istemciler tam sayı bekler.
		"iat": jwt.NewNumericDate(now),
		"exp": accessExpiry.Unix(),
		"jti": uuid.New().String(),
	}
	accessToken := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims)
	accessTokenString, err := accessToken.SignedString(s.jwtSecret)
	if err != nil {
		return nil, err
	}

	// Refresh token
	refreshClaims := jwt.RegisteredClaims{
		Issuer:    tokenIssuer,
		Subject:   user.ID,
		IssuedAt:  jwt.NewNumericDate(now),
		ExpiresAt: jwt.NewNumericDate(refreshExpiry),
		ID:        uuid.New().String(),
	}
	refreshToken := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims)
	refreshTokenString, err := refreshToken.SignedString(s.jwtSecret)
	if err != nil {
		return nil, err
	}

	return &TokenPair{
		AccessToken:  accessTokenString,
		RefreshToken: refreshTokenString,
		ExpiresIn:    int64(accessExpiry.Sub(now).Seconds()),
	}, nil
}

// WithRevocations, jeton iptal denetleyicisini bağlar ve servisi geri döner.
//
// Ayrı bir kurucu yerine zincirlenebilir ayarlayıcı kullanılır: mevcut
// NewAuthService çağrıları bozulmaz, bağlanmadığında da alan nil kalır ve
// bu durum kodda görünür olur.
func (s *AuthService) WithRevocations(c *revocation.Checker) *AuthService {
	s.revocations = c
	return s
}

// ensureActiveProperty, kullanıcının aktif sitesinin HÂLÂ bağlı olduğu bir site
// olmasını sağlar ve site listesini döner.
//
// DÜZELTME (2026-09-26): yeni açılan hesapta (yönetimin eklediği sakin) aktif
// site boştu; jeton site taşımıyor, sakin giriş yaptıktan sonra HER istekte
// 403 alıyordu. Aktif site boşsa ya da kullanıcı artık o siteye bağlı değilse
// (taşındı, görevi bitti) bağlı olduğu ilk site seçilir ve kaydedilir. Hiç
// bağlı site yoksa aktif site boşaltılır: eski sitenin kimliği jetonda kalmaz.
func (s *AuthService) ensureActiveProperty(ctx context.Context, user *models.User) ([]models.UserProperty, error) {
	properties, err := s.userRepo.GetUserProperties(ctx, user.ID)
	if err != nil {
		return nil, fmt.Errorf("siteler okunamadı: %w", err)
	}
	for _, p := range properties {
		if p.PropertyID == user.ActivePropertyID {
			return properties, nil
		}
	}
	if len(properties) == 0 {
		if user.ActivePropertyID != "" {
			if err := s.userRepo.ClearActiveProperty(ctx, user.ID); err != nil {
				return nil, err
			}
			user.ActivePropertyID = ""
		}
		return properties, nil
	}
	if err := s.userRepo.SetActiveProperty(ctx, user.ID, properties[0].PropertyID); err != nil {
		return nil, err
	}
	user.ActivePropertyID = properties[0].PropertyID
	return properties, nil
}
