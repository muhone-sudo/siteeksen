package repository

// Banka ekstresi mutabakatı (migration 059, Apsiyon BUG-12).
//
// Gelen her hareket, sakinin bildirdiği ONAY BEKLEYEN ödemeyle eşleştirilmeye çalışılır:
//   1) tutar aynı ve sakinin yazdığı havale açıklaması/dekont no hareket açıklamasında geçiyor → öneri
//   2) tutar aynı ve beyan edilen ödeme günü hareket gününe ±3 gün → tek aday varsa öneri
//   3) yalnızca tutar tutuyor ve tek aday var → öneri (not: yalnızca tutar)
//   birden çok eşit aday → AMBIGUOUS (yönetici seçer), aday yok → UNMATCHED.
// Sistem hiçbir ödemeyi kendiliğinden onaylamaz; yönetici satır satır onaylar. Daha önce
// yüklenmiş hareket (aynı gün, tutar, açıklama, referans) DUPLICATE kaydedilir, yeniden işlenmez.

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
)

var (
	// ErrBankLineNotFound: satır bulunamadı.
	ErrBankLineNotFound = errors.New("ekstre satırı bulunamadı")
	// ErrBankLineResolved: satır zaten onaylanmış/yok sayılmış ya da onaylanamaz türde.
	ErrBankLineResolved = errors.New("bu ekstre satırı onaylanamaz (giden, mükerrer ya da zaten sonuçlanmış)")
	// ErrBankAmountMismatch: seçilen ödemenin tutarı hareketle aynı değil.
	ErrBankAmountMismatch = errors.New("seçilen ödemenin tutarı banka hareketiyle aynı değil")
)

// BankLineInput, ayrıştırılmış ekstre hareketidir.
type BankLineInput struct {
	LineNo      int
	Date        time.Time
	AmountKurus int64
	Description string
	Reference   string
}

// BankLine, kaydedilmiş ekstre satırıdır.
type BankLine struct {
	ID                 string     `json:"id"`
	LineNo             int        `json:"line_no"`
	Date               time.Time  `json:"date"`
	AmountKurus        int64      `json:"amount_kurus"`
	Description        string     `json:"description"`
	Reference          *string    `json:"reference,omitempty"`
	Status             string     `json:"status"`
	SuggestedPaymentID *string    `json:"suggested_payment_id,omitempty"`
	MatchedPaymentID   *string    `json:"matched_payment_id,omitempty"`
	Note               *string    `json:"note,omitempty"`
	Payer              *string    `json:"payer,omitempty"`
	Unit               *string    `json:"unit,omitempty"`
	ResolvedAt         *time.Time `json:"resolved_at,omitempty"`
}

// BankImport, yüklenen ekstredir.
type BankImport struct {
	ID        string         `json:"id"`
	FileName  string         `json:"file_name"`
	RowCount  int            `json:"row_count"`
	CreatedAt time.Time      `json:"created_at"`
	Counts    map[string]int `json:"counts"`
	Lines     []BankLine     `json:"lines,omitempty"`
}

type pendingCandidate struct {
	id, reference string
	valueDate     *time.Time
}

func bankLineHash(l BankLineInput) string {
	norm := strings.Join(strings.Fields(strings.ToLower(l.Description)), " ")
	s := fmt.Sprintf("%s|%d|%s|%s", l.Date.Format("2006-01-02"), l.AmountKurus, norm, strings.TrimSpace(l.Reference))
	sum := sha256.Sum256([]byte(s))
	return hex.EncodeToString(sum[:])
}

