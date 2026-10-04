/**
 * Arka uç yanıt tipleri — tasks/api-sozlesmesi.md ile birebir.
 * Alan adları sunucunun JSON etiketleridir; burada uydurma alan YOKTUR.
 * Doğrulama: admin/scripts/verify-endpoints.ts gerçek gateway'e karşı çalışır.
 */

export type List<T> = { data: T[] };
/** Sayfalı liste (B69): `total` kesilmiş listeyi fark ettirmek için. */
export type Paged<T> = { data: T[]; total: number; limit: number; offset: number };
export type Id = string;

export interface BroadcastResult {
    recipients: number;
    sent: number;
    pending: number;
    suppressed: number;
    failed: number;
    duplicate: number;
    note?: string;
}

// ---------------------------------------------------------------- identity
export interface UserProperty { property_id: Id; property_name: string; unit_id: Id; unit_name: string; role: string }
export interface Resident {
    id: Id; user_id: Id; first_name: string; last_name: string; phone: string; email: string;
    unit_id: Id; unit: string; role: string; is_active: boolean; created_at: string;
}
/** Yöneticiye YALNIZCA BİR KEZ gösterilen etkinleştirme / şifre sıfırlama kodu. */
export interface Activation { activation_code: string; purpose: "ACTIVATION" | "RESET"; expires_at: string; note: string }
/** Sakin daveti (S-20): kişinin adı/e-postası yönetime gösterilmez. */
export interface Invitation {
    id: Id; unit_id: Id; unit: string; phone: string; role: string;
    status: "PENDING" | "ACCEPTED" | "DECLINED" | "CANCELLED" | "EXPIRED"; created_at: string; expires_at: string; responded_at?: string;
}
/** Bağ kurulduysa sakin alanları; kişi başka sitede kayıtlıysa yalnızca `invitation` döner (202). */
export type CreateResidentResult = Partial<Resident> & { activation?: Activation; invitation?: Invitation; note?: string };
export interface Unit {
    id: Id; property_id: Id; block: string; floor: number; door_number: string; share_ratio: number;
    gross_area_m2: number; unit_type: string; is_commercial: boolean; is_ground_floor?: boolean;
}
/** Bölüm ekleme/güncelleme girdisi; güncellemede verilmeyen alan değişmez. */
export interface UnitInput {
    block?: string; floor?: number; door_number?: string; share_ratio?: number; gross_area_m2?: number;
    unit_type?: string; is_commercial?: boolean; is_ground_floor?: boolean;
}

// ---------------------------------------------------------------- finance
export interface AssessmentPeriod { period: string; due_date: string; total_amount: number; collected_amount: number; rate: number; status: string }
export interface Debtor { unit_id: Id; resident_id: Id | ""; name: string; unit: string; amount: number }
export interface Payment {
    id: Id; user_id: string; amount: number; payment_method: string; status: string;
    transaction_id?: string; created_at: string; completed_at: string; name: string; unit: string;
}
export interface FinanceCategory { id: Id; property_id: Id; name: string; distribution_type: string; is_active: boolean }
export interface LateFeeRun {
    as_of: string; monthly_rate: string; legal_basis: string; processed_count: number;
    total_fee_kurus: number; total_fee_try: string; skipped_not_due: number;
}

// ---------------------------------------------------------------- community
export interface ServiceRequest {
    id: Id; unit_id: Id | null; resident_id: Id; ticket_number: string; title: string; description: string;
    location: string; priority: string; status: string; created_at: string; resolved_at: string | null;
}
export interface Announcement {
    id: Id; title: string; content: string; category: string; priority: string; is_pinned: boolean;
    published_at: string; expires_at?: string; created_by_name?: string; is_read: boolean; read_count?: number;
}

