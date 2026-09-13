package pii

import (
	"crypto/rand"
	"encoding/base64"
	"errors"
	"strings"
	"testing"
)

func testVault(t *testing.T) *Vault {
	t.Helper()
	key := make([]byte, 32)
	if _, err := rand.Read(key); err != nil {
		t.Fatal(err)
	}
	v, err := New(base64.StdEncoding.EncodeToString(key))
	if err != nil {
		t.Fatal(err)
	}
	return v
}

func TestFromEnvAnahtarsizAcilmaz(t *testing.T) {
	t.Setenv(EnvKey, "")
	if _, err := FromEnv(); !errors.Is(err, ErrNoKey) {
		t.Fatalf("anahtarsız kasa kuruldu: %v", err)
	}
	t.Setenv(EnvKey, "kisa-anahtar")
	if _, err := FromEnv(); !errors.Is(err, ErrNoKey) {
		t.Fatalf("geçersiz anahtar kabul edildi: %v", err)
	}
}

func TestSifrelemeGidisDonus(t *testing.T) {
	v := testVault(t)
	plain := "12345678901"
	ct, err := v.Encrypt(plain)
	if err != nil {
		t.Fatal(err)
	}
	if ct == plain {
		t.Fatal("şifreli metin düz metinle aynı")
	}
	if strings.Contains(ct, plain) {
		t.Fatal("şifreli metin düz metni içeriyor")
	}
	back, err := v.Decrypt(ct)
	if err != nil {
		t.Fatal(err)
	}
	if back != plain {
		t.Fatalf("çözülen değer farklı: %q", back)
	}
}

func TestAyniDegerFarkliSifreUretir(t *testing.T) {
	// AES-GCM her şifrelemede yeni nonce kullanır. Aynı TCKN'nin hep aynı
	// şifreli metni üretmesi, iki satırın aynı kişiye ait olduğunu ele verirdi.
	v := testVault(t)
	a, _ := v.Encrypt("12345678901")
	b, _ := v.Encrypt("12345678901")
	if a == b {
		t.Fatal("aynı değer aynı şifreli metni üretti (nonce tekrar kullanılıyor)")
	}
}

func TestBlindIndexAramaIcinKararli(t *testing.T) {
	v := testVault(t)
	// Aynı değerin farklı yazımları aynı arama anahtarını üretmeli.
	a := v.BlindIndex("TR33 0006 1005 1978 6457 8413 26")
	b := v.BlindIndex("tr330006100519786457841326")
	if a != b {
		t.Fatal("aynı IBAN'ın farklı yazımları farklı arama anahtarı üretti")
	}
	if a == "" {
		t.Fatal("arama anahtarı boş")
	}
	// Farklı değer farklı anahtar üretmeli.
	if v.BlindIndex("12345678901") == v.BlindIndex("12345678902") {
		t.Fatal("farklı değerler aynı arama anahtarını üretti")
	}
}

func TestBlindIndexAnahtaraBagli(t *testing.T) {
	// Anahtarı olmayan biri özetten değere gidememelidir: aynı değer, farklı
	// anahtarla farklı özet üretmelidir (düz SHA-256 bunu sağlamaz).
	v1 := testVault(t)
	v2 := testVault(t)
	if v1.BlindIndex("12345678901") == v2.BlindIndex("12345678901") {
		t.Fatal("arama anahtarı gizli anahtardan bağımsız (kaba kuvvetle çözülebilir)")
	}
}

func TestValidateTCKN(t *testing.T) {
	// Algoritmaya uygun, gerçek kişiye ait OLMAYAN sınama numaraları.
	valid := []string{"10000000146", "11111111110"}
	for _, s := range valid {
		if err := ValidateTCKN(s); err != nil {
			t.Errorf("geçerli TCKN reddedildi: %s (%v)", s, err)
		}
	}

	invalid := []string{
		"",             // boş
		"1234567890",   // 10 hane
		"123456789012", // 12 hane
		"01234567890",  // sıfırla başlıyor
		"12345678901",  // sağlama tutmuyor
		"1000000014a",  // harf
	}
	for _, s := range invalid {
		if err := ValidateTCKN(s); err == nil {
			t.Errorf("geçersiz TCKN kabul edildi: %q", s)
		}
	}
}

func TestValidateIBAN(t *testing.T) {
	valid := []string{
		"TR330006100519786457841326",
		"TR33 0006 1005 1978 6457 8413 26",
		"GB82WEST12345698765432",
	}
	for _, s := range valid {
		if err := ValidateIBAN(s); err != nil {
			t.Errorf("geçerli IBAN reddedildi: %s (%v)", s, err)
		}
	}

	invalid := []string{
		"",
		"TR33",
		"TR330006100519786457841327", // sağlama tutmuyor
		"TR3300061005197864578413",   // TR için yanlış uzunluk
		"TR33000610051978645784132!", // geçersiz karakter
	}
	for _, s := range invalid {
		if err := ValidateIBAN(s); err == nil {
			t.Errorf("geçersiz IBAN kabul edildi: %q", s)
		}
	}
}

func TestMaskeleme(t *testing.T) {
	if got := MaskTCKN("10000000146"); got != "100****0146" {
		t.Fatalf("TCKN maskesi: %s", got)
	}
	if strings.Contains(MaskTCKN("10000000146"), "00000") {
		t.Fatal("maske orta haneleri sızdırıyor")
	}
	if got := MaskIBAN("TR330006100519786457841326"); got != "TR33 **** 1326" {
		t.Fatalf("IBAN maskesi: %s", got)
	}
	if got := MaskTCKN("123"); got != "***" {
		t.Fatalf("kısa girdi maskesi: %s", got)
	}
}

func TestLast4(t *testing.T) {
	if got := Last4("TR330006100519786457841326"); got != "1326" {
		t.Fatalf("son dört hane: %s", got)
	}
	if got := Last4("12"); got != "12" {
		t.Fatalf("kısa girdi: %s", got)
	}
}

func TestBosDegerCozulunceBosKalir(t *testing.T) {
	v := testVault(t)
	got, err := v.Decrypt("")
	if err != nil || got != "" {
		t.Fatalf("boş şifreli metin: %q %v", got, err)
	}
}
