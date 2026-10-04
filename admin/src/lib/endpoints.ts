/**
 * Panelin kullandığı TÜM arka uç çağrıları — tek yerde, sözleşmeyle birebir
 * (tasks/api-sozlesmesi.md).
 *
 * NEDEN VAR (2026-09-26): önceki api-client'taki yöntemlerin ~20'si arka uçta
 * olmayan yollara istek atıyordu; sayfalar "sunucu hazır değil" diyordu, oysa
 * sunucu hazırdı — istemci yanlış adresi çağırıyordu. Bu dosya:
 *   - Yalnızca gerçekten var olan yolları içerir,
 *   - `READS` listesiyle panelin okuduğu her uç için sayfaların kullandığı
 *     alanları sabitler. `admin/scripts/verify-endpoints.ts` bu listeyi gerçek
 *     gateway'e karşı çalıştırır: yol ya da alan adı kayarsa doğrulama düşer.
 *
 * Yalnızca göreli içe aktarma kullanılır (doğrulama betiği Node ile doğrudan çalıştırır).
 */
import type * as T from "./types";

type Q = Record<string, unknown>;

export interface Http {
    get<R>(url: string, params?: Q): Promise<R>;
    post<R>(url: string, body?: unknown): Promise<R>;
    put<R>(url: string, body?: unknown): Promise<R>;
    patch<R>(url: string, body?: unknown): Promise<R>;
    del<R>(url: string, body?: unknown): Promise<R>;
    upload<R>(url: string, form: FormData): Promise<R>;
    download(url: string, fallbackName: string): Promise<void>;
}

type Msg = { message?: string; note?: string };

