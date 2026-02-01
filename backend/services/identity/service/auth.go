package service

import (
	"context"
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
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
	if err != nil {
		return nil, nil, errors.New("kullanıcı bulunamadı")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)); err != nil {
		return nil, nil, errors.New("geçersiz şifre")
	}

	tokens, err := s.generateTokens(user)
	if err != nil {
		return nil, nil, err
	}

	// Kullanıcının sitelerini al
	properties, _ := s.userRepo.GetUserProperties(ctx, user.ID)

	response := &models.UserResponse{
		ID:         user.ID,
		FirstName:  user.FirstName,
		LastName:   user.LastName,
		Phone:      user.Phone,
		Email:      user.Email,
		Properties: properties,
	}

	return tokens, response, nil
}

// RefreshToken token yeniler
func (s *AuthService) RefreshToken(ctx context.Context, refreshToken string) (*TokenPair, error) {
	claims := &jwt.RegisteredClaims{}
	token, err := jwt.ParseWithClaims(refreshToken, claims, func(t *jwt.Token) (interface{}, error) {
		return s.jwtSecret, nil
	})

	if err != nil || !token.Valid {
		return nil, errors.New("geçersiz refresh token")
	}

	user, err := s.userRepo.GetByID(ctx, claims.Subject)
	if err != nil {
		return nil, err
	}

	return s.generateTokens(user)
}

// GetUserByID ID ile kullanıcı getirir
func (s *AuthService) GetUserByID(ctx context.Context, userID string) (*models.UserResponse, error) {
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return nil, err
	}

	properties, _ := s.userRepo.GetUserProperties(ctx, user.ID)

	return &models.UserResponse{
		ID:         user.ID,
		FirstName:  user.FirstName,
		LastName:   user.LastName,
		Phone:      user.Phone,
		Email:      user.Email,
		Properties: properties,
	}, nil
}

// GetUserProperties kullanıcının sitelerini getirir
func (s *AuthService) GetUserProperties(ctx context.Context, userID string) ([]models.UserProperty, error) {
	return s.userRepo.GetUserProperties(ctx, userID)
}

// SetActiveProperty aktif siteyi değiştirir
func (s *AuthService) SetActiveProperty(ctx context.Context, userID, propertyID string) error {
	return s.userRepo.SetActiveProperty(ctx, userID, propertyID)
}

func (s *AuthService) generateTokens(user *models.User) (*TokenPair, error) {
	now := time.Now()
	accessExpiry := now.Add(15 * time.Minute)
	refreshExpiry := now.Add(7 * 24 * time.Hour)

	// Access token
	accessClaims := jwt.MapClaims{
		"sub":         user.ID,
		"property_id": user.ActivePropertyID,
		"roles":       user.Roles,
		"iat":         now.Unix(),
		"exp":         accessExpiry.Unix(),
		"jti":         uuid.New().String(),
	}
	accessToken := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims)
	accessTokenString, err := accessToken.SignedString(s.jwtSecret)
	if err != nil {
		return nil, err
	}

	// Refresh token
	refreshClaims := jwt.RegisteredClaims{
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
