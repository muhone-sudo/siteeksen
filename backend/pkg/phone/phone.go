// Package phone, telefon numaralarını tek biçime (E.164: +ÜLKEKODU…) getirir.
//
// Yurt dışında yaşayan kat malikleri (Apsiyon BUG-10: Lüksemburg +352, Almanya +49) de
// hesap açabilmeli, giriş yapabilmeli ve SMS alabilmelidir. Önceden "00352…" yazımı
// başına +90 eklenerek bozuluyor, mobil uygulama her numaraya +90 ekliyordu.
//
// Kurallar:
//   - "+" ya da "00" ile başlayan numara uluslararasıdır: ülke kodu + abone numarası,
//     toplam 8–15 hane (ITU-T E.164). +90 ise ardından tam 10 hane gelmelidir.
//   - Diğerleri Türkiye numarasıdır: 0XXXXXXXXXX, 90XXXXXXXXXX ya da XXXXXXXXXX (10 hane).
package phone

import (
	"errors"
	"strings"
)

// ErrInvalid, numaranın tanınamadığını bildirir.
var ErrInvalid = errors.New("telefon numarası geçersiz; yurt dışı numarayı +ülke kodu ile yazın (ör. +49…)")

// Normalize, numarayı E.164 biçimine getirir.
func Normalize(input string) (string, error) {
	s := strings.TrimSpace(input)
	plus := strings.HasPrefix(s, "+")
	digits := strings.Map(func(r rune) rune {
		if r >= '0' && r <= '9' {
			return r
		}
		switch r {
		case ' ', '-', '(', ')', '.', '\t', '+', '/':
			return -1
		}
		return 'x'
	}, s)
	if digits == "" || strings.ContainsRune(digits, 'x') || strings.Count(s, "+") > 1 || (strings.Contains(s, "+") && !plus) {
		return "", ErrInvalid
	}
	if !plus && strings.HasPrefix(digits, "00") {
		plus, digits = true, digits[2:]
	}
	if plus {
		if strings.HasPrefix(digits, "0") || len(digits) < 8 || len(digits) > 15 {
			return "", ErrInvalid
		}
		if strings.HasPrefix(digits, "90") {
			return turkish(digits[2:])
		}
		return "+" + digits, nil
	}
	switch {
	case len(digits) == 11 && digits[0] == '0':
		return turkish(digits[1:])
	case len(digits) == 12 && strings.HasPrefix(digits, "90"):
		return turkish(digits[2:])
	case len(digits) == 10:
		return turkish(digits)
	}
	return "", ErrInvalid
}

func turkish(national string) (string, error) {
	if len(national) != 10 || national[0] == '0' {
		return "", ErrInvalid
	}
	return "+90" + national, nil
}

// National, şifre denetimi gibi yerlerde kullanılan abone kısmıdır (ülke kodu olmadan).
// Türkiye için son 10 hane; diğer ülkelerde ülke kodunu bilmeden ayıramayız, son 8 hane kullanılır.
func National(e164 string) string {
	d := strings.TrimPrefix(e164, "+")
	if strings.HasPrefix(d, "90") && len(d) == 12 {
		return d[2:]
	}
	if len(d) > 8 {
		return d[len(d)-8:]
	}
	return d
}