export function endpoints(http: Http) {
    const g = <R>(u: string, q?: Q) => http.get<R>(u, q);
    return {
        dashboard: {
            stats: () => g<{ data: T.DashboardStats; unavailable: { source: string; reason: string }[] | null; partial: boolean }>("/dashboard/stats"),
            recentPayments: () => g<{ data: T.Payment[] }>("/dashboard/recent-payments"),
            recentRequests: () => g<{ data: T.ServiceRequest[] }>("/dashboard/recent-requests"),
        },
        identity: {
            properties: () => g<T.UserProperty[] | null>("/users/me/properties"),
            createProperty: (b: { name: string; type: string; address: string; city: string; district?: string }) =>
                http.post<{ id: string; name: string }>("/users/me/properties", b),
            setActiveProperty: (property_id: string) => http.post<Msg>("/users/me/active-property", { property_id }),
            residents: (q?: { search?: string; block?: string; role?: string }) => g<T.List<T.Resident>>("/residents", q),
            createResident: (b: { first_name: string; last_name: string; phone: string; email?: string; unit_id: string; role: string }) =>
                http.post<T.CreateResidentResult>("/residents", b),
            updateResident: (id: string, b: { role?: string; is_active?: boolean }) => http.patch<T.Resident>(`/residents/${id}`, b),
            issueActivationCode: (id: string) => http.post<T.Activation>(`/residents/${id}/activation-code`),
            invitations: () => g<T.List<T.Invitation>>("/residents/invitations"),
            bulkResidents: (residents: { first_name: string; last_name: string; phone: string; unit_id: string; role: string }[]) =>
                http.post<{ data: T.BulkResidentRow[]; summary: Record<string, number>; note: string }>("/residents/bulk", { residents }),
            siteRoles: () => g<T.List<T.SiteRole>>("/property-roles"),
            grantRole: (b: T.GrantRoleInput) => http.post<{ role: T.SiteRole; activation?: T.Activation; note?: string }>("/property-roles", b),
            endRole: (id: string) => http.post<{ role: T.SiteRole; note?: string }>(`/property-roles/${id}/end`),
            cancelInvitation: (id: string) => http.post<T.Invitation>(`/residents/invitations/${id}/cancel`),
            changePassword: (current_password: string, new_password: string) =>
                http.post<Msg>("/users/me/password", { current_password, new_password }),
            /** Oturum gerektirmez: kodla ilk şifre belirleme ya da sıfırlama. */
            activate: (phone: string, code: string, new_password: string) =>
                http.post<Msg>("/auth/activate", { phone, code, new_password }),
            units: () => g<T.List<T.Unit>>("/units"),
            createUnits: (units: T.UnitInput[]) => http.post<{ data: T.Unit[]; created: number }>("/units", { units }),
            updateUnit: (id: string, b: T.UnitInput) => http.patch<T.Unit>(`/units/${id}`, b),
        },
        finance: {
            overview: (year?: number) => g<T.List<T.AssessmentPeriod>>("/finance/assessments/overview", { year }),
            debtors: () => g<T.List<T.Debtor>>("/finance/debtors"),
            payments: (limit = 50) => g<T.Paged<T.Payment>>(`/finance/payments?limit=${limit}`),
            openingBalances: () => g<T.List<T.OpeningBalance>>("/finance/opening-balances"),
            createOpeningBalances: (b: { due_date: string; items: { unit_id: string; amount: number; description?: string }[] }) =>
                http.post<{ data: T.OpeningBalance[]; created: number; note: string }>("/finance/opening-balances", b),
            cancelOpeningBalance: (id: string) => http.post<Msg>(`/finance/opening-balances/${id}/cancel`),
            pendingPayments: () => g<T.List<T.Payment>>("/finance/payments/pending"),
            categories: () => g<T.List<T.FinanceCategory>>("/finance/expense-categories"),
            createAssessment: (b: { period_year: number; period_month: number; due_date: string; expense_items: { category_id: string; amount: number }[] }) =>
                http.post<{ data: unknown[] }>("/finance/assessments", b),
            confirmPayment: (id: string, reference?: string) => http.post<Msg>(`/finance/payments/${id}/confirm`, { reference }),
            rejectPayment: (id: string) => http.post<Msg>(`/finance/payments/${id}/reject`),
            accrueLateFees: (as_of?: string) => http.post<T.LateFeeRun>("/finance/late-fees/accrue", as_of ? { as_of } : {}),
        },
        requests: {
            list: (status?: string) => g<T.List<T.ServiceRequest>>("/requests", { status }),
            setStatus: (id: string, status: string) => http.patch<T.ServiceRequest>(`/requests/${id}/status`, { status }),
        },
        announcements: {
            list: (q?: { category?: string; include_expired?: string }) => g<T.List<T.Announcement>>("/announcements", q),
            create: (b: { title: string; content: string; category: string; priority: string; is_pinned?: boolean; expires_at?: string }) =>
                http.post<{ id: string; notification: T.BroadcastResult }>("/announcements", b),
            pin: (id: string, pinned: boolean) => http.post<{ is_pinned: boolean }>(`/announcements/${id}/pin`, { pinned }),
            readStats: (id: string) => g<{ stats: { total_residents: number; read_count: number; unread_count: number }; note: string }>(`/announcements/${id}/read-stats`),
        },
        notifications: {
            outbox: (q?: { status?: string; channel?: string }) => g<T.List<T.Notification>>("/notifications/outbox", q),
            summary: () => g<{ summary: T.NotificationSummary; delivery: unknown }>("/notifications/summary"),
            mine: () => g<T.List<T.Notification>>("/notifications"),
            preferences: () => g<{ data: T.Preference[]; note: string }>("/notification-preferences"),
            setPreference: (b: { channel: string; category: string; enabled: boolean; consent_source?: string }) =>
                http.put<Msg & { consent_note?: string }>("/notification-preferences", b),
            send: (b: { recipient_user_id: string; channel: string; category: string; subject?: string; body: string }) =>
                http.post<{ notification: { id: string; status: string; reason?: string } }>("/notifications", b),
        },
        expenses: {
            categories: () => g<T.List<T.ExpenseCategory>>("/expense-categories"),
            list: (q?: { year?: number; month?: number; status?: string; category_id?: string }) => g<T.List<T.Expense>>("/expenses", q),
            summary: (q?: { year?: number; month?: number }) => g<T.ExpenseSummary>("/expenses/summary", q),
            get: (id: string) => g<T.Expense>(`/expenses/${id}`),
            create: (b: Record<string, unknown>) => http.post<{ expense: T.Expense; note?: string }>("/expenses", b),
            approve: (id: string) => http.post<Msg>(`/expenses/${id}/approve`),
            reject: (id: string, reason: string) => http.post<Msg>(`/expenses/${id}/reject`, { reason }),
        },
        personnel: {
            list: (all?: boolean) => g<T.List<T.Employee>>("/employees", { all: all ? "true" : undefined }),
            summary: () => g<T.PersonnelSummary>("/employees/summary"),
            get: (id: string, reveal?: boolean) => g<T.Employee>(`/employees/${id}`, { reveal: reveal ? "true" : undefined }),
            create: (b: Record<string, unknown>) => http.post<T.Employee>("/employees", b),
            terminate: (id: string, reason: string, end_date?: string) => http.post<Msg>(`/employees/${id}/terminate`, { reason, end_date }),
            leaves: (status?: string) => g<T.List<T.Leave>>("/leaves", { status }),
            createLeave: (b: { employee_id: string; leave_type: string; start_date: string; end_date: string; reason?: string }) =>
                http.post<{ id: string }>("/leaves", b),
            approveLeave: (id: string) => http.post<Msg>(`/leaves/${id}/approve`),
            rejectLeave: (id: string, reason: string) => http.post<Msg>(`/leaves/${id}/reject`, { reason }),
        },
        visitors: {
            list: (q?: { status?: string; inside?: string }) => g<T.List<T.Visitor>>("/visitors", q),
            summary: () => g<T.VisitorSummary>("/visitors/summary"),
            create: (b: Record<string, unknown>) => http.post<{ id: string; note?: string }>("/visitors", b),
            checkIn: (id: string) => http.post<Msg & { notification?: T.BroadcastResult }>(`/visitors/${id}/check-in`),
            checkOut: (id: string) => http.post<Msg>(`/visitors/${id}/check-out`),
            cancel: (id: string) => http.post<Msg>(`/visitors/${id}/cancel`),
        },
        parking: {
            vehicles: () => g<T.List<T.Vehicle>>("/vehicles"),
            createVehicle: (b: Record<string, unknown>) => http.post<{ id: string }>("/vehicles", b),
            deactivateVehicle: (id: string) => http.del<Msg>(`/vehicles/${id}`),
            zones: () => g<T.List<T.ParkingZone>>("/parking-zones"),
            logs: (inside?: boolean) => g<T.List<T.ParkingLog>>("/parking-logs", { inside: inside ? "true" : undefined }),
            entry: (b: { plate: string; parking_zone_id?: string; entry_gate?: string }) =>
                http.post<{ id: string; is_resident_vehicle: boolean }>("/parking-logs/entry", b),
            exit: (id: string) => http.post<{ duration_minutes: number; calculated_fee: number; note?: string }>(`/parking-logs/${id}/exit`),
        },
        reservations: {
            facilities: () => g<T.List<T.Facility>>("/facilities"),
            list: (q?: { status?: string; facility_id?: string }) => g<T.List<T.Reservation>>("/reservations", q),
            approve: (id: string) => http.post<Msg & { notification?: T.BroadcastResult }>(`/reservations/${id}/approve`),
            reject: (id: string, reason: string) => http.post<Msg>(`/reservations/${id}/reject`, { reason }),
            cancel: (id: string, reason?: string) => http.post<Msg>(`/reservations/${id}/cancel`, { reason }),
        },
        packages: {
            list: (q?: { status?: string; pending?: string }) => g<T.List<T.Package>>("/packages", q),
            summary: () => g<T.PackageSummary>("/packages-summary"),
            create: (b: Record<string, unknown>) => http.post<{ id: string; notification?: T.BroadcastResult; note?: string }>("/packages", b),
            notify: (id: string) => http.post<Msg>(`/packages/${id}/notify`, { method: "MANUAL" }),
            deliver: (id: string, delivered_to_name: string) => http.post<Msg>(`/packages/${id}/deliver`, { delivered_to_name }),
            returnToCarrier: (id: string, reason: string) => http.post<Msg>(`/packages/${id}/return`, { reason }),
        },
        contracts: {
            summary: () => g<{ summary: T.ContractSummary; note: string }>("/contracts-summary"),
            list: (q?: { type?: string; status?: string; expiring_days?: number }) => g<T.List<T.Contract>>("/contracts", q),
            create: (b: Record<string, unknown>) => http.post<{ id: string; note?: string }>("/contracts", b),
            renew: (id: string) => http.post<{ contract: T.Contract; note?: string }>(`/contracts/${id}/renew`),
            terminate: (id: string, reason: string) => http.post<Msg>(`/contracts/${id}/terminate`, { reason }),
            expireDue: () => http.post<{ expired_count: number; note?: string }>("/contracts/expire-due"),
        },
        documents: {
            list: (q?: { category?: string; include_archived?: string }) => g<T.List<T.DocumentRec> & { visible_levels: string[] }>("/documents", q),
            summary: () => g<T.DocumentSummary>("/documents-summary"),
            upload: (form: FormData) => http.upload<{ id: string; sha256: string; note?: string }>("/documents", form),
            download: (id: string, name: string) => http.download(`/documents/${id}/download`, name),
            archive: (id: string, reason: string) => http.post<Msg>(`/documents/${id}/archive`, { reason }),
            accessLog: (id: string) => g<T.List<T.AccessLogEntry>>(`/documents/${id}/access-log`),
        },
        assets: {
            categories: () => g<T.List<T.AssetCategory>>("/asset-categories"),
            list: (q?: { status?: string; maintenance_due?: string; include_disposed?: string }) => g<T.List<T.Asset>>("/assets", q),
            summary: () => g<T.AssetSummary>("/assets-summary"),
            get: (id: string) => g<{ asset: T.Asset; depreciation?: { accumulated: string; book_value: string; annual_amount: string; fully_depreciated: boolean }; depreciation_note?: string }>(`/assets/${id}`),
            maintenance: (id: string) => g<T.List<T.Maintenance>>(`/assets/${id}/maintenance`),
            create: (b: Record<string, unknown>) => http.post<{ id: string; note?: string }>("/assets", b),
            addMaintenance: (id: string, b: Record<string, unknown>) => http.post<{ id: string; total_cost: number; note?: string }>(`/assets/${id}/maintenance`, b),
            dispose: (id: string, b: { reason: string; decision_ref: string }) => http.post<Msg>(`/assets/${id}/dispose`, b),
            createCategory: (b: { name: string; depreciation_years?: number }) => http.post<{ id: string }>("/asset-categories", b),
        },
        inventory: {
            categories: () => g<T.List<{ id: string; name: string; item_count: number }>>("/inventory-categories"),
            list: (q?: { q?: string; below_minimum?: string }) => g<T.List<T.InventoryItem>>("/inventory", q),
            summary: () => g<T.InventorySummary>("/inventory-summary"),
            movements: (limit = 100) => g<T.List<T.InventoryMovement>>("/inventory-movements", { limit }),
            create: (b: Record<string, unknown>) => http.post<{ id: string; note?: string }>("/inventory", b),
            move: (id: string, b: Record<string, unknown>) => http.post<{ movement: { new_stock: string; below_minimum: boolean }; warning?: string }>(`/inventory/${id}/movements`, b),
            deactivate: (id: string, reason: string) => http.del<Msg>(`/inventory/${id}`, { reason }),
        },
        surveys: {
            list: (status?: string) => g<T.List<T.Survey> & { legal_notice: string }>("/surveys", { status }),
            get: (id: string) => g<{ survey: T.Survey; results_visible: boolean; legal_notice: string; results_note?: string }>(`/surveys/${id}`),
            create: (b: Record<string, unknown>) => http.post<{ id: string; note?: string; legal_notice?: string }>("/surveys", b),
            publish: (id: string) => http.post<{ status: string; notification?: T.BroadcastResult }>(`/surveys/${id}/publish`),
            close: (id: string) => http.post<{ status: string }>(`/surveys/${id}/close`),
            cancel: (id: string, reason: string) => http.post<{ status: string }>(`/surveys/${id}/cancel`, { reason }),
        },
        meters: {
            list: (q?: { meter_type?: string; unit_id?: string; include_inactive?: string }) => g<T.List<T.Meter> & { valid_types: string[] }>("/meters", q),
            readings: (q?: { meter_id?: string; from?: string; to?: string }) => g<T.List<T.MeterReading>>("/meter-readings", q),
            addReading: (b: { meter_id: string; current_value: string; reading_date?: string; reading_type?: string; meter_replaced?: boolean; reason?: string }) =>
                http.post<{ reading: T.MeterReading; note?: string }>("/meter-readings", b),
            create: (b: { unit_id: string; meter_type: string; serial_number: string; brand?: string }) => http.post<{ id: string }>("/meters", b),
            deactivate: (id: string) => http.del<Msg>(`/meters/${id}`),
            allocate: (b: { meter_type: string; from: string; to: string; total_amount_try: number }) =>
                http.post<{ allocation: T.Allocation; basis_note: string; note: string; warning?: string }>("/consumption/allocate", b),
        },
        patrol: {
            summary: () => g<{ summary: T.PatrolSummary; warning?: string }>("/patrols-summary"),
            list: (q?: { status?: string }) => g<T.List<T.Patrol>>("/patrols", q),
            checkpoints: () => g<T.List<T.Checkpoint>>("/patrol-checkpoints"),
            routes: () => g<T.List<T.PatrolRoute>>("/patrol-routes"),
            createCheckpoint: (b: Record<string, unknown>) => http.post<{ id: string; note?: string }>("/patrol-checkpoints", b),
            createRoute: (b: Record<string, unknown>) => http.post<{ id: string }>("/patrol-routes", b),
        },
        bulletins: {
            list: (q?: { status?: string; category?: string }) => g<T.List<T.BulletinPost> & { categories: string[] }>("/bulletins", q),
            summary: () => g<T.BulletinSummary>("/bulletins-summary"),
            approve: (id: string) => http.post<Msg>(`/bulletins/${id}/approve`),
            reject: (id: string, reason: string) => http.post<Msg>(`/bulletins/${id}/reject`, { reason }),
            close: (id: string) => http.post<Msg>(`/bulletins/${id}/close`),
            expireDue: () => http.post<{ expired_count: number }>("/bulletins/expire-due"),
        },
        settings: {
            list: () => g<{ data: T.Setting[]; note: string }>("/settings"),
            definitions: () => g<{ data: T.SettingDef[] }>("/settings/definitions"),
            set: (key: string, value: unknown) => http.put<{ setting: T.Setting }>(`/settings/${key}`, { value }),
            reset: (key: string) => http.del<Msg>(`/settings/${key}`),
            history: (key?: string) => g<T.List<T.SettingHistory>>("/settings-history", { key }),
        },
        governance: {
            budgets: () => g<T.List<T.Budget>>("/governance/budgets"),
            budget: (id: string) => g<T.Budget>(`/governance/budgets/${id}`),
            createBudget: (b: { period_year: number; items: T.BudgetItem[]; note?: string }) => http.post<T.Budget>("/governance/budgets", b),
            notifyBudget: (id: string, method: string) => http.post<T.Budget>(`/governance/budgets/${id}/notify`, { method }),
            finalizeBudget: (id: string, decision_ref?: string) => http.post<{ budget: T.Budget; note: string }>(`/governance/budgets/${id}/finalize`, { decision_ref }),
            objections: (id: string) => g<T.List<T.Objection>>(`/governance/budgets/${id}/objections`),
            resolveObjection: (budgetId: string, id: string, status: string, resolution?: string) =>
                http.patch<Msg>(`/governance/budgets/${budgetId}/objections/${id}`, { status, resolution }),
            assemblies: () => g<T.List<T.Assembly>>("/governance/assemblies"),
            assembly: (id: string) => g<T.Assembly>(`/governance/assemblies/${id}`),
            createAssembly: (b: { kind: string; call_number: number; scheduled_at: string; location?: string; agenda_items: { title: string; description?: string; required_majority_code?: string }[] }) =>
                http.post<T.Assembly>("/governance/assemblies", b),
            notifyAssembly: (id: string, method: string) => http.post<Msg>(`/governance/assemblies/${id}/notify`, { method }),
            addAttendee: (id: string, b: { unit_id: string; attendance_type?: string; proxy_holder_id?: string }) =>
                http.post<Msg>(`/governance/assemblies/${id}/attendees`, b),
            quorum: (id: string) => g<T.Quorum>(`/governance/assemblies/${id}/quorum`),
            attendees: (id: string) => g<T.List<T.Attendee>>(`/governance/assemblies/${id}/attendees`),
            hold: (id: string) => http.post<T.Quorum>(`/governance/assemblies/${id}/hold`),
            vote: (itemId: string, unit_id: string, vote: string) => http.post<Msg>(`/governance/agenda-items/${itemId}/votes`, { unit_id, vote }),
            closeItem: (itemId: string, decision_text?: string) => http.post<T.MajorityResult & { book_entry?: T.BookEntry; note?: string }>(`/governance/agenda-items/${itemId}/close`, { decision_text }),
            ensureBook: (kind: string, year: number) => http.post<T.Book>(`/governance/books?kind=${encodeURIComponent(kind)}&year=${year}`),
            entries: (bookId: string) => g<T.List<T.BookEntry>>(`/governance/books/${bookId}/entries`),
            addEntry: (bookId: string, b: { title: string; body: string; entry_date?: string }) => http.post<T.BookEntry>(`/governance/books/${bookId}/entries`, b),
            verifyBook: (bookId: string) => g<T.BookIntegrity>(`/governance/books/${bookId}/verify`),
            closeBook: (bookId: string, b: { notary_ref?: string; closed_at?: string; period_year?: number }) =>
                http.post<{ message: string; warning?: string }>(`/governance/books/${bookId}/close`, b),
            legalCases: () => g<T.List<T.LegalCase>>("/governance/legal-cases"),
            createLegalCase: (b: Record<string, unknown>) => http.post<{ case: T.LegalCase | null; warning?: string }>("/governance/legal-cases", b),
        },
        analytics: {
            energyTrends: (meter_type: string, months = 12) => g<T.EnergyTrends>("/energy/trends", { meter_type, months }),
            energyAnomalies: (meter_type: string) => g<T.EnergyAnomalies>("/energy/anomalies", { meter_type }),
            risk: () => g<T.RiskReport>("/collection/risk"),
            riskSnapshot: () => http.post<{ saved: number; skipped: number; note: string }>("/collection/risk/snapshot"),
            nps: () => g<T.List<T.NpsSurvey>>("/nps"),
            npsDetail: (id: string) => g<T.NpsDetail>(`/nps/${id}`),
            npsComments: (id: string) => g<T.List<{ score?: number; comment: string; created_at: string }> & { note: string }>(`/nps/${id}/comments`),
            createNps: (b: { title: string; description?: string; ends_at?: string }) => http.post<{ id: string; note?: string }>("/nps", b),
            closeNps: (id: string) => http.post<{ status: string }>(`/nps/${id}/close`),
            esgConsumption: (q?: { from?: string; to?: string }) => g<T.EsgConsumption>("/esg/consumption", q),
            carbon: (b: { from?: string; to?: string; emission_factors: Record<string, number>; emission_factor_source: string }) =>
                http.post<T.CarbonResult>("/esg/carbon-footprint", b),
        },
    };
}

