/**
 * Biçimlendiriciler — tr-TR yerel ayarıyla.
 *
 * Kural: değer YOKSA "—" gösterilir, "0" değil. Bilinmeyen ile sıfır aynı şey
 * değildir; boş bir tutarı "₺0" göstermek "borç yok" demek olur.
 */

const TRY = new Intl.NumberFormat("tr-TR", { style: "currency", currency: "TRY", minimumFractionDigits: 2 });
const NUM = new Intl.NumberFormat("tr-TR", { maximumFractionDigits: 3 });

type Num = number | string | null | undefined;

function toNumber(v: Num): number | null {
    if (v === null || v === undefined || v === "") return null;
    const n = typeof v === "number" ? v : Number(String(v).replace(",", "."));
    return Number.isFinite(n) ? n : null;
}

export function tl(v: Num): string {
    const n = toNumber(v);
    return n === null ? "—" : TRY.format(n);
}

/** Kuruş (tam sayı) → TL. Sunucu yeni para alanlarını kuruş olarak döndürür. */
export function kurus(v: Num): string {
    const n = toNumber(v);
    return n === null ? "—" : TRY.format(n / 100);
}

export function num(v: Num): string {
    const n = toNumber(v);
    return n === null ? "—" : NUM.format(n);
}

export function pct(v: Num, digits = 0): string {
    const n = toNumber(v);
    return n === null ? "—" : `%${n.toFixed(digits)}`;
}

function toDate(v?: string | null): Date | null {
    if (!v) return null;
    const d = new Date(v);
    // Go'nun sıfır zamanı ("0001-01-01") "tarih yok" demektir.
    if (Number.isNaN(d.getTime()) || d.getFullYear() < 1900) return null;
    return d;
}

export function date(v?: string | null): string {
    const d = toDate(v);
    return d ? d.toLocaleDateString("tr-TR", { day: "2-digit", month: "2-digit", year: "numeric" }) : "—";
}

export function dateTime(v?: string | null): string {
    const d = toDate(v);
    return d
        ? d.toLocaleString("tr-TR", { day: "2-digit", month: "2-digit", year: "numeric", hour: "2-digit", minute: "2-digit" })
        : "—";
}

/** `<input type="date">` için bugünün tarihi (yerel). */
export function today(): string {
    const d = new Date();
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

/** `<input type="datetime-local">` değerini RFC3339'a çevirir (yerel saat dilimiyle). */
export function localToRFC3339(v: string): string {
    if (!v) return "";
    return new Date(v).toISOString();
}

export function bytes(v: Num): string {
    const n = toNumber(v);
    if (n === null) return "—";
    if (n < 1024) return `${n} B`;
    if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`;
    return `${(n / 1024 / 1024).toFixed(1)} MB`;
}
