package authtoken

import (
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

const testSecret = "test-secret-at-least-32-characters-long"

func sign(t *testing.T, method jwt.SigningMethod, claims jwt.Claims, key interface{}) string {
	t.Helper()
	s, err := jwt.NewWithClaims(method, claims).SignedString(key)
	if err != nil {
		t.Fatalf("jeton imzalanamadı: %v", err)
	}
	return s
}

func validClaims() jwt.MapClaims {
	return jwt.MapClaims{
		"iss":         "siteeksen",
		"sub":         "11111111-1111-1111-1111-111111111111",
		"property_id": "22222222-2222-2222-2222-222222222222",
		"roles":       []string{"MANAGER"},
		"exp":         time.Now().Add(15 * time.Minute).Unix(),
		"iat":         time.Now().Unix(),
	}
}

func TestParse_GecerliJeton(t *testing.T) {
	t.Setenv("JWT_SECRET", testSecret)

	tok := sign(t, jwt.SigningMethodHS256, validClaims(), []byte(testSecret))
	claims, err := Parse(tok)
	if err != nil {
		t.Fatalf("geçerli jeton reddedildi: %v", err)
	}
	if got := claims.Subject(); got != "11111111-1111-1111-1111-111111111111" {
		t.Errorf("sub beklenen kullanıcı değil: %q", got)
	}
	if claims.PropertyID != "22222222-2222-2222-2222-222222222222" {
		t.Errorf("property_id okunamadı: %q", claims.PropertyID)
	}
	if !claims.HasRole("MANAGER") {
		t.Errorf("MANAGER rolü okunamadı: %v", claims.Roles)
	}
	if claims.HasRole("AUDITOR") {
		t.Errorf("olmayan rol doğru kabul edildi")
	}
}

// JWT_SECRET yoksa doğrulama yapılmamalı ve istek reddedilmeli (fail-closed).
// Aksi hâlde boş anahtarla imzalanmış bir jeton kabul edilir ve saldırgan
// istediği user_id/roles değerleriyle kimliğe bürünebilir.
func TestParse_AnahtarYokFailClosed(t *testing.T) {
	t.Setenv("JWT_SECRET", "")

	tok := sign(t, jwt.SigningMethodHS256, validClaims(), []byte(""))
	if _, err := Parse(tok); err != ErrNoSecret {
		t.Fatalf("anahtar yokken ErrNoSecret bekleniyordu, gelen: %v", err)
	}
}

// Algoritma karıştırma: `alg: none` ile imzasız jeton kabul edilmemeli.
func TestParse_AlgNoneReddedilir(t *testing.T) {
	t.Setenv("JWT_SECRET", testSecret)

	tok := sign(t, jwt.SigningMethodNone, validClaims(), jwt.UnsafeAllowNoneSignatureType)
	if _, err := Parse(tok); err != ErrInvalidToken {
		t.Fatalf("alg=none kabul edildi (err=%v)", err)
	}
}

func TestParse_YanlisAnahtarReddedilir(t *testing.T) {
	t.Setenv("JWT_SECRET", testSecret)

	tok := sign(t, jwt.SigningMethodHS256, validClaims(), []byte("baska-bir-anahtar-32-karakterden-uzun"))
	if _, err := Parse(tok); err != ErrInvalidToken {
		t.Fatalf("yanlış anahtarla imzalı jeton kabul edildi (err=%v)", err)
	}
}

func TestParse_SuresiDolmusReddedilir(t *testing.T) {
	t.Setenv("JWT_SECRET", testSecret)

	c := validClaims()
	c["exp"] = time.Now().Add(-time.Minute).Unix()
	tok := sign(t, jwt.SigningMethodHS256, c, []byte(testSecret))
	if _, err := Parse(tok); err != ErrInvalidToken {
		t.Fatalf("süresi dolmuş jeton kabul edildi (err=%v)", err)
	}
}

func TestExtractBearer(t *testing.T) {
	cases := []struct {
		in      string
		want    string
		wantErr bool
	}{
		{"Bearer abc.def.ghi", "abc.def.ghi", false},
		{"bearer abc.def.ghi", "abc.def.ghi", false},
		{"", "", true},
		{"abc.def.ghi", "", true},
		{"Basic abc", "", true},
		{"Bearer", "", true},
		{"Bearer ", "", true},
	}
	for _, tc := range cases {
		got, err := ExtractBearer(tc.in)
		if tc.wantErr && err == nil {
			t.Errorf("%q için hata bekleniyordu", tc.in)
			continue
		}
		if !tc.wantErr && got != tc.want {
			t.Errorf("%q → %q, beklenen %q", tc.in, got, tc.want)
		}
	}
}

// user_id claim'i yoksa `sub` kullanılmalı (identity-service `sub` yazıyor).
func TestSubject_SubGeriDusumu(t *testing.T) {
	c := &Claims{}
	c.RegisteredClaims.Subject = "abc"
	if c.Subject() != "abc" {
		t.Errorf("sub geri düşümü çalışmadı")
	}
	c.UserID = "xyz"
	if c.Subject() != "xyz" {
		t.Errorf("user_id önceliği çalışmadı")
	}
}
