"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import type { useAction } from "@/lib/use-api";
import { Field, FormModal, Grid, Input, Notice, Select, Textarea } from "@/components/ui/kit";
import type { Facility } from "@/lib/types";

const CATEGORIES = [
    { value: "MEETING_ROOM", label: "Toplantı salonu" }, { value: "POOL", label: "Havuz" }, { value: "GYM", label: "Spor salonu" },
    { value: "TENNIS", label: "Tenis kortu" }, { value: "BBQ", label: "Barbekü" }, { value: "SAUNA", label: "Sauna" }, { value: "OTHER", label: "Diğer" },
];
const DAYS = [[1, "Pzt"], [2, "Sal"], [3, "Çar"], [4, "Per"], [5, "Cum"], [6, "Cmt"], [0, "Paz"]] as const;

type Form = {
    name: string; description: string; category: string; capacity: string; is_paid: boolean; hourly_fee: string; daily_fee: string; deposit_amount: string;
    available_from: string; available_to: string; available_days: number[]; min_duration_minutes: string; max_duration_minutes: string;
    advance_booking_days: string; max_reservations_per_unit: string; buffer_minutes: string; cancellation_deadline_hours: string;
    requires_approval: boolean; rules: string; is_active: boolean; maintenance_mode: boolean; maintenance_note: string;
};

function toForm(f?: Facility): Form {
    const s = (v?: number) => (v === undefined || v === null ? "" : String(v));
    return {
        name: f?.name ?? "", description: f?.description ?? "", category: f?.category ?? "MEETING_ROOM", capacity: s(f?.capacity),
        is_paid: f?.is_paid ?? false, hourly_fee: s(f?.hourly_fee), daily_fee: s(f?.daily_fee), deposit_amount: s(f?.deposit_amount),
        available_from: f?.available_from ?? "08:00", available_to: f?.available_to ?? "22:00", available_days: f?.available_days ?? [0, 1, 2, 3, 4, 5, 6],
        min_duration_minutes: s(f?.min_duration_minutes ?? 60), max_duration_minutes: s(f?.max_duration_minutes ?? 240),
        advance_booking_days: s(f?.advance_booking_days ?? 14), max_reservations_per_unit: s(f?.max_reservations_per_unit ?? 2),
        buffer_minutes: s(f?.buffer_minutes ?? 0), cancellation_deadline_hours: s(f?.cancellation_deadline_hours ?? 0),
        requires_approval: f?.requires_approval ?? false, rules: f?.rules ?? "", is_active: f?.is_active ?? true,
        maintenance_mode: f?.maintenance_mode ?? false, maintenance_note: f?.maintenance_note ?? "",
    };
}

function toBody(f: Form): Record<string, unknown> {
    const n = (v: string) => (v === "" ? 0 : Number(v));
    return {
        ...f, capacity: n(f.capacity), hourly_fee: n(f.hourly_fee), daily_fee: n(f.daily_fee), deposit_amount: n(f.deposit_amount),
        min_duration_minutes: n(f.min_duration_minutes), max_duration_minutes: n(f.max_duration_minutes), advance_booking_days: n(f.advance_booking_days),
        max_reservations_per_unit: n(f.max_reservations_per_unit), buffer_minutes: n(f.buffer_minutes), cancellation_deadline_hours: n(f.cancellation_deadline_hours),
        // Onaylı tesiste sakin rezervasyonu otomatik onaylanmaz.
        auto_approve_residents: !f.requires_approval,
    };
}

