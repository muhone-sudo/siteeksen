// Package pii, kişisel verilerin (TCKN, IBAN) şifreli saklanmasını sağlar.
//
// Neden var (FAZ 2.8): TCKN ve IBAN veritabanında DÜZ METİN duruyordu.
// `pkg/encryption` yazılmış ama hiçbir yerden import edilmiyordu. Tek bir yedek
// dosyasının ya da veritabanı sızıntısının bedeli, sitedeki herkesin kimlik
// numarası ve çalışanların banka hesabıdır.
//
// Hukuki dayanak:
//
//	6698 s. KVKK m.12/1: veri sorumlusu, kişisel verilerin hukuka aykırı
//	erişimini önlemek için UYGUN GÜVENLİK DÜZEYİNİ sağlamakla yükümlüdür.
//	KVKK Kurumu'nun "Kişisel Veri Güvenliği Rehberi" özel önem taşıyan
//	verilerin şifreli saklanmasını açıkça önerir.
//	5490 s. Nüfus Hizmetleri Kanunu m.45: TCKN'nin paylaşımı ve kullanımı sınırlıdır.
//
// Tasarım kararları:
//
//  1. ANAHTAR ZORUNLUDUR. Anahtar yoksa `FromEnv` hata döner ve kişisel veri
//     işleyen servis AÇILMAZ. Şifresiz çalışmaya devam etmek, korumayı
//     "yapılandırma unutulunca" sessizce kapatmak olurdu.
//
//  2. ARAMA İÇİN HMAC, DÜZ SHA-256 DEĞİL. TCKN 11 hanedir; olası değer uzayı
//     yaklaşık 10^10'dur ve düz bir SHA-256 özeti sıradan bir bilgisayarda
//     kaba kuvvetle çözülür. Bu yüzden arama anahtarı (blind index) gizli
//     anahtarla HMAC-SHA256 olarak üretilir: anahtarı olmayan, özetten
//     TCKN'ye geri gidemez.
//
//  3. GÖSTERİM İÇİN SON HANELER AYRI SAKLANIR. "IBAN'ın son 4 hanesi"
//     listelemede gerekir; bunun için her satırı çözmek hem yavaş hem de
//     gereksiz bir çözme işlemidir (her çözme, veriyi belleğe düz metin
//     olarak getirir).
package pii

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/hkdf"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"os"
	"regexp"
	"sort"
	"strings"

	"github.com/siteeksen/backend/pkg/encryption"
)

var (
	// ErrNoKey, şifreleme anahtarı tanımlı değilse döner.
	ErrNoKey = errors.New("kişisel veri şifreleme anahtarı (PII_ENCRYPTION_KEY) tanımlı değil")
	// ErrInvalidTCKN, TCKN algoritmik doğrulamadan geçmezse döner.
	ErrInvalidTCKN = errors.New("geçersiz T.C. kimlik numarası")
	// ErrInvalidIBAN, IBAN doğrulamadan geçmezse döner.
	ErrInvalidIBAN = errors.New("geçersiz IBAN")
	// ErrUnknownKey, şifreli metnin anahtarı halkada yoksa döner.
	ErrUnknownKey = errors.New("şifreleme anahtarı halkada yok")
)

// Ortam değişkenleri.
//
// ANAHTAR DÖNDÜRME (2026-09-27): önceden tek anahtar vardı ve şifreli metin
// hangi anahtarla yazıldığını taşımıyordu; anahtar değiştirilirse bütün kayıtlar
// okunamaz olurdu. Artık:
//   - PII_ENCRYPTION_KEY      : BİRİNCİL anahtar (yeni yazımlar bununla).
//   - PII_ENCRYPTION_KEY_ID   : birincil anahtarın kimliği (varsayılan "k1").
//   - PII_ENCRYPTION_PREVIOUS_KEYS: "k0:<base64>,..." — YALNIZCA ÇÖZMEK için.
//
// Döndürme: yeni anahtar birincil yapılır, eskisi PREVIOUS'a taşınır, servisler
// yeniden başlatılır, `go run ./cmd/rotate-pii` bütün kayıtları yeni anahtara
// geçirir; ardından eski anahtar PREVIOUS'tan çıkarılır (docs/runbook-anahtar-dondurme.md).
const (
	EnvKey          = "PII_ENCRYPTION_KEY"
	EnvKeyID        = "PII_ENCRYPTION_KEY_ID"
	EnvPreviousKeys = "PII_ENCRYPTION_PREVIOUS_KEYS"
	DefaultKeyID    = "k1"

	// keySep, şifreli metinde anahtar kimliğini ayırır. Base64 alfabesinde
	// olmadığı için eski (kimliksiz) biçimle karışmaz.
	keySep = "$"
)