// ---------------------------------------------------------------- notification
export interface Notification {
    id: Id; recipient_name?: string; recipient_masked: string; channel: string; category: string; topic: string;
    subject?: string; body: string; status: string; suppress_reason?: string; attempts: number; created_at: string; sent_at?: string;
}
export interface NotificationSummary {
    total: number; pending: number; sent: number; failed: number; suppressed: number;
    by_channel: Record<string, number>; pending_note?: string;
}
export interface Preference { channel: string; category: string; enabled: boolean; consent_at?: string; consent_source?: string }

// ---------------------------------------------------------------- expense
export interface ExpenseCategory {
    id: Id; property_id?: string; name: string; description?: string; distribution_type: string;
    reflects_to_assessment: boolean; is_default: boolean; is_active: boolean; legal_basis?: string;
}
export interface Expense {
    id: Id; category_id: Id; category_name?: string; description: string; amount: number; expense_date: string;
    is_invoiced: boolean; invoice_reason?: string; distribution_type: string; status: string;
    rejection_reason?: string; vendor_name?: string; invoice_number?: string; created_at: string;
    per_unit_amount?: number; distributions?: { unit_id: Id; unit_name?: string; amount: number; is_paid: boolean }[];
}
export interface ExpenseSummary {
    period_year: number; total_amount: number; invoiced_amount: number; non_invoiced_amount: number; pending_count: number;
    by_category: { category_id: Id; category_name: string; amount: number; count: number }[];
}

// ---------------------------------------------------------------- personnel
export interface Employee {
    id: Id; employee_number?: string; first_name: string; last_name: string; tc_number?: string; bank_iban?: string;
    phone?: string; email?: string; position: string; department?: string; hire_date: string; end_date?: string;
    contract_type: string; gross_salary?: number; net_salary?: number; annual_leave_days: number;
    used_leave_days: number; remaining_leave_days: number; is_active: boolean; salary_visible: boolean;
}
export interface Leave {
    id: Id; employee_id: Id; employee_name?: string; leave_type: string; start_date: string; end_date: string;
    days: number; reason?: string; status: string; rejection_reason?: string;
}
export interface PersonnelSummary {
    total_active: number; total_inactive: number; pending_leaves: number; monthly_salary_cost?: number;
    by_position: { position: string; count: number }[];
}

// ---------------------------------------------------------------- visitor
export interface Visitor {
    id: Id; unit_id?: Id; unit_name?: string; visitor_name: string; visitor_phone?: string; visitor_company?: string;
    vehicle_plate?: string; purpose?: string; expected_at?: string; checked_in_at?: string; checked_out_at?: string;
    status: string; duration_minutes?: number; notes?: string; created_at: string;
}
export interface VisitorSummary { currently_inside: number; today_expected: number; today_checked_in: number; today_checked_out: number }

// ---------------------------------------------------------------- parking
export interface Vehicle {
    id: Id; unit_id?: Id; unit_name?: string; owner_type: string; owner_name?: string; plate: string;
    brand?: string; model?: string; color?: string; vehicle_type: string; parking_spot?: string; is_active: boolean;
}
export interface ParkingZone {
    id: Id; name: string; location?: string; capacity: number; occupied_count: number; available_spots: number;
    is_paid: boolean; hourly_fee?: number; daily_fee?: number; is_active: boolean;
}
export interface ParkingLog {
    id: Id; parking_zone_id?: Id; zone_name?: string; plate: string; entry_at: string; exit_at?: string;
    duration_minutes?: number; calculated_fee?: number; payment_status?: string; is_resident: boolean;
}

// ---------------------------------------------------------------- reservation
export interface Facility {
    id: Id; name: string; category?: string; capacity?: number; is_paid: boolean; hourly_fee?: number;
    available_from: string; available_to: string; requires_approval: boolean; is_active: boolean; maintenance_mode: boolean;
}
export interface Reservation {
    id: Id; facility_id: Id; facility_name?: string; unit_name?: string; resident_name?: string; start_time: string;
    end_time: string; guest_count: number; purpose?: string; status: string; total_fee: number; rejection_reason?: string;
}