// ImportBankStatement, ekstreyi kaydeder ve her gelen hareket için eşleşme önerir.
func (r *FinanceRepository) ImportBankStatement(ctx context.Context, propertyID, userID, fileName, fileSHA string, lines []BankLineInput) (string, error) {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	// Aynı sitede eşzamanlı iki yükleme aynı hareketi iki kez "yeni" saymasın.
	if _, err := tx.Exec(ctx, `SELECT pg_advisory_xact_lock(hashtextextended('bank_import:' || $1::text, 0))`, propertyID); err != nil {
		return "", err
	}
	var importID string
	if err := tx.QueryRow(ctx, `INSERT INTO bank_statement_imports (property_id, file_name, file_sha256, row_count, created_by)
		VALUES ($1, $2, $3, $4, NULLIF($5,'')::uuid) RETURNING id`, propertyID, fileName, fileSHA, len(lines), userID).Scan(&importID); err != nil {
		return "", err
	}
	// Onay bekleyen ödemeler (henüz bir banka hareketiyle eşleşmemiş).
	rows, err := tx.Query(ctx, `
		SELECT p.id::text, round(p.amount * 100)::bigint, COALESCE(p.payer_reference, ''), p.value_date
		FROM payments p
		WHERE p.property_id = $1 AND p.status = 'PENDING' AND COALESCE(p.deleted, 0) = 0
		  AND NOT EXISTS (SELECT 1 FROM bank_statement_lines l WHERE l.matched_payment_id = p.id)`, propertyID)
	if err != nil {
		return "", err
	}
	byAmount := map[int64][]pendingCandidate{}
	for rows.Next() {
		var c pendingCandidate
		var k int64
		if err := rows.Scan(&c.id, &k, &c.reference, &c.valueDate); err != nil {
			rows.Close()
			return "", err
		}
		byAmount[k] = append(byAmount[k], c)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return "", err
	}
	used := map[string]bool{}
	for _, l := range lines {
		hash := bankLineHash(l)
		status, note := "", ""
		var suggested *string
		var dup bool
		if err := tx.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM bank_statement_lines WHERE property_id = $1 AND line_hash = $2 AND status <> 'DUPLICATE')`,
			propertyID, hash).Scan(&dup); err != nil {
			return "", err
		}
		switch {
		case dup:
			status, note = "DUPLICATE", "Bu hareket daha önce yüklenmiş bir ekstrede var; yeniden işlenmedi."
		case l.AmountKurus <= 0:
			status = "OUTGOING"
		default:
			id, why, ambiguous := suggest(l, byAmount[l.AmountKurus], used)
			switch {
			case id != "":
				status, note, suggested = "SUGGESTED", why, &id
				used[id] = true
			case ambiguous:
				status, note = "AMBIGUOUS", "Aynı tutarda birden çok onay bekleyen ödeme var; doğru olanı seçin."
			default:
				status, note = "UNMATCHED", "Bu tutarda onay bekleyen ödeme bildirimi yok."
			}
		}
		if _, err := tx.Exec(ctx, `INSERT INTO bank_statement_lines (import_id, property_id, line_no, txn_date, amount, description, reference,
			line_hash, status, suggested_payment_id, note) VALUES ($1,$2,$3,$4,$5::numeric/100,$6,NULLIF($7,''),$8,$9,$10::uuid,NULLIF($11,''))`,
			importID, propertyID, l.LineNo, l.Date, l.AmountKurus, l.Description, l.Reference, hash, status, suggested, note); err != nil {
			return "", err
		}
	}
	return importID, tx.Commit(ctx)
}

func suggest(l BankLineInput, cands []pendingCandidate, used map[string]bool) (id, why string, ambiguous bool) {
	text := strings.ToLower(l.Description + " " + l.Reference)
	var ref, near, free []pendingCandidate
	for _, c := range cands {
		if used[c.id] {
			continue
		}
		free = append(free, c)
		if r := strings.ToLower(strings.TrimSpace(c.reference)); len(r) >= 3 && strings.Contains(text, r) {
			ref = append(ref, c)
		}
		if c.valueDate != nil {
			if d := l.Date.Sub(*c.valueDate).Hours() / 24; d >= -3 && d <= 3 {
				near = append(near, c)
			}
		}
	}
	switch {
	case len(ref) == 1:
		return ref[0].id, "Tutar ve havale açıklaması/dekont no eşleşti.", false
	case len(ref) > 1:
		return "", "", true
	case len(near) == 1:
		return near[0].id, "Tutar ve beyan edilen ödeme günü (±3 gün) eşleşti.", false
	case len(near) > 1:
		return "", "", true
	case len(free) == 1:
		return free[0].id, "Yalnızca tutar eşleşti; ödeyeni kontrol ederek onaylayın.", false
	case len(free) > 1:
		return "", "", true
	}
	return "", "", false
}

// ListBankImports, yüklenen ekstreleri durum sayılarıyla verir.
func (r *FinanceRepository) ListBankImports(ctx context.Context, propertyID string) ([]BankImport, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT i.id, i.file_name, i.row_count, i.created_at,
		       COALESCE((SELECT jsonb_object_agg(status, n) FROM (SELECT status, count(*) n FROM bank_statement_lines l
		                 WHERE l.import_id = i.id GROUP BY status) s), '{}'::jsonb)::text
		FROM bank_statement_imports i WHERE i.property_id = $1 ORDER BY i.created_at DESC LIMIT 100`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []BankImport{}
	for rows.Next() {
		var b BankImport
		var counts string
		if err := rows.Scan(&b.ID, &b.FileName, &b.RowCount, &b.CreatedAt, &counts); err != nil {
			return nil, err
		}
		b.Counts = parseCounts(counts)
		out = append(out, b)
	}
	return out, rows.Err()
}

func parseCounts(js string) map[string]int {
	out := map[string]int{}
	js = strings.Trim(js, "{} ")
	for _, part := range strings.Split(js, ",") {
		kv := strings.SplitN(part, ":", 2)
		if len(kv) != 2 {
			continue
		}
		var n int
		fmt.Sscanf(strings.TrimSpace(kv[1]), "%d", &n) //nolint:errcheck
		out[strings.Trim(strings.TrimSpace(kv[0]), `"`)] = n
	}
	return out
}