var keyIDPattern = regexp.MustCompile(`^[a-z0-9][a-z0-9_-]{0,15}$`)

// keyMaterial, tek bir ana anahtardan TÜRETİLEN alt anahtarlardır.
//
// Anahtar ayrımı: önceden aynı 32 bayt hem AES-GCM hem HMAC anahtarı olarak
// kullanılıyordu. Yeni biçimde ikisi HKDF ile ayrı türetilir; eski biçimi
// okuyabilmek için ham anahtar da tutulur.
type keyMaterial struct {
	id        string
	encKey    []byte              // HKDF("pii-enc")
	macKey    []byte              // HKDF("pii-blind-index")
	legacyEnc *encryption.Service // kimliksiz eski şifreli metinler
	legacyMac []byte              // eski arama anahtarları (ham anahtarla HMAC)
}

func newKeyMaterial(id, keyBase64 string) (*keyMaterial, error) {
	if !keyIDPattern.MatchString(id) {
		return nil, fmt.Errorf("%w: geçersiz anahtar kimliği %q (küçük harf/rakam, en çok 16)", ErrNoKey, id)
	}
	legacy, err := encryption.NewService(keyBase64)
	if err != nil {
		return nil, fmt.Errorf("%w: %s: %v", ErrNoKey, id, err)
	}
	raw, err := base64.StdEncoding.DecodeString(keyBase64)
	if err != nil {
		return nil, ErrNoKey
	}
	encKey, err := hkdf.Key(sha256.New, raw, nil, "siteeksen/pii-enc/v2", 32)
	if err != nil {
		return nil, err
	}
	macKey, err := hkdf.Key(sha256.New, raw, nil, "siteeksen/pii-blind-index/v2", 32)
	if err != nil {
		return nil, err
	}
	return &keyMaterial{id: id, encKey: encKey, macKey: macKey, legacyEnc: legacy, legacyMac: raw}, nil
}

// Vault, kişisel verileri şifreler ve çözer.
type Vault struct {
	primary *keyMaterial
	keys    []*keyMaterial // birincil önce
}

// FromEnv, anahtarları ortamdan okur.
//
// Anahtar yoksa ya da geçersizse HATA döner. Çağıran servis bu hatada
// AÇILMAMALIDIR: kişisel veriyi şifresiz yazmaya devam etmek, korumanın
// yapılandırma hatasıyla sessizce kapanması demektir.
func FromEnv() (*Vault, error) {
	raw := strings.TrimSpace(os.Getenv(EnvKey))
	if raw == "" {
		return nil, ErrNoKey
	}
	id := strings.TrimSpace(os.Getenv(EnvKeyID))
	if id == "" {
		id = DefaultKeyID
	}
	previous := map[string]string{}
	for _, part := range strings.Split(os.Getenv(EnvPreviousKeys), ",") {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}
		pid, key, ok := strings.Cut(part, ":")
		if !ok {
			return nil, fmt.Errorf("%w: %s girdisi 'kimlik:base64' biçiminde olmalı", ErrNoKey, EnvPreviousKeys)
		}
		previous[strings.TrimSpace(pid)] = strings.TrimSpace(key)
	}
	return NewKeyring(id, raw, previous)
}

// New, tek (birincil) anahtarla kasa kurar; kimliği DefaultKeyID'dir.
func New(keyBase64 string) (*Vault, error) {
	return NewKeyring(DefaultKeyID, keyBase64, nil)
}

// NewKeyring, birincil anahtar ve yalnızca çözmek için eski anahtarlarla kasa kurar.
func NewKeyring(primaryID, primaryKey string, previous map[string]string) (*Vault, error) {
	p, err := newKeyMaterial(primaryID, primaryKey)
	if err != nil {
		return nil, err
	}
	v := &Vault{primary: p, keys: []*keyMaterial{p}}
	ids := make([]string, 0, len(previous))
	for id := range previous {
		ids = append(ids, id)
	}
	sort.Strings(ids)
	for _, id := range ids {
		if id == primaryID {
			return nil, fmt.Errorf("%w: %q hem birincil hem eski anahtar", ErrNoKey, id)
		}
		k, err := newKeyMaterial(id, previous[id])
		if err != nil {
			return nil, err
		}
		v.keys = append(v.keys, k)
	}
	return v, nil
}

// PrimaryKeyID, yeni yazımlarda kullanılan anahtarın kimliğidir.
func (v *Vault) PrimaryKeyID() string {
	if v == nil {
		return ""
	}
	return v.primary.id
}

