package reports

import (
	"context"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
)

// ErrFormat, desteklenmeyen biçim için döner.
var ErrFormat = fmt.Errorf("format pdf ya da xlsx olmalı")

// Write, belgeyi istenen biçimde (pdf|xlsx) indirme olarak yazar. Dosya adı ASCII'ye
// indirgenmiş ve RFC 5987 ile UTF-8 olarak verilir; doğrulama kodu başlıkta da döner.
func Write(w http.ResponseWriter, d *Document, format, baseName string) error {
	var (
		body []byte
		err  error
		ct   string
		ext  string
	)
	switch strings.ToLower(format) {
	case "", "pdf":
		body, err = d.PDF()
		ct, ext = "application/pdf", "pdf"
	case "xlsx", "excel":
		body, err = d.XLSX()
		ct, ext = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "xlsx"
	default:
		return ErrFormat
	}
	if err != nil {
		return err
	}
	name := fmt.Sprintf("%s-%s.%s", baseName, time.Now().In(trLoc()).Format("20060102"), ext)
	w.Header().Set("Content-Type", ct)
	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="%s"; filename*=UTF-8''%s`, asciiName(name), url.PathEscape(name)))
	w.Header().Set("X-Document-Verification", d.VerificationCode())
	w.Header().Set("Cache-Control", "private, no-store")
	w.WriteHeader(http.StatusOK)
	_, err = w.Write(body)
	return err
}

func asciiName(s string) string {
	r := strings.NewReplacer("ç", "c", "Ç", "C", "ğ", "g", "Ğ", "G", "ı", "i", "İ", "I", "ö", "o", "Ö", "O", "ş", "s", "Ş", "S", "ü", "u", "Ü", "U", " ", "-")
	s = r.Replace(s)
	return strings.Map(func(c rune) rune {
		if c < 32 || c > 126 || c == '"' || c == '\\' {
			return '_'
		}
		return c
	}, s)
}

// PropertyName, belge başlığı için sitenin adını okur (site kapsamında).
func PropertyName(ctx context.Context, pool *pgxpool.Pool, propertyID string) string {
	var name string
	if err := dbscope.For(pool, propertyID).QueryRow(ctx, `SELECT name FROM properties WHERE id = $1`, propertyID).Scan(&name); err != nil {
		return "Site"
	}
	return name
}

// KurusOf, float TL değerini kuruşa çevirir (yalnızca görüntüleme amaçlı dökümler için).
func KurusOf(tl float64) int64 {
	if tl < 0 {
		return -int64(-tl*100 + 0.5)
	}
	return int64(tl*100 + 0.5)
}
