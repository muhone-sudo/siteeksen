// Package rules, pazaryerinin veritabanından bağımsız kurallarıdır (birim testli): mesafe, hizmet alanı,
// ücret hesabı, iletişim bilgisi maskeleme, vergi numarası biçimi.
package rules

import (
	"math"
	"regexp"
	"sort"
	"strings"
)

// DistanceMeters, iki koordinat arasındaki büyük daire uzaklığıdır (Haversine, metre).
func DistanceMeters(lat1, lng1, lat2, lng2 float64) float64 {
	const r = 6371000.0
	rad := math.Pi / 180
	dLat := (lat2 - lat1) * rad
	dLng := (lng2 - lng1) * rad
	a := math.Sin(dLat/2)*math.Sin(dLat/2) + math.Cos(lat1*rad)*math.Cos(lat2*rad)*math.Sin(dLng/2)*math.Sin(dLng/2)
	return 2 * r * math.Asin(math.Min(1, math.Sqrt(a)))
}

// Area, işletmenin hizmet alanıdır.
type Area struct {
	Kind     string // KM, CITY, COUNTRY
	RadiusKm int
	Lat, Lng float64
	City     string
	District string
}

// Site, talebin geldiği yerdir (koordinat yoksa ilçe kullanılır).
type Site struct {
	Lat, Lng       *float64
	City, District string
}

// Covers, işletmenin hizmet alanının siteyi kapsayıp kapsamadığını ve (biliniyorsa) uzaklığı döner.
//
//	COUNTRY: her yer.  CITY: aynı il.  KM: site koordinatı varsa yarıçap içi; yoksa aynı il + aynı ilçe (yedek).
func Covers(a Area, s Site) (bool, *int) {
	var dist *int
	if s.Lat != nil && s.Lng != nil {
		d := int(math.Round(DistanceMeters(a.Lat, a.Lng, *s.Lat, *s.Lng)))
		dist = &d
	}
	switch a.Kind {
	case "COUNTRY":
		return true, dist
	case "CITY":
		return SamePlace(a.City, s.City), dist
	case "KM":
		if dist != nil {
			return *dist <= a.RadiusKm*1000, dist
		}
		return SamePlace(a.City, s.City) && SamePlace(a.District, s.District), nil
	}
	return false, dist
}

// Candidate, talebin kategorisinde yayında olan, hesabı onaylı bir işletmedir.
type Candidate struct {
	BusinessID, AccountID string
	Area                  Area
	Priority              bool
}

// Dispatch, talebin gideceği tedarikçi hesabıdır: hesabın kapsayan işletmelerinden en yakını.
type Dispatch struct {
	BusinessID, AccountID string
	DistanceM             *int
	Priority              bool
	local                 bool
}

// Match, talebin gönderileceği hesapları seçer (FAZ M6, K9/K16): hizmet alanı siteyi kapsamalı, çatışan hesap
// (sitede yönetim görevi olan kişinin hesabı, yalnız yönetim taleplerinde verilir) dışarıda kalır, doğrudan talepte
// (target) yalnız o işletme. Bir hesap birden çok şubesiyle uygunsa tek kez, en yakın şubesiyle gelir; uzaklık
// bilinmiyorsa (site koordinatsız) sitenin ilçesindeki şube, o da yoksa ilk uygun şube. Sonuç uzaklığa göre sıralıdır (bilinmeyen en sonda).
func Match(cands []Candidate, site Site, excluded map[string]bool, target string) []Dispatch {
	best := map[string]*Dispatch{}
	for _, c := range cands {
		if excluded[c.AccountID] || (target != "" && c.BusinessID != target) {
			continue
		}
		ok, dist := Covers(c.Area, site)
		if !ok {
			continue
		}
		cur := best[c.AccountID]
		local := dist == nil && SamePlace(c.Area.District, site.District) && SamePlace(c.Area.City, site.City)
		closer := cur == nil || (dist != nil && (cur.DistanceM == nil || *dist < *cur.DistanceM)) || (local && !cur.local)
		if closer {
			best[c.AccountID] = &Dispatch{BusinessID: c.BusinessID, AccountID: c.AccountID, DistanceM: dist, Priority: c.Priority, local: local}
		}
	}
	out := make([]Dispatch, 0, len(best))
	for _, d := range best {
		out = append(out, *d)
	}
	sort.Slice(out, func(i, j int) bool {
		a, b := out[i].DistanceM, out[j].DistanceM
		if (a == nil) != (b == nil) {
			return a != nil
		}
		if a != nil && *a != *b {
			return *a < *b
		}
		return out[i].AccountID < out[j].AccountID
	})
	return out
}

// SamePlace, il/ilçe adlarını Türkçe büyük-küçük harf ve boşluk farkı gözetmeden karşılaştırır.
func SamePlace(a, b string) bool {
	return a != "" && placeKey(a) == placeKey(b)
}

func placeKey(s string) string {
	s = strings.TrimSpace(s)
	s = strings.NewReplacer("I", "ı", "İ", "i").Replace(s)
	return strings.Join(strings.Fields(strings.ToLower(s)), " ")
}

// RequestFee, kabul ücretidir: kategori ücreti, paket indirimiyle (kuruş, aşağı yuvarlanmaz — indirim tam kuruşa yuvarlanır).
func RequestFee(categoryFeeKurus int64, discountPct int) int64 {
	if discountPct <= 0 {
		return categoryFeeKurus
	}
	if discountPct >= 100 {
		return 0
	}
	// Tam sayı aritmetiği: (ücret × (100 − indirim) + 50) / 100 → en yakın kuruşa.
	return (categoryFeeKurus*int64(100-discountPct) + 50) / 100
}

var (
	// Telefon: 10–13 rakam; araya boşluk, nokta, tire, parantez girebilir (+90 / 0 öneki dahil). Eşleşme rakamla biter.
	phonePattern = regexp.MustCompile(`\+?\d(?:[\s().-]*\d){9,12}`)
	emailPattern = regexp.MustCompile(`[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}`)
)

// MaskedNotice, gizlenen iletişim bilgisinin yerine yazılan metindir.
const MaskedNotice = "[iletişim bilgisi gizlendi]"

// MaskContacts, serbest metindeki telefon ve e-posta kalıplarını gizler (talep açıklaması, hizmet tanımı).
// Amaç, iletişimin ücret ödenmeden metin içinde paylaşılmasını önlemektir.
func MaskContacts(s string) (string, bool) {
	out := emailPattern.ReplaceAllString(s, MaskedNotice)
	out = phonePattern.ReplaceAllStringFunc(out, func(m string) string {
		digits := 0
		for _, r := range m {
			if r >= '0' && r <= '9' {
				digits++
			}
		}
		if digits < 10 {
			return m
		}
		return MaskedNotice
	})
	return out, out != s
}

// ValidTaxNumber, vergi numarası (10 hane) ya da TCKN (11 hane) biçimini denetler.
func ValidTaxNumber(s string) bool {
	if len(s) != 10 && len(s) != 11 {
		return false
	}
	for _, r := range s {
		if r < '0' || r > '9' {
			return false
		}
	}
	return true
}