// Encrypt, düz metni birincil anahtarla şifreler: "<kimlik>$<base64(nonce|şifreli)>".
// Anahtar kimliği ek doğrulanmış veri (AAD) olarak bağlanır: kimliği başka
// anahtarınkiyle değiştirilen metin çözülmez.
func (v *Vault) Encrypt(plain string) (string, error) {
	if v == nil {
		return "", ErrNoKey
	}
	gcm, err := newGCM(v.primary.encKey)
	if err != nil {
		return "", err
	}
	nonce := make([]byte, gcm.NonceSize())
	if _, err := rand.Read(nonce); err != nil {
		return "", err
	}
	sealed := gcm.Seal(nonce, nonce, []byte(plain), []byte(v.primary.id))
	return v.primary.id + keySep + base64.StdEncoding.EncodeToString(sealed), nil
}

// Decrypt, şifreli metni çözer. Kimlikli metin yalnızca o anahtarla; eski
// (kimliksiz) metin halkadaki anahtarlar sırayla denenerek çözülür — GCM
// doğrulaması yanlış anahtarda kesin olarak başarısız olur.
func (v *Vault) Decrypt(cipherText string) (string, error) {
	if v == nil {
		return "", ErrNoKey
	}
	cipherText = strings.TrimSpace(cipherText)
	if cipherText == "" {
		return "", nil
	}
	if id, body, ok := strings.Cut(cipherText, keySep); ok {
		k := v.key(id)
		if k == nil {
			return "", fmt.Errorf("%w: veri %q anahtarıyla şifrelenmiş ama bu anahtar tanımlı değil (%s)",
				ErrUnknownKey, id, EnvPreviousKeys)
		}
		data, err := base64.StdEncoding.DecodeString(body)
		if err != nil {
			return "", err
		}
		gcm, err := newGCM(k.encKey)
		if err != nil {
			return "", err
		}
		if len(data) < gcm.NonceSize() {
			return "", errors.New("şifreli veri çok kısa")
		}
		plain, err := gcm.Open(nil, data[:gcm.NonceSize()], data[gcm.NonceSize():], []byte(id))
		if err != nil {
			return "", fmt.Errorf("şifreli veri çözülemedi (%s): %w", id, err)
		}
		return string(plain), nil
	}
	var lastErr error
	for _, k := range v.keys {
		plain, err := k.legacyEnc.Decrypt(cipherText)
		if err == nil {
			return plain, nil
		}
		lastErr = err
	}
	return "", fmt.Errorf("eski biçimli şifreli veri halkadaki hiçbir anahtarla çözülemedi: %w", lastErr)
}

// NeedsRotation, şifreli metnin birincil anahtarla YENİ biçimde yazılmadığını söyler.
func (v *Vault) NeedsRotation(cipherText string) bool {
	cipherText = strings.TrimSpace(cipherText)
	return cipherText != "" && !strings.HasPrefix(cipherText, v.primary.id+keySep)
}

func (v *Vault) key(id string) *keyMaterial {
	for _, k := range v.keys {
		if k.id == id {
			return k
		}
	}
	return nil
}

func newGCM(key []byte) (cipher.AEAD, error) {
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}
	return cipher.NewGCM(block)
}

// BlindIndex, şifreli veri üzerinde EŞİTLİK ARAMASI yapabilmek için üretilen
// arama anahtarıdır (birincil anahtarın HMAC alt anahtarıyla).
//
// HMAC-SHA256 kullanılır, düz SHA-256 değil: TCKN'nin değer uzayı küçüktür ve
// anahtarsız bir özet kaba kuvvetle geri çevrilebilir. HMAC'te anahtarı
// bilmeyen, özetten veriye gidemez.
//
// Girdi normalize edilir (boşluk ve ayraçlar atılır, büyük harfe çevrilir):
// aynı IBAN'ın "TR12 3456" ve "tr123456" yazımları aynı anahtarı üretmelidir.
func (v *Vault) BlindIndex(value string) string {
	if v == nil {
		return ""
	}
	return blindIndex(v.primary.macKey, value)
}

// BlindIndexCandidates, değerin halkadaki BÜTÜN anahtarlarla (eski biçim dahil)
// üretilebilecek arama anahtarlarıdır.
//
// Döndürme sürerken bazı kayıtların arama anahtarı eski anahtarla üretilmiştir;
// yalnızca birincil anahtarla aramak, aynı TCKN'li ikinci kaydı "yok" sanıp
// yinelenen kayda izin verirdi. Eşitlik denetimleri bu kümeyle yapılmalıdır.
func (v *Vault) BlindIndexCandidates(value string) []string {
	if v == nil || Normalize(value) == "" {
		return nil
	}
	out := make([]string, 0, 2*len(v.keys))
	for _, k := range v.keys {
		out = append(out, blindIndex(k.macKey, value), blindIndex(k.legacyMac, value))
	}
	return out
}