/** Tesis ekleme / düzenleme (TEST_RAPORU 2.1). Kurallar sunucuda da denetlenir. */
export function FacilityForm({ facility, open, onClose, act }: { facility?: Facility; open: boolean; onClose: () => void; act: ReturnType<typeof useAction> }) {
    const [f, setF] = useState<Form>(() => toForm(facility));
    const num = (k: keyof Form, label: string, hint?: string, step = "1") => (
        <Field label={label} hint={hint}><Input type="number" min="0" step={step} value={f[k] as string} onChange={(e) => setF({ ...f, [k]: e.target.value })} /></Field>
    );
    const check = (k: "is_paid" | "requires_approval" | "is_active" | "maintenance_mode", label: string) => (
        <label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={f[k]} onChange={(e) => setF({ ...f, [k]: e.target.checked })} /> {label}</label>
    );

    return (
        <FormModal open={open} onClose={onClose} title={facility ? `Tesis düzenle — ${facility.name}` : "Yeni tesis"} wide pending={act.pending} error={act.error}
            onSubmit={async () => {
                const body = toBody(f);
                const r = facility
                    ? await act.run(() => api.reservations.updateFacility(facility.id, body), { invalidate: ["facilities"], success: (x) => x.note })
                    : await act.run(() => api.reservations.createFacility(body), { invalidate: ["facilities"], success: "Tesis eklendi; sakinler rezervasyon yapabilir" });
                if (r) onClose();
            }}>
            {facility && <Notice tone="blue">Değişiklikler yalnızca bundan sonraki rezervasyonlara uygulanır.</Notice>}
            <Grid cols={3}>
                <Field label="Ad" required><Input required value={f.name} onChange={(e) => setF({ ...f, name: e.target.value })} /></Field>
                <Field label="Kategori"><Select value={f.category} onChange={(e) => setF({ ...f, category: e.target.value })} options={CATEGORIES} /></Field>
                {num("capacity", "Kapasite (kişi)", "Boş = sınırsız")}
                <Field label="Açılış" required><Input type="time" required value={f.available_from} onChange={(e) => setF({ ...f, available_from: e.target.value })} /></Field>
                <Field label="Kapanış" required><Input type="time" required value={f.available_to} onChange={(e) => setF({ ...f, available_to: e.target.value })} /></Field>
                {num("advance_booking_days", "İleri tarih sınırı (gün)")}
                {num("min_duration_minutes", "En kısa süre (dk)")}
                {num("max_duration_minutes", "En uzun süre (dk)")}
                {num("buffer_minutes", "Tampon süre (dk)", "Rezervasyonlar arası temizlik/hazırlık")}
                {num("max_reservations_per_unit", "Haftalık kota (daire)", "0 = sınırsız")}
                {num("cancellation_deadline_hours", "İptal son süresi (saat)", "Sakin başlangıçtan en geç bu kadar önce iptal eder; 0 = serbest")}
            </Grid>
            <div>
                <p className="mb-1 text-sm font-medium text-gray-700 dark:text-gray-300">Açık günler</p>
                <div className="flex flex-wrap gap-3">
                    {DAYS.map(([d, label]) => (
                        <label key={d} className="flex items-center gap-1 text-sm">
                            <input type="checkbox" checked={f.available_days.includes(d)}
                                onChange={(e) => setF({ ...f, available_days: e.target.checked ? [...f.available_days, d] : f.available_days.filter((x) => x !== d) })} /> {label}
                        </label>
                    ))}
                </div>
            </div>
            <div className="grid gap-1 sm:grid-cols-2">
                {check("requires_approval", "Rezervasyon yönetim onayı gerektirir")}
                {check("is_paid", "Ücretli tesis")}
                {facility && check("is_active", "Kullanıma açık")}
                {facility && check("maintenance_mode", "Bakımda")}
            </div>
            {f.is_paid && (
                <Grid cols={3}>
                    {num("hourly_fee", "Saatlik ücret (TL)", undefined, "0.01")}
                    {num("daily_fee", "Günlük ücret (TL)", undefined, "0.01")}
                    {num("deposit_amount", "Depozito (TL)", undefined, "0.01")}
                </Grid>
            )}
            {f.is_paid && <Notice tone="amber">Ücret hesaplanır ancak tahsil edilmez; çevrimiçi tahsilat bağlı değilse sakin ödemeyi yönetime yapar.</Notice>}
            {f.maintenance_mode && <Field label="Bakım notu (sakinlere gösterilir)" required><Input required value={f.maintenance_note} onChange={(e) => setF({ ...f, maintenance_note: e.target.value })} /></Field>}
            <Field label="Açıklama"><Input value={f.description} onChange={(e) => setF({ ...f, description: e.target.value })} /></Field>
            <Field label="Kullanım kuralları"><Textarea value={f.rules} onChange={(e) => setF({ ...f, rules: e.target.value })} /></Field>
        </FormModal>
    );
}
