package store

// Bakiye koşulları (FAZ M13.3): tedarikçi ilk yüklemeden önce bu metni ayrıca kabul eder (TBK m.21: genel işlem koşulu
// karşı tarafa açıkça bildirilip kabul ettirilmezse yazılmamış sayılır). Kabul, sürüm ve metnin SHA-256 özetiyle saklanır;
// metin değişirse sürüm değişir ve yeniden kabul istenir. Hukuk taslağı: docs/hukuk/tedarikci-bakiye-kosullari.md (aynı metin).

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"net/http"
	"time"

	"github.com/jackc/pgx/v5"
)

// RefundWindowDays, üyelik sona erince kalan bakiyenin karta iade edildiği yükleme yaşı sınırıdır. Sözleşme metniyle
// birlikte değişir (ayar değildir): ödeme kuruluşu (iyzico) bir ödemeyi en çok 365 gün içinde iade edebilir.
const RefundWindowDays = 365

// BalanceTermsKey ve BalanceTermsVersion, bakiye koşullarının anahtarı ve yürürlükteki sürümüdür.
const (
	BalanceTermsKey     = "BALANCE"
	BalanceTermsVersion = "2026-11-01"
	BalanceTermsTitle   = "Usta & Hizmet Bakiye ve İade Koşulları"
)

// BalanceTermsText, tedarikçiye gösterilen ve kabul ettirilen metindir.
const BalanceTermsText = `1. Bakiye, yalnız SiteEksen Usta & Hizmet platformunun hizmet bedellerinde (paket aidatı ve talep kabul ücreti) kullanılır. Bakiye nakde çevrilemez, başka bir hesaba devredilemez, faiz ya da getiri işlemez.

2. Üyelik herhangi bir nedenle (tedarikçinin talebi ya da platformun üyeliği sona erdirmesi) sona erdiğinde kalan bakiye, sona erme tarihinden geriye doğru son 365 gün içinde kartla yapılmış yüklemelerden karşılanan kısmı kadar, yüklemenin yapıldığı karta ödeme kuruluşu aracılığıyla kendiliğinden iade edilir. Kalan bakiye, en yeni yüklemeden başlanarak eskiye doğru yüklemelerle eşleştirilir; bir yüklemeden en çok o yüklemenin tutarı kadar iade yapılır.

3. Sona erme tarihinde 365 günden eski yüklemelerden karşılanan kalan bakiye iade edilmez ve hesaptan düşülür. Bu sınır, ödeme kuruluşunun bir ödemeyi karta iade edebildiği en uzun süredir.

4. Üyelik sona erdikten sonra sonuçlanan bir kart yüklemesi hesaba yazılmaz; tutarın tamamı karta iade edilir.

5. Karta iade teknik bir nedenle yapılamazsa platform, tedarikçinin bildireceği kendi adına kayıtlı banka hesabına iade tutarını havaleyle öder.

6. İadenin karta yansıma süresi kartı veren bankaya bağlıdır. Platform, iade talimatını ödeme kuruluşuna ilettiği tarihi ve sonucunu tedarikçinin hesabında gösterir.

7. Bu koşullar ilk bakiye yüklemesinden önce ayrıca gösterilir ve kabul edilmeden bakiye yüklenemez. Kabul tarihi ve metnin sürümü kaydedilir. Koşullar değişirse sonraki yüklemeden önce yeniden kabul istenir.`

// BalanceTermsSHA256, metnin özetidir (kabul kaydına yazılır).
func BalanceTermsSHA256() string {
	h := sha256.Sum256([]byte(BalanceTermsText))
	return hex.EncodeToString(h[:])
}

// TermsAcceptance, hesabın yürürlükteki koşul sürümünü kabul kaydıdır.
type TermsAcceptance struct {
	Version    string    `json:"version"`
	AcceptedAt time.Time `json:"accepted_at"`
}

// BalanceTermsAccepted, hesabın yürürlükteki sürümü kabul edip etmediğini döner (kabul yoksa nil).
func (s *Store) BalanceTermsAccepted(ctx context.Context, accountID string) (*TermsAcceptance, error) {
	return termsAccepted(ctx, s.supplier(accountID), accountID)
}

type rowQuerier interface {
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

func termsAccepted(ctx context.Context, q rowQuerier, accountID string) (*TermsAcceptance, error) {
	t := &TermsAcceptance{}
	err := q.QueryRow(ctx, `SELECT version, accepted_at FROM mp_terms_acceptances WHERE account_id = $1 AND terms_key = $2 AND version = $3`,
		accountID, BalanceTermsKey, BalanceTermsVersion).Scan(&t.Version, &t.AcceptedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	return t, err
}

// AcceptBalanceTerms, yürürlükteki sürümün kabulünü kaydeder. İstemci kabul ettiği sürümü gönderir; yürürlükteki sürüm
// değilse 409 (kullanıcının görmediği bir metin kabul edilmiş sayılmaz). Aynı sürümün ikinci kabulü ilk kaydı döner.
func (s *Store) AcceptBalanceTerms(ctx context.Context, accountID, userID, version, ip string) (*TermsAcceptance, error) {
	if version != BalanceTermsVersion {
		return nil, userErr(http.StatusConflict, "TERMS_VERSION", "Koşulların güncel sürümü değişti; sayfayı yenileyip metni yeniden okuyun")
	}
	sc := s.supplier(accountID)
	if _, err := sc.Exec(ctx, `INSERT INTO mp_terms_acceptances (account_id, user_id, terms_key, version, text_sha256, ip)
		VALUES ($1, $2, $3, $4, $5, $6) ON CONFLICT (account_id, terms_key, version) DO NOTHING`,
		accountID, userID, BalanceTermsKey, BalanceTermsVersion, BalanceTermsSHA256(), ip); err != nil {
		return nil, err
	}
	return termsAccepted(ctx, sc, accountID)
}

// ErrTermsRequired: bakiye koşulları kabul edilmeden yükleme yapılamaz.
var ErrTermsRequired = &UserError{Status: http.StatusConflict, Code: "TERMS_REQUIRED",
	Message: "Bakiye yüklemeden önce bakiye ve iade koşullarını okuyup kabul etmeniz gerekir"}