func blindIndex(key []byte, value string) string {
	normalized := Normalize(value)
	if normalized == "" {
		return ""
	}
	mac := hmac.New(sha256.New, key)
	mac.Write([]byte(normalized))
	return hex.EncodeToString(mac.Sum(nil))
}

// Normalize, karşılaştırma ve arama için değeri sadeleştirir.
func Normalize(value string) string {
	var b strings.Builder
	for _, r := range strings.ToUpper(value) {
		if (r >= '0' && r <= '9') || (r >= 'A' && r <= 'Z') {
			b.WriteRune(r)
		}
	}
	return b.String()
}

// Last4, gösterim için son dört haneyi döner.
func Last4(value string) string {
	n := Normalize(value)
	if len(n) <= 4 {
		return n
	}
	return n[len(n)-4:]
}

// MaskTCKN, TCKN'yi gösterim için maskeler: 123****8901
func MaskTCKN(tckn string) string {
	n := Normalize(tckn)
	if len(n) != 11 {
		return "***"
	}
	return n[:3] + "****" + n[7:]
}

// MaskIBAN, IBAN'ı gösterim için maskeler: TR12 **** 3456
func MaskIBAN(iban string) string {
	n := Normalize(iban)
	if len(n) < 8 {
		return "***"
	}
	return n[:4] + " **** " + n[len(n)-4:]
}

// ValidateTCKN, T.C. kimlik numarasını ALGORİTMİK olarak doğrular.
//
// Kural (Nüfus ve Vatandaşlık İşleri'nin yayımladığı, kamuya açık algoritma):
//   - 11 hane, ilk hane 0 olamaz
//   - (1,3,5,7,9. hanelerin toplamı × 7 − 2,4,6,8. hanelerin toplamı) mod 10 = 10. hane
//   - İlk 10 hanenin toplamı mod 10 = 11. hane
//
// Bu doğrulama, yanlış yazılmış bir numaranın şifrelenip saklanmasını önler:
// şifreli bir alandaki hatayı sonradan gözle görmek mümkün değildir.
func ValidateTCKN(tckn string) error {
	n := Normalize(tckn)
	if len(n) != 11 || n[0] == '0' {
		return ErrInvalidTCKN
	}
	d := make([]int, 11)
	for i, r := range n {
		if r < '0' || r > '9' {
			return ErrInvalidTCKN
		}
		d[i] = int(r - '0')
	}

	odd := d[0] + d[2] + d[4] + d[6] + d[8]
	even := d[1] + d[3] + d[5] + d[7]
	check10 := ((odd * 7) - even) % 10
	if check10 < 0 {
		check10 += 10
	}
	if check10 != d[9] {
		return ErrInvalidTCKN
	}

	sum := 0
	for i := 0; i < 10; i++ {
		sum += d[i]
	}
	if sum%10 != d[10] {
		return ErrInvalidTCKN
	}
	return nil
}

// ValidateIBAN, IBAN'ı ISO 13616 mod-97 kuralıyla doğrular.
//
// Türkiye IBAN'ı 26 karakterdir ve "TR" ile başlar. Yanlış yazılmış bir IBAN,
// maaşın başkasının hesabına gitmesi demektir; şifreli alanda bu hata
// sonradan gözle bulunamaz.
func ValidateIBAN(iban string) error {
	n := Normalize(iban)
	if len(n) < 15 || len(n) > 34 {
		return ErrInvalidIBAN
	}
	if strings.HasPrefix(n, "TR") && len(n) != 26 {
		return ErrInvalidIBAN
	}

	// İlk dört karakter sona taşınır.
	rearranged := n[4:] + n[:4]

	// Harfler sayıya çevrilir (A=10 … Z=35) ve mod 97 alınır.
	// Sayı çok büyük olacağı için parça parça mod alınır.
	remainder := 0
	for _, r := range rearranged {
		var part string
		switch {
		case r >= '0' && r <= '9':
			part = string(r)
		case r >= 'A' && r <= 'Z':
			part = fmt.Sprintf("%d", int(r-'A')+10)
		default:
			return ErrInvalidIBAN
		}
		for _, c := range part {
			remainder = (remainder*10 + int(c-'0')) % 97
		}
	}
	if remainder != 1 {
		return ErrInvalidIBAN
	}
	return nil
}