export type Api = ReturnType<typeof endpoints>;

/**
 * Panelin OKUDUĞU her uç ve sayfaların kullandığı alanlar.
 * `list: true` → yanıt {data:[...]} ve ilk öğede `keys` aranır (liste boşsa
 * yalnızca sarmalayıcı denetlenir). Aksi hâlde `keys` üst düzeyde aranır.
 * `roles`: bu ucu okuyabilen panel rolü (doğrulama yönetici jetonuyla yapılır).
 */
export const READS: { path: string; keys: string[]; list?: boolean }[] = [
    { path: "/dashboard/stats", keys: ["data", "partial"] },
    { path: "/dashboard/recent-payments", keys: ["data"] },
    { path: "/dashboard/recent-requests", keys: ["data"] },
    { path: "/residents", keys: ["id", "first_name", "last_name", "phone", "unit", "role", "is_active"], list: true },
    { path: "/residents/invitations", keys: ["data"] },
    { path: "/property-roles", keys: ["id", "role", "first_name", "active", "decision_ref"], list: true },
    { path: "/units", keys: ["id", "block", "door_number", "share_ratio"], list: true },
    { path: "/finance/assessments/overview", keys: ["period", "total_amount", "collected_amount", "rate"], list: true },
    { path: "/finance/debtors", keys: ["unit_id", "resident_id", "name", "unit", "amount"], list: true },
    { path: "/finance/payments", keys: ["id", "amount", "status", "name", "unit", "created_at"], list: true },
    { path: "/finance/payments/pending", keys: ["id", "amount", "status"], list: true },
    { path: "/finance/opening-balances", keys: ["data"] },
    { path: "/finance/expense-categories", keys: ["id", "name", "distribution_type"], list: true },
    { path: "/requests", keys: ["id", "ticket_number", "title", "status", "priority", "created_at"], list: true },
    { path: "/announcements", keys: ["id", "title", "category", "priority", "is_pinned", "published_at"], list: true },
    { path: "/notifications/outbox", keys: ["id", "channel", "status", "created_at"], list: true },
    { path: "/notifications/summary", keys: ["summary"] },
    { path: "/notification-preferences", keys: ["data"] },
    { path: "/expense-categories", keys: ["id", "name", "distribution_type"], list: true },
    { path: "/expenses", keys: ["id", "description", "amount", "status", "expense_date"], list: true },
    { path: "/expenses/summary", keys: ["total_amount", "pending_count", "by_category"] },
    { path: "/employees", keys: ["id", "first_name", "last_name", "position", "is_active", "salary_visible"], list: true },
    { path: "/employees/summary", keys: ["total_active", "pending_leaves", "by_position"] },
    { path: "/leaves", keys: ["id", "leave_type", "start_date", "end_date", "status"], list: true },
    { path: "/visitors", keys: ["id", "visitor_name", "status", "created_at"], list: true },
    { path: "/visitors/summary", keys: ["currently_inside", "today_expected"] },
    { path: "/vehicles", keys: ["id", "plate", "owner_type", "is_active"], list: true },
    { path: "/parking-zones", keys: ["id", "name", "capacity", "available_spots"], list: true },
    { path: "/parking-logs", keys: ["id", "plate", "entry_at"], list: true },
    { path: "/facilities", keys: ["id", "name", "requires_approval"], list: true },
    { path: "/reservations", keys: ["id", "facility_name", "start_time", "end_time", "status"], list: true },
    { path: "/packages", keys: ["id", "recipient_name", "status", "received_at"], list: true },
    { path: "/packages-summary", keys: ["pending", "delivered", "waiting_over_7_days"] },
    { path: "/contracts-summary", keys: ["summary"] },
    { path: "/contracts", keys: ["id", "title", "party_name", "status", "notice_due"], list: true },
    { path: "/documents", keys: ["id", "title", "category", "visibility", "size_bytes"], list: true },
    { path: "/documents-summary", keys: ["total", "by_category"] },
    { path: "/asset-categories", keys: ["id", "name", "asset_count"], list: true },
    { path: "/assets", keys: ["id", "name", "condition", "status"], list: true },
    { path: "/assets-summary", keys: ["total", "maintenance_overdue"] },
    { path: "/inventory-categories", keys: ["id", "name"], list: true },
    { path: "/inventory", keys: ["id", "name", "unit", "current_stock", "below_minimum"], list: true },
    { path: "/inventory-summary", keys: ["item_count", "below_minimum", "total_value_try"] },
    { path: "/inventory-movements", keys: ["id", "movement_type", "quantity", "created_at"], list: true },
    { path: "/surveys", keys: ["id", "title", "status", "total_votes"], list: true },
    { path: "/meters", keys: ["id", "meter_type", "serial_number", "is_active"], list: true },
    { path: "/meter-readings", keys: ["id", "reading_date", "current_value", "consumption"], list: true },
    { path: "/patrols-summary", keys: ["summary"] },
    { path: "/patrols", keys: ["id", "status", "started_at"], list: true },
    { path: "/patrol-checkpoints", keys: ["id", "name"], list: true },
    { path: "/patrol-routes", keys: ["id", "name", "checkpoints"], list: true },
    { path: "/bulletins", keys: ["id", "title", "status", "category"], list: true },
    { path: "/bulletins-summary", keys: ["pending_review", "approved"] },
    { path: "/settings", keys: ["data"] },
    { path: "/settings/definitions", keys: ["data"] },
    { path: "/settings-history", keys: ["key", "new_value", "changed_at"], list: true },
    { path: "/governance/budgets", keys: ["id", "period_year", "status", "total_amount"], list: true },
    { path: "/governance/assemblies", keys: ["id", "kind", "scheduled_at", "status"], list: true },
    { path: "/governance/legal-cases", keys: ["id", "case_type", "status", "principal_kurus"], list: true },
    { path: "/energy/trends?meter_type=HEAT", keys: ["periods", "note"] },
    { path: "/energy/anomalies?meter_type=HEAT", keys: ["anomalies", "basis"] },
    { path: "/collection/risk", keys: ["data", "totals", "method"] },
    { path: "/nps", keys: ["id", "title", "status"], list: true },
    { path: "/esg/consumption", keys: ["consumption", "note"] },
];