// GetBankImport, ekstreyi satırlarıyla ve önerilen/eşleşen ödemenin sahibiyle verir.
func (r *FinanceRepository) GetBankImport(ctx context.Context, propertyID, id string) (*BankImport, error) {
	list, err := r.ListBankImports(ctx, propertyID)
	if err != nil {
		return nil, err
	}
	var imp *BankImport
	for i := range list {
		if list[i].ID == id {
			imp = &list[i]
		}
	}
	if imp == nil {
		return nil, ErrBankLineNotFound
	}
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT l.id, l.line_no, l.txn_date, round(l.amount * 100)::bigint, l.description, l.reference, l.status,
		       l.suggested_payment_id::text, l.matched_payment_id::text, l.note,
		       NULLIF(TRIM(COALESCE(u.first_name,'') || ' ' || COALESCE(u.last_name,'')), ''),
		       (SELECT string_agg(DISTINCT COALESCE(un.block,'') || '-' || COALESCE(un.door_number,''), ', ')
		          FROM payment_assessments pa JOIN monthly_assessments ma ON ma.id = pa.assessment_id JOIN units un ON un.id = ma.unit_id
		         WHERE pa.payment_id = COALESCE(l.matched_payment_id, l.suggested_payment_id)),
		       l.resolved_at
		FROM bank_statement_lines l
		LEFT JOIN payments p ON p.id = COALESCE(l.matched_payment_id, l.suggested_payment_id)
		LEFT JOIN users u ON u.id = p.user_id
		WHERE l.import_id = $1 AND l.property_id = $2 ORDER BY l.line_no`, id, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	imp.Lines = []BankLine{}
	for rows.Next() {
		var b BankLine
		if err := rows.Scan(&b.ID, &b.LineNo, &b.Date, &b.AmountKurus, &b.Description, &b.Reference, &b.Status,
			&b.SuggestedPaymentID, &b.MatchedPaymentID, &b.Note, &b.Payer, &b.Unit, &b.ResolvedAt); err != nil {
			return nil, err
		}
		imp.Lines = append(imp.Lines, b)
	}
	return imp, rows.Err()
}

// ConfirmBankLine, satırı bir onay bekleyen ödemeyle eşleştirir ve ödemeyi AYNI işlemde onaylar.
func (r *FinanceRepository) ConfirmBankLine(ctx context.Context, propertyID, userID, lineID, paymentID string) (string, error) {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	var status string
	var suggested *string
	var amountKurus int64
	var txnDate time.Time
	var desc string
	var ref *string
	err = tx.QueryRow(ctx, `SELECT status, suggested_payment_id::text, round(amount*100)::bigint, txn_date, description, reference
		FROM bank_statement_lines WHERE id = $1 AND property_id = $2 FOR UPDATE`, lineID, propertyID).
		Scan(&status, &suggested, &amountKurus, &txnDate, &desc, &ref)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", ErrBankLineNotFound
	}
	if err != nil {
		return "", err
	}
	if status != "SUGGESTED" && status != "AMBIGUOUS" && status != "UNMATCHED" {
		return "", ErrBankLineResolved
	}
	if paymentID == "" && suggested != nil {
		paymentID = *suggested
	}
	if paymentID == "" {
		return "", fmt.Errorf("%w: eşleşecek ödeme seçilmedi", ErrInvalidAssessmentInput)
	}
	var payKurus int64
	err = tx.QueryRow(ctx, `SELECT round(amount*100)::bigint FROM payments WHERE id = $1 AND property_id = $2`, paymentID, propertyID).Scan(&payKurus)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", ErrPaymentNotFound
	}
	if err != nil {
		return "", err
	}
	if payKurus != amountKurus {
		return "", ErrBankAmountMismatch
	}
	reference := "Banka ekstresi " + txnDate.Format("02.01.2006")
	if ref != nil && *ref != "" {
		reference += " · " + *ref
	}
	if err := confirmPaymentTx(ctx, tx, paymentID, propertyID, reference, userID); err != nil {
		return "", err
	}
	if _, err := tx.Exec(ctx, `UPDATE bank_statement_lines SET status = 'CONFIRMED', matched_payment_id = $2, resolved_by = NULLIF($3,'')::uuid,
		resolved_at = now() WHERE id = $1`, lineID, paymentID, userID); err != nil {
		return "", err
	}
	return paymentID, tx.Commit(ctx)
}

// IgnoreBankLine, satırı gerekçeyle yok sayar (ör. aidat dışı gelir; ayrıca kaydedilecek).
func (r *FinanceRepository) IgnoreBankLine(ctx context.Context, propertyID, userID, lineID, note string) error {
	note = strings.TrimSpace(note)
	if len([]rune(note)) < 3 {
		return fmt.Errorf("%w: gerekçe zorunludur", ErrInvalidAssessmentInput)
	}
	tag, err := r.scope(propertyID).Exec(ctx, `UPDATE bank_statement_lines SET status = 'IGNORED', note = $3, resolved_by = NULLIF($4,'')::uuid,
		resolved_at = now() WHERE id = $1 AND property_id = $2 AND status IN ('SUGGESTED','AMBIGUOUS','UNMATCHED')`, lineID, propertyID, note, userID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrBankLineResolved
	}
	return nil
}