// ---------------------------------------------------------------- package
export interface Package {
    id: Id; unit_id: Id; unit_name?: string; recipient_name: string; carrier?: string; tracking_number?: string;
    package_type: string; received_at: string; storage_location?: string; notification_sent: boolean; reminder_count: number;
    delivered_at?: string; delivered_to_name?: string; status: string; waiting_days?: number;
}
export interface PackageSummary { pending: number; delivered: number; returned: number; not_notified: number; waiting_over_7_days: number; oldest_waiting_days: number }

// ---------------------------------------------------------------- contract
export interface Contract {
    id: Id; contract_type: string; title: string; party_name: string; start_date: string; end_date?: string;
    auto_renew: boolean; renewal_period_months?: number; renewal_notice_days: number; payment_type?: string;
    monthly_amount?: number; yearly_amount?: number; status: string; days_remaining?: number; notice_due: boolean;
    termination_reason?: string;
}
export interface ContractSummary {
    active: number; expired: number; terminated: number; notice_due: number; expiring_in_30_days: number;
    monthly_commitment_try: number; yearly_commitment_try: number;
}

// ---------------------------------------------------------------- document
export interface DocumentRec {
    id: Id; category: string; title: string; description?: string; file_name: string; content_type: string;
    size_bytes: number; sha256: string; visibility: string; version: number; is_current: boolean;
    retention_until?: string; uploaded_by_name?: string; uploaded_at: string; archived_at?: string;
}
export interface DocumentSummary { total: number; archived: number; by_category: Record<string, number>; total_size_bytes: number; retention_due: number }
export interface AccessLogEntry { user_name?: string; action: string; ip_address?: string; accessed_at: string }

// ---------------------------------------------------------------- asset
export interface Asset {
    id: Id; category_id?: Id; category_name?: string; name: string; asset_code?: string; serial_number?: string;
    location?: string; purchase_date?: string; purchase_price?: number; warranty_end?: string; warranty_days_left?: number;
    book_value?: number; condition: string; status: string; assigned_to?: string; next_maintenance_date?: string;
    maintenance_overdue_days?: number;
}
export interface AssetCategory { id: Id; name: string; depreciation_years: number; is_global: boolean; asset_count: number }
export interface AssetSummary {
    total: number; active: number; disposed: number; maintenance_overdue: number; warranty_expiring_30_days: number;
    purchase_total_try: number; maintenance_cost_ytd_try: number;
}
export interface Maintenance { id: Id; maintenance_type: string; description: string; total_cost: number; performed_by?: string; performed_at?: string; status: string }

// ---------------------------------------------------------------- inventory
export interface InventoryItem {
    id: Id; category_id?: Id; category_name?: string; name: string; sku?: string; unit: string; current_stock: string;
    minimum_stock: string; unit_price?: number; stock_value?: number; location?: string; is_active: boolean; below_minimum: boolean;
}
export interface InventoryMovement {
    id: Id; item_id: Id; item_name?: string; unit?: string; movement_type: string; quantity: string; previous_stock: string;
    new_stock: string; reference_type?: string; notes?: string; created_by_name?: string; created_at: string;
}
export interface InventorySummary {
    item_count: number; below_minimum: number; out_of_stock: number; total_value_try: number;
    purchase_cost_ytd_try: number; consumption_cost_ytd_try: number; movements_last_30_days: number;
}

// ---------------------------------------------------------------- survey
export interface Survey {
    id: Id; title: string; description?: string; survey_type: string; is_anonymous: boolean; is_weighted: boolean;
    starts_at: string; ends_at?: string; status: string; eligible_voters: number; total_votes: number; participation_rate: string;
    options?: { id: Id; option_text: string; vote_count?: number; percentage?: string; weighted_share?: string }[];
}

