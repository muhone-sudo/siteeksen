import type { Tone } from "@/components/ui/kit";

/**
 * Sunucudaki durum/tür kodlarının Türkçe etiketleri ve rozet renkleri.
 * Anahtarlar arka ucun gerçek değerleridir (tasks/api-sozlesmesi.md).
 */
type Map = Record<string, [string, Tone]>;

export const REQUEST_STATUS: Map = {
    OPEN: ["Açık", "amber"], IN_PROGRESS: ["İşlemde", "blue"], RESOLVED: ["Çözüldü", "green"], CLOSED: ["Kapandı", "gray"],
};
export const PRIORITY: Map = { LOW: ["Düşük", "gray"], NORMAL: ["Normal", "blue"], HIGH: ["Yüksek", "amber"], URGENT: ["Acil", "red"] };
export const PAYMENT_STATUS: Map = {
    PENDING: ["Onay bekliyor", "amber"], COMPLETED: ["Tamamlandı", "green"], FAILED: ["Reddedildi", "red"], REFUNDED: ["İade", "gray"],
};
export const EXPENSE_STATUS: Map = { PENDING: ["Onay bekliyor", "amber"], APPROVED: ["Onaylandı", "green"], REJECTED: ["Reddedildi", "red"] };
export const LEAVE_STATUS: Map = { PENDING: ["Bekliyor", "amber"], APPROVED: ["Onaylandı", "green"], REJECTED: ["Reddedildi", "red"] };
export const VISITOR_STATUS: Map = {
    EXPECTED: ["Bekleniyor", "blue"], CHECKED_IN: ["İçeride", "green"], CHECKED_OUT: ["Çıktı", "gray"],
    CANCELLED: ["İptal", "red"], NO_SHOW: ["Gelmedi", "gray"],
};
export const RESERVATION_STATUS: Map = {
    PENDING: ["Onay bekliyor", "amber"], APPROVED: ["Onaylandı", "green"], REJECTED: ["Reddedildi", "red"],
    CANCELLED: ["İptal", "gray"], COMPLETED: ["Tamamlandı", "gray"],
};
export const PACKAGE_STATUS: Map = {
    RECEIVED: ["Teslim alındı", "amber"], NOTIFIED: ["Haber verildi", "blue"], DELIVERED: ["Teslim edildi", "green"], RETURNED: ["İade edildi", "gray"],
};
export const CONTRACT_STATUS: Map = {
    DRAFT: ["Taslak", "gray"], ACTIVE: ["Yürürlükte", "green"], EXPIRED: ["Süresi doldu", "amber"], TERMINATED: ["Feshedildi", "red"],
};
export const ASSET_CONDITION: Map = {
    NEW: ["Yeni", "green"], GOOD: ["İyi", "green"], FAIR: ["Orta", "amber"], POOR: ["Kötü", "red"], DISPOSED: ["Hurdaya ayrıldı", "gray"], LOST: ["Kayıp", "red"],
};
export const SURVEY_STATUS: Map = { DRAFT: ["Taslak", "gray"], ACTIVE: ["Oylamada", "green"], ENDED: ["Bitti", "blue"], CANCELLED: ["İptal", "red"] };
export const PATROL_STATUS: Map = { IN_PROGRESS: ["Sürüyor", "blue"], COMPLETED: ["Tamamlandı", "green"], INCOMPLETE: ["Eksik", "red"] };
export const BULLETIN_STATUS: Map = {
    PENDING: ["Onay bekliyor", "amber"], APPROVED: ["Yayında", "green"], REJECTED: ["Reddedildi", "red"], EXPIRED: ["Süresi doldu", "gray"], CLOSED: ["Kapatıldı", "gray"],
};
export const BUDGET_STATUS: Map = { DRAFT: ["Taslak", "gray"], NOTIFIED: ["Tebliğ edildi", "amber"], FINAL: ["Kesinleşti", "green"], CANCELLED: ["İptal", "red"] };
export const ASSEMBLY_STATUS: Map = { PLANNED: ["Planlandı", "gray"], NOTIFIED: ["Çağrı yapıldı", "blue"], HELD: ["Yapıldı", "green"], CANCELLED: ["İptal", "red"] };
export const DECISION_STATUS: Map = { PENDING: ["Karar bekliyor", "amber"], ACCEPTED: ["Kabul", "green"], REJECTED: ["Ret", "red"], POSTPONED: ["Ertelendi", "gray"] };
export const OBJECTION_STATUS: Map = { OPEN: ["Açık", "amber"], ACCEPTED: ["Kabul", "green"], REJECTED: ["Ret", "red"], WITHDRAWN: ["Geri çekildi", "gray"] };
export const CASE_STATUS: Map = {
    PREPARING: ["Hazırlanıyor", "gray"], FILED: ["Açıldı", "blue"], OBJECTED: ["İtiraz", "amber"], CONCLUDED: ["Sonuçlandı", "green"],
    COLLECTED: ["Tahsil edildi", "green"], WITHDRAWN: ["Geri çekildi", "gray"],
};
export const NOTIFY_STATUS: Map = { PENDING: ["Kuyrukta", "amber"], SENT: ["Gönderildi", "green"], FAILED: ["Başarısız", "red"], SUPPRESSED: ["Engellendi", "gray"] };
export const RISK: Map = { LOW: ["Düşük", "green"], MEDIUM: ["Orta", "amber"], HIGH: ["Yüksek", "red"], CRITICAL: ["Kritik", "red"] };

export const RESIDENT_ROLES = [
    { value: "OWNER", label: "Kat maliki" },
    { value: "TENANT", label: "Kiracı" },
    { value: "PROXY", label: "Vekil" },
];
export const ROLE_LABEL: Record<string, string> = { OWNER: "Kat maliki", TENANT: "Kiracı", PROXY: "Vekil" };

export const DISTRIBUTION = [
    { value: "EQUAL", label: "Eşit (KMK m.20/1-a)" },
    { value: "SHARE_RATIO", label: "Arsa payı (KMK m.20/1-b)" },
    { value: "AREA_M2", label: "Kullanım alanı (yönetim planı öngörürse)" },
];

export const METER_TYPES = [
    { value: "HEAT", label: "Isı (kalorimetre)" },
    { value: "WATER_COLD", label: "Soğuk su" },
    { value: "WATER_HOT", label: "Sıcak su" },
    { value: "GAS", label: "Doğalgaz" },
    { value: "ELECTRIC", label: "Elektrik" },
];

export const opts = (m: Map) => Object.entries(m).map(([value, [label]]) => ({ value, label }));
