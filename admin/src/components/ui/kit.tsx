"use client";

/**
 * Panelin ortak arayüz kiti.
 *
 * Neden: 30'a yakın modül ekranı aynı parçalardan oluşur (başlık, özet
 * kartları, tablo, form penceresi, durum rozeti). Her sayfa bunları ayrı
 * yazdığında davranışlar ayrışıyordu — ör. bir sayfa hata alınca uydurma veri
 * gösteriyor, diğeri sessizce boş liste gösteriyordu. Veri durumu (yükleniyor /
 * hata / boş) burada TEK biçimde ele alınır.
 */

import { ReactNode, useEffect } from "react";
import type { UseQueryResult } from "@tanstack/react-query";
import { X } from "lucide-react";
import { cn } from "@/lib/utils";
import { EmptyState, ErrorState, LoadingState, toUserMessage } from "@/components/ui/data-state";

// ---------------------------------------------------------------- sayfa
export function Page({
    title,
    description,
    actions,
    children,
}: {
    title: string;
    description?: ReactNode;
    actions?: ReactNode;
    children: ReactNode;
}) {
    return (
        <div className="space-y-6">
            <div className="flex flex-wrap items-start justify-between gap-3">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">{title}</h1>
                    {description && <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">{description}</p>}
                </div>
                {actions && <div className="flex flex-wrap items-center gap-2">{actions}</div>}
            </div>
            {children}
        </div>
    );
}

export function Card({
    title,
    actions,
    children,
    className,
    padded = true,
}: {
    title?: ReactNode;
    actions?: ReactNode;
    children: ReactNode;
    className?: string;
    padded?: boolean;
}) {
    return (
        <div className={cn("rounded-xl bg-white shadow-sm dark:bg-gray-800", className)}>
            {(title || actions) && (
                <div className="flex items-center justify-between gap-2 border-b border-gray-100 px-5 py-3 dark:border-gray-700">
                    <h3 className="font-semibold text-gray-900 dark:text-white">{title}</h3>
                    {actions && <div className="flex items-center gap-2">{actions}</div>}
                </div>
            )}
            <div className={padded ? "p-5" : undefined}>{children}</div>
        </div>
    );
}

// ---------------------------------------------------------------- özet kartları
export type Tone = "gray" | "blue" | "green" | "amber" | "red" | "purple";

const TONE_TEXT: Record<Tone, string> = {
    gray: "text-gray-900 dark:text-white",
    blue: "text-blue-600",
    green: "text-green-600",
    amber: "text-amber-600",
    red: "text-red-600",
    purple: "text-purple-600",
};

export function Stats({ items }: { items: { label: string; value: ReactNode; tone?: Tone; hint?: string }[] }) {
    return (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {items.map((s) => (
                <div key={s.label} className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
                    <p className="text-sm text-gray-500">{s.label}</p>
                    <p className={cn("mt-1 text-2xl font-bold", TONE_TEXT[s.tone ?? "gray"])}>{s.value}</p>
                    {s.hint && <p className="mt-1 text-xs text-gray-400">{s.hint}</p>}
                </div>
            ))}
        </div>
    );
}

// ---------------------------------------------------------------- rozet
const TONE_BADGE: Record<Tone, string> = {
    gray: "bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-200",
    blue: "bg-blue-100 text-blue-700",
    green: "bg-green-100 text-green-700",
    amber: "bg-amber-100 text-amber-800",
    red: "bg-red-100 text-red-700",
    purple: "bg-purple-100 text-purple-700",
};

export function Badge({ tone = "gray", children }: { tone?: Tone; children: ReactNode }) {
    return <span className={cn("inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium", TONE_BADGE[tone])}>{children}</span>;
}

/** Durum kodu → etiket ve renk. Tanımsız değer olduğu gibi (gri) gösterilir. */
export function StatusBadge({ value, map }: { value?: string | null; map: Record<string, [string, Tone]> }) {
    if (!value) return <Badge>—</Badge>;
    const [label, tone] = map[value] ?? [value, "gray" as Tone];
    return <Badge tone={tone}>{label}</Badge>;
}

// ---------------------------------------------------------------- düğme
export function Button({
    variant = "primary",
    size = "md",
    className,
    ...rest
}: React.ButtonHTMLAttributes<HTMLButtonElement> & { variant?: "primary" | "secondary" | "danger" | "ghost"; size?: "sm" | "md" }) {
    const v = {
        primary: "bg-primary text-white hover:bg-primary/90",
        secondary: "border border-gray-300 text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-200 dark:hover:bg-gray-700",
        danger: "bg-red-600 text-white hover:bg-red-700",
        ghost: "text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-700",
    }[variant];
    const s = size === "sm" ? "px-2.5 py-1 text-xs" : "px-4 py-2 text-sm";
    return (
        <button
            type={rest.type ?? "button"}
            className={cn("inline-flex items-center gap-1.5 rounded-lg font-medium disabled:cursor-not-allowed disabled:opacity-50", v, s, className)}
            {...rest}
        />
    );
}

// ---------------------------------------------------------------- bildirim kutusu
export function Notice({ tone = "blue", title, children }: { tone?: "blue" | "amber" | "red" | "green"; title?: string; children?: ReactNode }) {
    const c = {
        blue: "border-blue-200 bg-blue-50 text-blue-900",
        amber: "border-amber-200 bg-amber-50 text-amber-900",
        red: "border-red-200 bg-red-50 text-red-800",
        green: "border-green-200 bg-green-50 text-green-800",
    }[tone];
    return (
        <div role={tone === "red" ? "alert" : "note"} className={cn("rounded-lg border px-4 py-3 text-sm", c)}>
            {title && <p className="font-medium">{title}</p>}
            {children && <div className={title ? "mt-1" : undefined}>{children}</div>}
        </div>
    );
}

/** useAction sonucunu gösterir: hata kırmızı, başarı yeşil. */
export function ActionFeedback({ action }: { action: { error: string | null; message: string | null } }) {
    if (action.error) return <Notice tone="red">{action.error}</Notice>;
    if (action.message) return <Notice tone="green">{action.message}</Notice>;
    return null;
}

// ---------------------------------------------------------------- sorgu görünümü
/**
 * Veri durumunu tek biçimde işler. Hata alındığında UYDURMA VERİ GÖSTERİLMEZ;
 * hata ve yeniden deneme düğmesi gösterilir. Boş liste ile "alınamadı" ayrıdır.
 */
export function QueryView<T>({
    q,
    children,
    empty,
    isEmpty,
}: {
    q: UseQueryResult<T>;
    children: (data: T) => ReactNode;
    empty?: string;
    isEmpty?: (data: T) => boolean;
}) {
    if (q.isPending) return <LoadingState />;
    if (q.isError) return <ErrorState message={toUserMessage(q.error)} onRetry={() => void q.refetch()} />;
    const data = q.data as T;
    const blank = isEmpty ? isEmpty(data) : Array.isArray((data as { data?: unknown[] })?.data) && (data as { data: unknown[] }).data.length === 0;
    if (blank) return <EmptyState title={empty ?? "Kayıt yok"} />;
    // Sunucu güvenlik tavanında kestiyse (B69) bu, listeyi okuyan herkese söylenir.
    const cut = data as { truncated?: boolean; limit?: number };
    return (
        <>
            {cut?.truncated && (
                <p className="px-4 py-2 text-xs text-amber-700 dark:text-amber-400">
                    Yalnızca en yeni {cut.limit ?? ""} kayıt gösteriliyor; daha eskileri için süzgeç kullanın.
                </p>
            )}
            {children(data)}
        </>
    );
}

// ---------------------------------------------------------------- tablo
export interface Column<T> {
    header: string;
    cell: (row: T) => ReactNode;
    className?: string;
}

export function Table<T>({ rows, columns, rowKey }: { rows: T[]; columns: Column<T>[]; rowKey: (row: T) => string }) {
    return (
        <div className="overflow-x-auto">
            <table className="w-full text-sm">
                <thead>
                    <tr className="border-b border-gray-200 dark:border-gray-700">
                        {columns.map((c) => (
                            <th key={c.header} className={cn("px-4 py-2.5 text-left text-xs font-medium uppercase text-gray-500", c.className)}>
                                {c.header}
                            </th>
                        ))}
                    </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 dark:divide-gray-700">
                    {rows.map((r) => (
                        <tr key={rowKey(r)} className="hover:bg-gray-50 dark:hover:bg-gray-700/40">
                            {columns.map((c) => (
                                <td key={c.header} className={cn("px-4 py-2.5 align-top text-gray-700 dark:text-gray-200", c.className)}>
                                    {c.cell(r)}
                                </td>
                            ))}
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    );
}

// ---------------------------------------------------------------- pencere ve form
export function Modal({
    open,
    onClose,
    title,
    children,
    wide,
}: {
    open: boolean;
    onClose: () => void;
    title: string;
    children: ReactNode;
    wide?: boolean;
}) {
    useEffect(() => {
        if (!open) return;
        const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
        window.addEventListener("keydown", onKey);
        return () => window.removeEventListener("keydown", onKey);
    }, [open, onClose]);
    if (!open) return null;
    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4" role="dialog" aria-modal="true">
            <div className={cn("max-h-[90vh] w-full overflow-y-auto rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800", wide ? "max-w-3xl" : "max-w-lg")}>
                <div className="mb-4 flex items-center justify-between">
                    <h2 className="text-lg font-bold text-gray-900 dark:text-white">{title}</h2>
                    <button onClick={onClose} aria-label="Kapat" className="rounded p-1 hover:bg-gray-100 dark:hover:bg-gray-700">
                        <X className="h-5 w-5 text-gray-500" />
                    </button>
                </div>
                {children}
            </div>
        </div>
    );
}

export function FormModal({
    open,
    onClose,
    title,
    onSubmit,
    submitLabel = "Kaydet",
    pending,
    error,
    children,
    wide,
}: {
    open: boolean;
    onClose: () => void;
    title: string;
    onSubmit: () => void | Promise<void>;
    submitLabel?: string;
    pending?: boolean;
    error?: string | null;
    children: ReactNode;
    wide?: boolean;
}) {
    return (
        <Modal open={open} onClose={onClose} title={title} wide={wide}>
            <form
                className="space-y-4"
                onSubmit={(e) => {
                    e.preventDefault();
                    void onSubmit();
                }}
            >
                {error && <Notice tone="red">{error}</Notice>}
                {children}
                <div className="flex justify-end gap-2 pt-2">
                    <Button variant="secondary" onClick={onClose}>
                        Vazgeç
                    </Button>
                    <Button type="submit" disabled={pending}>
                        {pending ? "Kaydediliyor…" : submitLabel}
                    </Button>
                </div>
            </form>
        </Modal>
    );
}

const INPUT = "w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700";

export function Field({ label, hint, children, required }: { label: string; hint?: string; children: ReactNode; required?: boolean }) {
    return (
        <label className="block">
            <span className="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300">
                {label}
                {required && <span className="text-red-600"> *</span>}
            </span>
            {children}
            {hint && <span className="mt-1 block text-xs text-gray-500">{hint}</span>}
        </label>
    );
}

export function Input(props: React.InputHTMLAttributes<HTMLInputElement>) {
    return <input {...props} className={cn(INPUT, props.className)} />;
}

export function Textarea(props: React.TextareaHTMLAttributes<HTMLTextAreaElement>) {
    return <textarea rows={3} {...props} className={cn(INPUT, props.className)} />;
}

export function Select({
    options,
    placeholder,
    ...props
}: React.SelectHTMLAttributes<HTMLSelectElement> & { options: { value: string; label: string }[]; placeholder?: string }) {
    return (
        <select {...props} className={cn(INPUT, props.className)}>
            {placeholder !== undefined && <option value="">{placeholder}</option>}
            {options.map((o) => (
                <option key={o.value} value={o.value}>
                    {o.label}
                </option>
            ))}
        </select>
    );
}

export function Grid({ cols = 2, children }: { cols?: 2 | 3; children: ReactNode }) {
    return <div className={cn("grid gap-4", cols === 3 ? "sm:grid-cols-3" : "sm:grid-cols-2")}>{children}</div>;
}

// ---------------------------------------------------------------- sekmeler
export function Tabs<K extends string>({ tabs, value, onChange }: { tabs: { id: K; label: string }[]; value: K; onChange: (v: K) => void }) {
    return (
        <div className="flex flex-wrap gap-1 border-b border-gray-200 dark:border-gray-700">
            {tabs.map((t) => (
                <button
                    key={t.id}
                    onClick={() => onChange(t.id)}
                    className={cn(
                        "border-b-2 px-4 py-2.5 text-sm font-medium transition-colors",
                        value === t.id ? "border-primary text-primary" : "border-transparent text-gray-500 hover:text-gray-700"
                    )}
                >
                    {t.label}
                </button>
            ))}
        </div>
    );
}

/** "Yetki yok" satırı: denetçiye yazma düğmesi yerine neden gösterilir. */
export function ReadOnlyHint() {
    return <Notice tone="blue">Bu ekranda yalnızca okuma yetkiniz var (denetçi yazamaz — KMK m.41).</Notice>;
}

export { EmptyState };