// ---------------------------------------------------------------- iot
export interface Meter {
    id: Id; unit_id: Id; unit_name?: string; meter_type: string; serial_number: string; brand?: string;
    is_active: boolean; last_reading_date?: string; last_reading_value?: string;
}
export interface MeterReading {
    id: Id; meter_id: Id; serial_number?: string; unit_name?: string; reading_date: string; previous_value: string;
    current_value: string; consumption: string; reading_type: string; reader_name?: string;
}
export interface Allocation {
    total_kurus: number; consumption_part_kurus: number; area_part_kurus: number;
    units: { unit_id: Id; unit_name: string; consumption: string; usable_area: string; total_kurus: number; total_try: string }[];
}

// ---------------------------------------------------------------- patrol
export interface Checkpoint { id: Id; name: string; location?: string; building?: string; floor?: string; nfc_tag_id?: string; qr_code?: string; is_active: boolean }
export interface PatrolRoute {
    id: Id; name: string; description?: string; checkpoints: { checkpoint_id: Id; name?: string; order: number; optional: boolean }[];
    expected_duration_minutes: number; tolerance_minutes: number; is_active: boolean;
}
export interface Patrol {
    id: Id; route_name?: string; guard_name?: string; started_at: string; completed_at?: string; status: string;
    checkpoints_expected: number; checkpoints_visited: number; issues_reported: number; too_fast: boolean;
    actual_duration_minutes?: number;
}
export interface PatrolSummary { patrols_last_7_days: number; completed: number; incomplete: number; in_progress: number; issues_reported: number; suspiciously_fast: number }

// ---------------------------------------------------------------- bulletin
export interface BulletinPost {
    id: Id; category: string; title: string; content: string; author_name?: string; unit_name?: string; price?: number;
    status: string; rejection_reason?: string; expires_at?: string; view_count: number; comment_count: number; created_at: string;
}
export interface BulletinSummary { pending_review: number; approved: number; rejected: number; expired: number; closed: number; by_category: Record<string, number> }

// ---------------------------------------------------------------- settings
export interface Setting { key: string; type: string; description: string; value: unknown; is_default: boolean; updated_by_name?: string; updated_at?: string }
export interface SettingDef { key: string; type: string; description: string; default: unknown; min?: number; max?: number }
export interface SettingHistory { key: string; old_value?: string; new_value: string; changed_by_name?: string; changed_at: string }

// ---------------------------------------------------------------- governance
export interface BudgetItem { id?: Id; category_id?: string; name: string; amount: number; distribution_type: string; kind?: string; note?: string }
export interface UnitShare { unit_id: Id; unit_name?: string; annual_kurus: number; monthly_kurus: number; breakdown?: Record<string, number> }
export interface Budget {
    id: Id; period_year: number; status: string; total_amount: number; notified_at?: string; notice_method?: string;
    objection_deadline?: string; finalized_at?: string; decision_ref?: string; note?: string;
    items?: BudgetItem[]; unit_shares?: UnitShare[]; open_objections: number;
}
export interface Objection { id: Id; unit_id?: string; user_id?: string; reason: string; submitted_at: string; status: string; resolution?: string; in_time: boolean }
export interface AgendaItem {
    id: Id; order_no: number; title: string; description?: string; required_majority_code?: string; decision_text?: string;
    decision_status: string; votes_for: number; votes_against: number; votes_abstain: number; share_for: number; share_against: number;
}
export interface Assembly {
    id: Id; kind: string; call_number: number; scheduled_at: string; location?: string; notice_sent_at?: string;
    notice_method?: string; status: string; held_at?: string; attended_units?: number; total_units?: number;
    quorum_met?: boolean; agenda_items?: AgendaItem[];
}
export interface Attendee {
    unit_id: Id; unit_name: string; user_id?: string; user_name?: string; attendance_type: string;
    proxy_holder_id?: string; proxy_holder_name?: string; share_ratio: number;
}
export interface Quorum {
    total_units: number; total_share_ratio: number; attended_units: number; attended_share_ratio: number;
    required_ratio: number; by_count_met: boolean; by_share_met: boolean; met: boolean; explanation: string; legal_basis: string;
}
export interface MajorityResult { accepted: boolean; explanation: string; legal_basis: string; by_count_ratio: number; by_share_ratio: number }
export interface Book { id: Id; kind: string; period_year: number; status: string; entry_count: number; notary_ref?: string; notary_closed_at?: string }
export interface BookEntry { id: Id; entry_no: number; entry_date: string; title: string; body: string; prev_hash?: string; entry_hash: string; created_at: string }
export interface BookIntegrity { book_id: Id; entry_count: number; valid: boolean; broken_at_entry_no?: number; message: string }
export interface LegalCase {
    id: Id; unit_id?: Id; case_type: string; status: string; principal_kurus: number; late_fee_kurus: number;
    basis_document_type?: string; office_or_court?: string; file_no?: string; lawyer_name?: string; filed_at?: string;
}

