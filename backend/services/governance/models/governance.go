// Package models, yönetişim (KMK m.29-45) veri yapılarını tanımlar.
package models

import "time"

// -----------------------------------------------------------------------------
// İŞLETME PROJESİ (KMK m.37)
// -----------------------------------------------------------------------------

// BudgetStatus değerleri.
const (
	BudgetDraft     = "DRAFT"    // hazırlanıyor
	BudgetNotified  = "NOTIFIED" // tebliğ edildi, itiraz süresi işliyor
	BudgetFinal     = "FINAL"    // kesinleşti — İİK m.68 anlamında belge
	BudgetCancelled = "CANCELLED"
)

// BudgetItem, işletme projesinin bir gelir/gider kalemidir.
type BudgetItem struct {
	ID               string  `json:"id,omitempty"`
	CategoryID       string  `json:"category_id,omitempty"`
	Name             string  `json:"name" binding:"required"`
	Amount           float64 `json:"amount" binding:"required,gt=0"`
	DistributionType string  `json:"distribution_type" binding:"required"`
	Kind             string  `json:"kind,omitempty"` // EXPENSE | INCOME
	Note             string  `json:"note,omitempty"`
	SortOrder        int     `json:"sort_order,omitempty"`
}

// UnitShare, bir bağımsız bölüme düşen yıllık/aylık paydır (kuruş).
type UnitShare struct {
	UnitID       string           `json:"unit_id"`
	UnitName     string           `json:"unit_name,omitempty"`
	AnnualKurus  int64            `json:"annual_kurus"`
	MonthlyKurus int64            `json:"monthly_kurus"`
	Breakdown    map[string]int64 `json:"breakdown,omitempty"`
}

// Budget, işletme projesidir.
type Budget struct {
	ID                string       `json:"id"`
	PropertyID        string       `json:"property_id"`
	PeriodYear        int          `json:"period_year"`
	Status            string       `json:"status"`
	TotalAmount       float64      `json:"total_amount"`
	PreparedBy        string       `json:"prepared_by,omitempty"`
	PreparedAt        *time.Time   `json:"prepared_at,omitempty"`
	NotifiedAt        *time.Time   `json:"notified_at,omitempty"`
	NoticeMethod      string       `json:"notice_method,omitempty"`
	ObjectionDeadline *time.Time   `json:"objection_deadline,omitempty"`
	FinalizedAt       *time.Time   `json:"finalized_at,omitempty"`
	DecisionRef       string       `json:"decision_ref,omitempty"`
	Note              string       `json:"note,omitempty"`
	Items             []BudgetItem `json:"items,omitempty"`
	UnitShares        []UnitShare  `json:"unit_shares,omitempty"`
	// OpenObjections, kesinleştirmeyi engelleyen açık itiraz sayısıdır.
	OpenObjections int `json:"open_objections"`
}

// CreateBudgetInput, yeni işletme projesi girdisidir.
type CreateBudgetInput struct {
	PeriodYear int          `json:"period_year" binding:"required"`
	Items      []BudgetItem `json:"items" binding:"required,min=1,dive"`
	Note       string       `json:"note"`
}

// NotifyBudgetInput, tebliğ bilgisidir (m.37: tebliğ anı itiraz süresini başlatır).
type NotifyBudgetInput struct {
	// IMZA_KARSILIGI | TAAHHUTLU_MEKTUP | ELEKTRONIK
	Method string `json:"method" binding:"required"`
}

// Objection, işletme projesine itirazdır (m.37/2).
type Objection struct {
	ID          string     `json:"id"`
	BudgetID    string     `json:"budget_id"`
	UnitID      string     `json:"unit_id,omitempty"`
	UserID      string     `json:"user_id,omitempty"`
	Reason      string     `json:"reason"`
	SubmittedAt time.Time  `json:"submitted_at"`
	Status      string     `json:"status"`
	Resolution  string     `json:"resolution,omitempty"`
	ResolvedAt  *time.Time `json:"resolved_at,omitempty"`
	// InTime, itirazın yasal süre içinde yapılıp yapılmadığını gösterir.
	InTime bool `json:"in_time"`
}

// -----------------------------------------------------------------------------
// GENEL KURUL (KMK m.29-33)
// -----------------------------------------------------------------------------

// Assembly durumları.
const (
	AssemblyPlanned   = "PLANNED"
	AssemblyNotified  = "NOTIFIED"
	AssemblyHeld      = "HELD"
	AssemblyCancelled = "CANCELLED"
)

