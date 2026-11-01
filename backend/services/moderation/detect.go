package main

import (
	"regexp"
	"strings"
)

var (
	// Telefon: 10–13 rakam; araya boşluk, nokta, tire, parantez, eğik çizgi girebilir (+90 / 0 öneki dahil).
	phonePattern = regexp.MustCompile(`\+?\d(?:[\s().\-/]*\d){9,12}`)
	emailPattern = regexp.MustCompile(`(?i)[a-z0-9._%+-]+\s?@\s?[a-z0-9.-]+\.[a-z]{2,}`)
	webPattern   = regexp.MustCompile(`(?i)\b(?:https?://|www\.)\S+|\b[a-z0-9-]{2,}\.(?:com|net|org|com\.tr|net\.tr|org\.tr|tr|info|biz|app|io|me|co)\b`)
)

// Finding, OCR metninde bulunan iletişim bilgisidir.
type Finding struct {
	Kind  string `json:"kind"`
	Value string `json:"value"`
}

// findContacts, OCR metnindeki telefon, e-posta ve web adresi kalıplarını bulur. Fotoğrafta iletişim bilgisi,
// ücret ödenmeden iletişim kurulmasını sağlar (vitrinde telefon yalnız ücretli pakette; talep iletişimi kabulde açılır).
func findContacts(text string) []Finding {
	out := []Finding{}
	for _, m := range phonePattern.FindAllString(text, -1) {
		digits := 0
		for _, r := range m {
			if r >= '0' && r <= '9' {
				digits++
			}
		}
		if digits >= 10 {
			out = append(out, Finding{Kind: "PHONE", Value: strings.TrimSpace(m)})
		}
	}
	for _, m := range emailPattern.FindAllString(text, -1) {
		out = append(out, Finding{Kind: "EMAIL", Value: m})
	}
	if len(out) == 0 || !hasKind(out, "EMAIL") {
		for _, m := range webPattern.FindAllString(text, -1) {
			out = append(out, Finding{Kind: "WEB", Value: m})
		}
	}
	return out
}

func hasKind(list []Finding, kind string) bool {
	for _, f := range list {
		if f.Kind == kind {
			return true
		}
	}
	return false
}

func describe(list []Finding) []string {
	out := make([]string, 0, len(list))
	for _, f := range list {
		out = append(out, f.Kind+": "+f.Value)
	}
	return out
}
