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
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"os"
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
)

// EnvKey, anahtarın okunduğu ortam değişkeni.
const EnvKey = "PII_ENCRYPTION_KEY"

// Vault, kişisel verileri şifreler ve çözer.
type Vault struct {
	enc *encryption.Service
	key []byte
}

// FromEnv, anahtarı ortamdan okur.
//
// Anahtar yoksa ya da geçersizse HATA döner. Çağıran servis bu hatada
// AÇILMAMALIDIR: kişisel veriyi şifresiz yazmaya devam etmek, korumanın
// yapılandırma hatasıyla sessizce kapanması demektir.
func FromEnv() (*Vault, error) {
	raw := strings.TrimSpace(os.Getenv(EnvKey))
	if raw == "" {
		return nil, ErrNoKey
	}
	return New(raw)
}

// New, base64 kodlu 32 baytlık anahtarla kasa kurar.
func New(keyBase64 string) (*Vault, error) {
	enc, err := encryption.NewService(keyBase64)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrNoKey, err)
	}
	key, err := base64.StdEncoding.DecodeString(keyBase64)
	if err != nil {
		return nil, ErrNoKey
	}
	return &Vault{enc: enc, key: key}, nil
}

// Encrypt, düz metni şifreler.
func (v *Vault) Encrypt(plain string) (string, error) {
	if v == nil {
		return "", ErrNoKey
	}
	return v.enc.Encrypt(plain)
}

// Decrypt, şifreli metni çözer.
func (v *Vault) Decrypt(cipherText string) (string, error) {
	if v == nil {
		return "", ErrNoKey
	}
	if strings.TrimSpace(cipherText) == "" {
		return "", nil
	}
	return v.enc.Decrypt(cipherText)
}

// BlindIndex, şifreli veri üzerinde EŞİTLİK ARAMASI yapabilmek için üretilen
// arama anahtarıdır.
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
	normalized := Normalize(value)
	if normalized == "" {
		return ""
	}
	mac := hmac.New(sha256.New, v.key)
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
