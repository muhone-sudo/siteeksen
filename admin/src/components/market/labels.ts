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
export const SERVICE_AREA: Record<string, string> = { KM: "Yarıçap (km)", CITY: "Tüm il", COUNTRY: "Türkiye geneli" };