// Assembly, kat malikleri kurulu toplantısıdır.
type Assembly struct {
	ID                 string       `json:"id"`
	PropertyID         string       `json:"property_id"`
	Kind               string       `json:"kind"`
	CallNumber         int          `json:"call_number"`
	ScheduledAt        time.Time    `json:"scheduled_at"`
	Location           string       `json:"location,omitempty"`
	NoticeSentAt       *time.Time   `json:"notice_sent_at,omitempty"`
	NoticeMethod       string       `json:"notice_method,omitempty"`
	Status             string       `json:"status"`
	HeldAt             *time.Time   `json:"held_at,omitempty"`
	TotalUnits         *int         `json:"total_units,omitempty"`
	TotalShareRatio    *float64     `json:"total_share_ratio,omitempty"`
	AttendedUnits      *int         `json:"attended_units,omitempty"`
	AttendedShareRatio *float64     `json:"attended_share_ratio,omitempty"`
	QuorumMet          *bool        `json:"quorum_met,omitempty"`
	MinutesRef         string       `json:"minutes_ref,omitempty"`
	AgendaItems        []AgendaItem `json:"agenda_items,omitempty"`
}

// AgendaItem, gündem maddesidir.
type AgendaItem struct {
	ID                   string  `json:"id"`
	AssemblyID           string  `json:"assembly_id"`
	OrderNo              int     `json:"order_no"`
	Title                string  `json:"title"`
	Description          string  `json:"description,omitempty"`
	RequiredMajorityCode string  `json:"required_majority_code,omitempty"`
	DecisionText         string  `json:"decision_text,omitempty"`
	DecisionStatus       string  `json:"decision_status"`
	VotesFor             int     `json:"votes_for"`
	VotesAgainst         int     `json:"votes_against"`
	VotesAbstain         int     `json:"votes_abstain"`
	ShareFor             float64 `json:"share_for"`
	ShareAgainst         float64 `json:"share_against"`
	ShareAbstain         float64 `json:"share_abstain"`
}

// CreateAssemblyInput, toplantı oluşturma girdisidir.
type CreateAssemblyInput struct {
	Kind        string       `json:"kind"`
	CallNumber  int          `json:"call_number"`
	ScheduledAt time.Time    `json:"scheduled_at" binding:"required"`
	Location    string       `json:"location"`
	AgendaItems []AgendaItem `json:"agenda_items" binding:"required,min=1,dive"`
}

// AttendeeInput, hazirun kaydıdır.
type AttendeeInput struct {
	UnitID         string `json:"unit_id" binding:"required"`
	UserID         string `json:"user_id"`
	AttendanceType string `json:"attendance_type"` // SELF | PROXY
	ProxyHolderID  string `json:"proxy_holder_id"`
}

// Attendee, hazirun cetvelindeki bir satırdır (KMK m.30: toplantıya katılan
// kat malikleri ve arsa payları cetvele yazılır).
type Attendee struct {
	UnitID         string  `json:"unit_id"`
	UnitName       string  `json:"unit_name"`
	UserID         string  `json:"user_id,omitempty"`
	UserName       string  `json:"user_name,omitempty"`
	AttendanceType string  `json:"attendance_type"`
	ProxyHolderID  string  `json:"proxy_holder_id,omitempty"`
	ProxyHolder    string  `json:"proxy_holder_name,omitempty"`
	ShareRatio     float64 `json:"share_ratio"`
}

// VoteInput, oy kaydıdır.
type VoteInput struct {
	UnitID string `json:"unit_id" binding:"required"`
	Vote   string `json:"vote" binding:"required"` // FOR | AGAINST | ABSTAIN
}

// QuorumResult, nisap hesabının sonucudur.
//
// KMK m.30: toplantı yeter sayısı SAYI ve ARSA PAYI bakımından ayrı ayrı aranır.
// İkisinden biri sağlanmazsa toplantı yapılamaz; bu yüzden iki ölçü de raporlanır.
type QuorumResult struct {
	TotalUnits         int     `json:"total_units"`
	TotalShareRatio    float64 `json:"total_share_ratio"`
	AttendedUnits      int     `json:"attended_units"`
	AttendedShareRatio float64 `json:"attended_share_ratio"`
	RequiredRatio      float64 `json:"required_ratio"`
	ByCountMet         bool    `json:"by_count_met"`
	ByShareMet         bool    `json:"by_share_met"`
	Met                bool    `json:"met"`
	CallNumber         int     `json:"call_number"`
	Explanation        string  `json:"explanation"`
	LegalBasis         string  `json:"legal_basis"`
}

