// Package repository, site ayarları modülünün veritabanı işlemlerini içerir.
package repository

import "strings"

// Tür sabitleri.
const (
	TypeText = "TEXT"
	TypeInt  = "INT"
	TypeBool = "BOOL"
)

// Definition, tanınan bir ayar anahtarının tanımıdır.
//
// Ayarlar serbest metin anahtarlarla tutulmaz: kayıtlı olmayan bir anahtar
// reddedilir. Serbest bırakılsaydı her istemci kendi yazımını uydurur
// ("aidat_gunu", "aidatGunu", "AIDAT_GUN") ve hiçbiri okunmazdı.
type Definition struct {
	Key         string `json:"key"`
	Type        string `json:"type"`
	Description string `json:"description"`
	// Default, ayar hiç kaydedilmemişse geçerli olan değerdir.
	Default any `json:"default"`
	// Min/Max yalnızca INT türünde anlamlıdır.
	Min int `json:"min,omitempty"`
	Max int `json:"max,omitempty"`
}

// Definitions, tanınan tüm ayarlardır.
//
// BURADA MEVZUATA BAĞLI HİÇBİR DEĞER YOKTUR. Gecikme tazminatı oranı, nisaplar,
// vekâlet sınırları ve ısı paylaşım oranları `legal_parameters` tablosundadır
// (migration 012) ve site bazında keyfî olarak değiştirilemez.
var Definitions = []Definition{
	// --- İletişim ---
	{Key: "CONTACT_PHONE", Type: TypeText, Default: "",
		Description: "Yönetim iletişim telefonu (sakinlere gösterilir)"},
	{Key: "CONTACT_EMAIL", Type: TypeText, Default: "",
		Description: "Yönetim e-posta adresi"},
	{Key: "OFFICE_HOURS", Type: TypeText, Default: "09:00-18:00",
		Description: "Yönetim ofisi çalışma saatleri"},
	{Key: "EMERGENCY_PHONE", Type: TypeText, Default: "",
		Description: "Acil durum telefonu (7/24)"},

	// --- Aidat ve tahsilat işletmesi ---
	// DİKKAT: son ödeme GÜNÜ bir işletme tercihidir; gecikme tazminatı ORANI
	// değildir. Oran kanunla sabittir (KMK m.20/2) ve legal_parameters'tadır.
	{Key: "DUE_DAY_OF_MONTH", Type: TypeInt, Default: 5, Min: 1, Max: 28,
		Description: "Aidatın son ödeme günü (ayın kaçı). 28'den büyük olamaz: " +
			"şubat ayında karşılığı olmayan bir gün seçilemez."},
	{Key: "REMINDER_DAYS_BEFORE", Type: TypeInt, Default: 3, Min: 0, Max: 30,
		Description: "Son ödeme gününden kaç gün önce hatırlatma yapılacağı"},
	{Key: "IBAN_DISPLAY", Type: TypeText, Default: "",
		Description: "Sakinlere gösterilecek site hesabı IBAN'ı"},

	// --- Modül tercihleri ---
	{Key: "BULLETIN_REQUIRES_APPROVAL", Type: TypeBool, Default: true,
		Description: "Sakin ilanları yayımlanmadan önce yönetim onayından geçsin mi"},
	{Key: "VISITOR_REGISTRATION_REQUIRED", Type: TypeBool, Default: true,
		Description: "Ziyaretçi kaydı zorunlu mu"},
	{Key: "RESERVATION_ENABLED", Type: TypeBool, Default: true,
		Description: "Ortak alan rezervasyonu açık mı"},
	{Key: "BULLETIN_ENABLED", Type: TypeBool, Default: true,
		Description: "İlan panosu açık mı"},

	// --- Operasyon ---
	{Key: "PACKAGE_REMINDER_DAYS", Type: TypeInt, Default: 7, Min: 1, Max: 90,
		Description: "Teslim alınmayan kargo kaç gün sonra hatırlatılsın"},
	{Key: "PATROL_REQUIRED_PER_DAY", Type: TypeInt, Default: 0, Min: 0, Max: 24,
		Description: "Günde kaç güvenlik turu beklendiği (0 = takip edilmiyor)"},
	{Key: "QUIET_HOURS", Type: TypeText, Default: "22:00-08:00",
		Description: "Gürültüye kapalı saatler (yönetim planında belirlenir; " +
			"buradaki değer yalnızca sakinlere gösterim içindir)"},
}

// byKey, hızlı arama için.
var byKey = func() map[string]Definition {
	m := make(map[string]Definition, len(Definitions))
	for _, d := range Definitions {
		m[d.Key] = d
	}
	return m
}()

// Lookup, anahtarın tanımını döner.
func Lookup(key string) (Definition, bool) {
	d, ok := byKey[strings.ToUpper(strings.TrimSpace(key))]
	return d, ok
}

// legalPrefixes, mevzuat parametrelerinin ön ekleridir. Bu ön eklerle başlayan
// bir anahtar site ayarı olarak kaydedilemez; veritabanında da aynı kısıt vardır.
var legalPrefixes = []string{
	"LATE_FEE", "HEATING_", "GA_", "PROXY_", "MAJORITY_",
	"BUDGET_OBJECTION", "AUDIT_INTERVAL", "DECISION_BOOK",
}

// IsLegalKey, anahtarın mevzuat parametresi alanına girip girmediğini söyler.
func IsLegalKey(key string) bool {
	k := strings.ToUpper(strings.TrimSpace(key))
	for _, p := range legalPrefixes {
		if strings.HasPrefix(k, p) {
			return true
		}
	}
	return false
}
