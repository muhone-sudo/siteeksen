// Package listcap, güvenlik tavanıyla sınırlanan listelerde kesilmeyi görünür kılar (B69).
//
// Liste uçları sınırsız satır döndürmesin diye sorgular tavanla sınırlıdır.
// Önceden tavan sessizce uygulanıyordu: 500. kayıttan eskisi hiç görünmüyor ve
// bunu kimse bilmiyordu. Kural: sorgu tavan+1 satır okur; fazlası varsa liste
// tavana kesilir ve yanıt `truncated: true` taşır, istemci süzgeç önerir.
package listcap

// Default, yoğun listelerin tavanıdır. Sorgularda LIMIT Default+1 kullanılır.
const Default = 500

// Trim, en çok limit kayıt bırakır; kesildiyse ikinci dönüş true'dur.
func Trim[T any](items []T, limit int) ([]T, bool) {
	if len(items) > limit {
		return items[:limit], true
	}
	return items, false
}
