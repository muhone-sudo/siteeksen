// Usta & Hizmet (FAZ M) durum ve tür etiketleri.
import type { Tone } from "@/components/ui/kit";

export const ACCOUNT_STATUS: Record<string, [string, Tone]> = {
    DRAFT: ["Taslak", "gray"], REVIEW: ["İncelemede", "amber"], APPROVED: ["Onaylı", "green"],
    SUSPENDED: ["Askıda", "red"], CLOSED: ["Kapalı", "gray"],
};
export const BUSINESS_STATUS: Record<string, [string, Tone]> = {
    DRAFT: ["Taslak", "gray"], REVIEW: ["İncelemede", "amber"], PUBLISHED: ["Yayında", "green"],
    REJECTED: ["Reddedildi", "red"], CLOSED: ["Kapalı", "gray"],
};
export const DOC_STATUS: Record<string, [string, Tone]> = {
    PENDING: ["İncelenecek", "amber"], APPROVED: ["Onaylandı", "green"], REJECTED: ["Reddedildi", "red"],
};
export const DOC_TYPE: Record<string, string> = {
    TAX_PLATE: "Vergi levhası", ID_CARD: "Kimlik belgesi", CHAMBER_RECORD: "Oda kaydı", OTHER: "Diğer",
};
export const REQUEST_STATUS: Record<string, [string, Tone]> = {
    OPEN: ["Açık", "green"], FULL: ["Doldu", "blue"], EXPIRED: ["Süresi doldu", "gray"], CLOSED: ["Kapandı", "gray"], CANCELLED: ["İptal", "gray"],
};
export const BUYER_TYPE: Record<string, string> = { RESIDENT: "Sakin (dairesi için)", MANAGEMENT: "Site yönetimi" };
export const OFFER_STATUS: Record<string, [string, Tone]> = {
    ACTIVE: ["Geçerli", "blue"], WITHDRAWN: ["Geri çekildi", "gray"], ACCEPTED: ["Seçildi", "green"], DECLINED: ["Seçilmedi", "gray"],
};
export const JOB_STATUS: Record<string, [string, Tone]> = {
    ACTIVE: ["Sürüyor", "blue"], DONE_CLAIMED: ["Tamamlandı (onay bekliyor)", "amber"], COMPLETED: ["Tamamlandı", "green"], DISPUTED: ["İtirazlı", "red"],
};
export const DISPUTE_STATUS: Record<string, [string, Tone]> = {
    OPEN: ["İncelenecek", "amber"], APPROVED: ["Onaylandı (iade)", "green"], REJECTED: ["Reddedildi", "red"],
};
export const DISPUTE_REASON: Record<string, string> = {
    FAKE: "Sahte talep", WRONG_CATEGORY: "Yanlış kategori", UNREACHABLE: "Alıcıya ulaşılamıyor", OTHER: "Diğer",
};
export const SERVICE_AREA: Record<string, string> = { KM: "Yarıçap (km)", CITY: "Tüm il", COUNTRY: "Türkiye geneli" };