// MajorityResult, bir gündem maddesinin nisap değerlendirmesidir.
type MajorityResult struct {
	RequiredCode  string  `json:"required_code"`
	RequiredRatio float64 `json:"required_ratio"`
	ByCountRatio  float64 `json:"by_count_ratio"`
	ByShareRatio  float64 `json:"by_share_ratio"`
	Accepted      bool    `json:"accepted"`
	Explanation   string  `json:"explanation"`
	LegalBasis    string  `json:"legal_basis"`
}

// -----------------------------------------------------------------------------
// DEFTERLER (KMK m.32, m.36)
// -----------------------------------------------------------------------------

// Book, karar ya da işletme defteridir.
type Book struct {
	ID             string     `json:"id"`
	PropertyID     string     `json:"property_id"`
	Kind           string     `json:"kind"`
	PeriodYear     int        `json:"period_year"`
	NotaryOpenedAt *time.Time `json:"notary_opened_at,omitempty"`
	NotaryClosedAt *time.Time `json:"notary_closed_at,omitempty"`
	NotaryRef      string     `json:"notary_ref,omitempty"`
	Status         string     `json:"status"`
	EntryCount     int        `json:"entry_count"`
}

// BookEntry, defter kaydıdır. Değiştirilemez.
type BookEntry struct {
	ID         string    `json:"id"`
	BookID     string    `json:"book_id"`
	EntryNo    int       `json:"entry_no"`
	EntryDate  time.Time `json:"entry_date"`
	Title      string    `json:"title"`
	Body       string    `json:"body"`
	SourceType string    `json:"source_type,omitempty"`
	SourceID   string    `json:"source_id,omitempty"`
	CreatedBy  string    `json:"created_by,omitempty"`
	CreatedAt  time.Time `json:"created_at"`
	PrevHash   string    `json:"prev_hash,omitempty"`
	EntryHash  string    `json:"entry_hash"`
}

// CreateBookEntryInput, yeni defter kaydıdır.
type CreateBookEntryInput struct {
	Title      string `json:"title" binding:"required"`
	Body       string `json:"body" binding:"required"`
	SourceType string `json:"source_type"`
	SourceID   string `json:"source_id"`
	EntryDate  string `json:"entry_date"`
}

// BookIntegrity, defterin hash zinciri doğrulamasının sonucudur.
type BookIntegrity struct {
	BookID     string `json:"book_id"`
	EntryCount int    `json:"entry_count"`
	Valid      bool   `json:"valid"`
	BrokenAtNo int    `json:"broken_at_entry_no,omitempty"`
	Message    string `json:"message"`
}

// -----------------------------------------------------------------------------
// HUKUK / İCRA (KMK m.22, İİK m.68)
// -----------------------------------------------------------------------------

// LegalCase, ortak gider alacağı için açılan takiptir.
type LegalCase struct {
	ID                string     `json:"id"`
	PropertyID        string     `json:"property_id"`
	UnitID            string     `json:"unit_id,omitempty"`
	DebtorUserID      string     `json:"debtor_user_id,omitempty"`
	CaseType          string     `json:"case_type"`
	Status            string     `json:"status"`
	PrincipalKurus    int64      `json:"principal_kurus"`
	LateFeeKurus      int64      `json:"late_fee_kurus"`
	BasisDocumentType string     `json:"basis_document_type,omitempty"`
	BasisDocumentID   string     `json:"basis_document_id,omitempty"`
	FiledAt           *time.Time `json:"filed_at,omitempty"`
	OfficeOrCourt     string     `json:"office_or_court,omitempty"`
	FileNo            string     `json:"file_no,omitempty"`
	LawyerName        string     `json:"lawyer_name,omitempty"`
	Note              string     `json:"note,omitempty"`
}

// CreateLegalCaseInput, takip açma girdisidir.
type CreateLegalCaseInput struct {
	UnitID            string `json:"unit_id" binding:"required"`
	DebtorUserID      string `json:"debtor_user_id"`
	CaseType          string `json:"case_type" binding:"required"`
	BasisDocumentType string `json:"basis_document_type"`
	BasisDocumentID   string `json:"basis_document_id"`
	OfficeOrCourt     string `json:"office_or_court"`
	FileNo            string `json:"file_no"`
	LawyerName        string `json:"lawyer_name"`
	Note              string `json:"note"`
}