// ---------------------------------------------------------------- analitik
export interface EnergyTrends {
    periods: { period: string; meter_type: string; total_consumption: string; units_with_reading: number; reading_count: number }[];
    month_over_month?: { previous: string; current: string; change_pct: string | null; direction: string };
    note: string;
}
export interface EnergyAnomalies {
    anomalies: { unit_id: Id; unit_name: string; value: string; median: string; deviation_pct: string; severity: string; reason: string }[];
    basis: string; note: string;
}
export interface RiskAssessment {
    unit_id: Id; unit_name: string; risk_score: number; risk_category: string; total_assessments: number; unpaid: number;
    current_debt: string; longest_overdue_days: number; suggested_action: string; suggested_action_reason: string; reliable: boolean;
    factors: { code: string; points: number; detail: string }[];
}
export interface RiskReport { data: RiskAssessment[]; totals: Record<string, number>; method: string; note: string; action_note: string }
export interface NpsSurvey { id: Id; title: string; description?: string; status: string; starts_at: string; ends_at?: string; eligible_respondents: number; responses: number }
export interface NpsDetail {
    survey: NpsSurvey;
    result?: { nps_score: number; responses: number; promoters: number; passives: number; detractors: number; reliable: boolean; interpretation: string };
    participation_pct?: string; result_note?: string; method: string;
}
export interface EsgConsumption { from: string; to: string; consumption: { meter_type: string; total_consumption: string; meter_count: number; reading_count: number }[]; note: string }
export interface CarbonResult { lines: { meter_type: string; consumption: string; emission_factor: string; co2e_kg: string }[]; total_co2e_kg: string; method: string; note: string }

// ---------------------------------------------------------------- pano
export interface DashboardStats {
    totalResidents?: number; totalUnits?: number; pendingRequests?: number; period?: string;
    monthlyIncome?: number; monthlyAssessed?: number; collectionRate?: number;
}

/** Site görevlendirmesi (property_roles). */
export interface SiteRole {
    id: Id; user_id: Id; first_name: string; last_name: string; phone: string; role: string;
    valid_from: string; valid_to?: string; decision_ref: string; active: boolean; granted_by_name: string; granted_at: string;
}
export interface GrantRoleInput {
    phone: string; role: string; decision_ref?: string; valid_from?: string; valid_to?: string; first_name?: string; last_name?: string;
}

/** Toplu sakin içe aktarma satır sonucu. */
export interface BulkResidentRow {
    row: number; status: "created" | "linked" | "invited" | "error"; phone: string;
    resident_id?: Id; invitation_id?: Id; activation?: Activation; error?: string;
}

/** Açılış (devir) bakiyesi (034). */
export interface OpeningBalance {
    id: Id; unit_id: Id; unit: string; amount: number; paid_amount: number; due_date: string; description: string; status: string; created_at: string;
}
