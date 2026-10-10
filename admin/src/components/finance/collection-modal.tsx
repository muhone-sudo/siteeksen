"use client";

// Yönetimin tahsilat girişi (061, beşinci tur B2): sakin uygulamadan bildirim yapmadan havale
// gönderdiğinde ya da yönetime elden ödediğinde tahsilat buradan girilir; ödeme aynı anda
// onaylanır ve tahsilat defterine yazılır. Ekstre satırından açıldığında gün ve tutar
// banka hareketinden gelir; seçilen borçların toplamı hareket tutarına eşit olmalıdır.

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { Field, FormModal, Input, Notice, Select } from "@/components/ui/kit";
import { date, kurus } from "@/lib/format";
import type { BankLine } from "@/lib/types";

type Form = { unit_id: string; ids: string[]; payment_method: "CASH" | "BANK_TRANSFER"; value_date: string; reference: string };

const today = () => new Date().toLocaleDateString("sv-SE");

export function CollectionModal({ open, onClose, line }: { open: boolean; onClose: () => void; line?: BankLine | null }) {
    const act = useAction();
    const units = useApi(["units"], api.identity.units, open);
    const [form, setForm] = useState<Form>({ unit_id: "", ids: [], payment_method: "BANK_TRANSFER", value_date: today(), reference: "" });
    const openList = useApi(["open-assessments", form.unit_id], () => api.finance.openAssessments(form.unit_id), open && !!form.unit_id);
    const rows = openList.data?.data ?? [];
    const selectedKurus = rows.filter((a) => form.ids.includes(a.id)).reduce((s, a) => s + a.outstanding_kurus, 0);
    const mismatch = !!line && form.ids.length > 0 && selectedKurus !== line.amount_kurus;
    const close = () => { setForm({ unit_id: "", ids: [], payment_method: "BANK_TRANSFER", value_date: today(), reference: "" }); onClose(); };
    const toggle = (id: string) => setForm({ ...form, ids: form.ids.includes(id) ? form.ids.filter((x) => x !== id) : [...form.ids, id] });

    return (
        <FormModal open={open} onClose={close} wide title={line ? "Banka hareketini daireye işle" : "Tahsilat gir"}
            submitLabel="Kaydet ve borçtan düş" pending={act.pending} error={act.error}
            onSubmit={async () => {
                if (!form.unit_id || form.ids.length === 0 || mismatch) return;
                const invalidate = ["payments", "debtors", "ledger", "open-assessments", "bank-imports", "dashboard"];
                const r = line
                    ? await act.run(() => api.finance.collectBankLine(line.id, { unit_id: form.unit_id, assessment_ids: form.ids }),
                        { invalidate, success: (x) => `${kurus(x.collection.amount_kurus)} daireye işlendi. Sakin bildirimi: ${x.notification?.note ?? "—"}` })
                    : await act.run(() => api.finance.recordCollection({ unit_id: form.unit_id, assessment_ids: form.ids, payment_method: form.payment_method, value_date: form.value_date, reference: form.reference }),
                        { invalidate, success: (x) => `${kurus(x.collection.amount_kurus)} tahsilat kaydedildi. Sakin bildirimi: ${x.notification?.note ?? "—"}` });
                if (r) close();
            }}>
            {line
                ? <Notice tone="blue">Hareket: {date(line.date)} · <b>{kurus(line.amount_kurus)}</b> · {line.description}. Seçtiğiniz borçların kalan toplamı bu tutara eşit olmalıdır; ödeme günü hareket günüdür.</Notice>
                : <Notice tone="blue">Sakinin bildirim yapmadığı havale/EFT ya da elden ödeme içindir. Kayıt silinemez; hata ancak gerekçeli ters kayıtla düzeltilir. Sakinin onay bekleyen bildirimi olan borç burada seçilemez — o bildirimi onaylayın.</Notice>}
            <Field label="Daire" required>
                <Select required value={form.unit_id} onChange={(e) => setForm({ ...form, unit_id: e.target.value, ids: [] })} placeholder="Seçin"
                    options={(units.data?.data ?? []).map((u) => ({ value: u.id, label: `${u.block}-${u.door_number}` }))} />
            </Field>
            {form.unit_id && (
                <div className="space-y-1">
                    <span className="block text-sm font-medium text-gray-700 dark:text-gray-300">Kapanacak borçlar <span className="text-red-600">*</span></span>
                    {openList.isLoading && <p className="text-sm text-gray-500">Yükleniyor…</p>}
                    {!openList.isLoading && rows.length === 0 && <p className="text-sm text-gray-500">Bu dairenin kalan borcu yok.</p>}
                    {rows.map((a) => (
                        <label key={a.id} className="flex items-center gap-2 rounded border px-3 py-2 text-sm dark:border-gray-600">
                            <input type="checkbox" checked={form.ids.includes(a.id)} onChange={() => toggle(a.id)} />
                            <span className="flex-1">{a.period} · vade {date(a.due_date)}</span>
                            <b>{kurus(a.outstanding_kurus)}</b>
                        </label>
                    ))}
                    {form.ids.length > 0 && (
                        <p className={`text-sm ${mismatch ? "text-red-600" : "text-gray-700 dark:text-gray-300"}`}>
                            Seçilen toplam: <b>{kurus(selectedKurus)}</b>{mismatch && ` — banka hareketi ${kurus(line!.amount_kurus)}; tutarlar eşit olmalı`}
                        </p>
                    )}
                </div>
            )}
            {!line && (
                <>
                    <Field label="Ödeme yöntemi" required>
                        <Select value={form.payment_method} onChange={(e) => setForm({ ...form, payment_method: e.target.value as Form["payment_method"] })}
                            options={[{ value: "BANK_TRANSFER", label: "Havale / EFT" }, { value: "CASH", label: "Elden (nakit)" }]} />
                    </Field>
                    <Field label="Ödeme günü" required hint="Paranın hesaba geçtiği ya da elden alındığı gün; ileri tarih olamaz.">
                        <Input type="date" required max={today()} value={form.value_date} onChange={(e) => setForm({ ...form, value_date: e.target.value })} />
                    </Field>
                    <Field label="Açıklama / makbuz no" hint="Ör. dekont no ya da elden verilen makbuzun numarası">
                        <Input maxLength={140} value={form.reference} onChange={(e) => setForm({ ...form, reference: e.target.value })} />
                    </Field>
                </>
            )}
        </FormModal>
    );
}
