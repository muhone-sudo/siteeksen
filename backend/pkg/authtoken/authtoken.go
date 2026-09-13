// Package authtoken, JWT erişim jetonlarının tek noktadan doğrulanmasını sağlar.
//
// NEDEN VAR:
// Doğrulama mantığı daha önce yalnızca gin middleware'i içindeydi; net/http tabanlı
// gateway bu mantığa erişemediği için HİÇBİR kimlik doğrulaması yapmıyordu. Sonuç:
// maaş, TCKN, IBAN ve API anahtarları gateway üzerinden token'sız erişilebiliyordu.
// Bu paket doğrulamayı çatıdan bağımsız hale getirir; gin middleware'i de bunu kullanır.
package authtoken

import (
	"errors"
	"os"
	"strings"

	"github.com/golang-jwt/jwt/v5"
)

// SigningMethods — imza algoritması allowlist'i.
// Belirtilmezse kütüphane token'ın kendi `alg` başlığına güvenir; bu, algoritma
// karıştırma (algorithm confusion) saldırılarına kapı açar.
var SigningMethods = []string{"HS256"}

var (
	// ErrNoSecret, JWT_SECRET ortam değişkeni tanımlı olmadığında döner.
	// Bu durumda istek REDDEDİLİR (fail-closed); boş anahtarla doğrulama yapılmaz.
	ErrNoSecret = errors.New("JWT_SECRET tanımlı değil")
	// ErrMalformedHeader, Authorization başlığı "Bearer <token>" biçiminde değilse döner.
	ErrMalformedHeader = errors.New("geçersiz Authorization formatı")
	// ErrInvalidToken, imza/son kullanma doğrulaması başarısız olduğunda döner.
	ErrInvalidToken = errors.New("geçersiz veya süresi dolmuş token")
)

// Claims, SiteEksen erişim jetonunun taşıdığı bilgileri temsil eder.
type Claims struct {
	UserID     string   `json:"user_id"`
	PropertyID string   `json:"property_id"`
	Roles      []string `json:"roles"`
	jwt.RegisteredClaims
}

// Subject, user_id claim'i boşsa standart `sub` claim'ine düşer.
func (c *Claims) Subject() string {
	if c.UserID != "" {
		return c.UserID
	}
	return c.RegisteredClaims.Subject
}

// HasRole, jetonun verilen rollerden en az birini taşıyıp taşımadığını söyler.
func (c *Claims) HasRole(roles ...string) bool {
	for _, want := range roles {
		for _, have := range c.Roles {
			if have == want {
				return true
			}
		}
	}
	return false
}

// Secret, imzalama anahtarını ortamdan okur. Yoksa ErrNoSecret döner.
func Secret() (string, error) {
	s := os.Getenv("JWT_SECRET")
	if s == "" {
		return "", ErrNoSecret
	}
	return s, nil
}

// ExtractBearer, "Bearer <token>" başlığından jetonu ayıklar.
func ExtractBearer(authHeader string) (string, error) {
	if authHeader == "" {
		return "", ErrMalformedHeader
	}
	parts := strings.Fields(authHeader)
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") || parts[1] == "" {
		return "", ErrMalformedHeader
	}
	return parts[1], nil
}

// Parse, jeton dizesini doğrular ve claim'leri döndürür.
func Parse(tokenString string) (*Claims, error) {
	secret, err := Secret()
	if err != nil {
		return nil, err
	}

	claims := &Claims{}
	token, err := jwt.ParseWithClaims(
		tokenString,
		claims,
		func(*jwt.Token) (interface{}, error) { return []byte(secret), nil },
		jwt.WithValidMethods(SigningMethods),
	)
	if err != nil || !token.Valid {
		return nil, ErrInvalidToken
	}
	return claims, nil
}

// ParseAuthHeader, Authorization başlığını doğrudan doğrular.
func ParseAuthHeader(authHeader string) (*Claims, error) {
	tokenString, err := ExtractBearer(authHeader)
	if err != nil {
		return nil, err
	}
	return Parse(tokenString)
}
