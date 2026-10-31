import { kurus } from "@/lib/format";
import type { MpSupplierRequest } from "@/lib/types";

/** Talebe uzaklık: metre/kilometre (site koordinatsızsa yok). */
export function distance(m?: number | null) {
    if (m == null) return null;
    return m < 1000 ? `${m} m` : `${(m / 1000).toFixed(1).replace(".", ",")} km`;
}

/** Kabul ücretinin tedarikçiye anlatımı (dahil talep hakkı ya da bakiyeden ücret). */
export function feeText(r: MpSupplierRequest) {
    if (r.accepted_at) return r.uses_included ? "Paket hakkından düştü" : `${kurus(r.fee_kurus)} ödendi`;
    return r.uses_included ? "Paketinizdeki talep hakkından düşer" : `Kabul ücreti ${kurus(r.fee_kurus)}`;
}
