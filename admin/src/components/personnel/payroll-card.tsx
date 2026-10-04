"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Notice, QueryView, Select, Table, Textarea } from "@/components/ui/kit";
import { date, tl, today } from "@/lib/format";
import type { Employee, PayrollRow } from "@/lib/types";

const STATUS: Record<string, [string, "green" | "amber" | "gray"]> = { PAID: ["Ödendi", "green"], PENDING: ["Ödeme bekliyor", "amber"], CANCELLED: ["İptal", "gray"] };
const OPTIONAL = [["gross_salary", "Brüt ücret"], ["sgk_employee", "SGK işçi payı"], ["sgk_employer", "SGK işveren payı"], ["income_tax", "Gelir vergisi"], ["stamp_tax", "Damga vergisi"]] as const;

function thisMonth() {
    return today().slice(0, 7);
}

/**
 * Bordro kaydı (FAZ 7.4, kullanıcı kararı S-22): bordro mali müşavirden gelir; sistem
 * ücret/vergi/SGK HESAPLAMAZ, yalnızca net ödemeyi ve işveren maliyetini kaydeder.
 */
export function PayrollCard({ canWrite, employees }: { canWrite: boolean; employees: Employee[] }) {
    const [period, setPeriod] = useState(thisMonth());
    const q = useApi(["payroll", period], () => api.personnel.payroll(period));
    const act = useAction();
    const blank = { employee_id: "", net_salary: "", employer_cost: "", source_ref: "", payment_date: "", payment_reference: "", notes: "", gross_salary: "", sgk_employee: "", sgk_employer: "", income_tax: "", stamp_tax: "" };
    const [form, setForm] = useState<typeof blank | null>(null);
    const [pay, setPay] = useState<{ row: PayrollRow; payment_date: string; payment_reference: string } | null>(null);
    const [cancel, setCancel] = useState<{ row: PayrollRow; reason: string } | null>(null);

    return (
        <Card title="Bordro kayıtları" padded={false}
            actions={<div className="flex items-center gap-2">
                <Input type="month" value={period} max={thisMonth()} onChange={(e) => e.target.value && setPeriod(e.target.value)} aria-label="Dönem" />
                {canWrite && <Button size="sm" variant="secondary" onClick={() => setForm(blank)}>Bordro gir</Button>}
            </div>}>
            <ActionFeedback action={act} />
            <QueryView q={q}>
                {(d) => (
                    <>
                        <div className="grid gap-2 px-4 py-3 text-sm sm:grid-cols-3">
                            <p>Net ödeme: <b>{tl(d.totals.net)}</b></p>
                            <p>İşveren maliyeti: <b>{tl(d.totals.employer_cost)}</b></p>
                            <p>Ödenmemiş net: <b>{tl(d.totals.unpaid_net)}</b></p>
                        </div>
                        {d.missing.length > 0 && <div className="px-4"><Notice tone="amber">Bu dönemde çalışıp bordrosu girilmemiş: {d.missing.join(", ")}</Notice></div>}
                        {d.data.length === 0 ? <p className="px-4 py-3 text-sm text-gray-500">Bu dönem için bordro kaydı yok.</p> : <Table rows={d.data} rowKey={(r) => r.id} columns={[
                            { header: "Personel", cell: (r) => <><b>{r.employee_name}</b><div className="text-xs text-gray-500">{r.position}</div></> },
                            { header: "Net", cell: (r) => tl(r.net_salary) },
                            { header: "İşveren maliyeti", cell: (r) => tl(r.employer_cost) },
                            { header: "Kaynak", cell: (r) => <span className="text-xs">{r.source_ref}</span> },
                            { header: "Durum", cell: (r) => <><Badge tone={STATUS[r.payment_status][1]}>{STATUS[r.payment_status][0]}</Badge>{r.payment_date && <div className="text-xs text-gray-500">{date(r.payment_date)}</div>}{r.cancel_reason && <div className="text-xs text-gray-500">{r.cancel_reason}</div>}</> },
                            ...(canWrite ? [{ header: "", cell: (r: PayrollRow) => r.payment_status === "PENDING" ? (
                                <div className="flex gap-1">
                                    <Button size="sm" onClick={() => setPay({ row: r, payment_date: today(), payment_reference: "" })}>Ödendi</Button>
                                    <Button size="sm" variant="ghost" onClick={() => setCancel({ row: r, reason: "" })}>İptal</Button>
                                </div>
                            ) : null }] : []),
                        ]} />}
                        <p className="px-4 py-3 text-xs text-gray-500">{d.note}</p>
                    </>
                )}
            </QueryView>

            <FormModal open={!!form} onClose={() => setForm(null)} title={`Bordro gir — ${period}`} wide pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!form) return;
                    const body: Record<string, unknown> = { employee_id: form.employee_id, period, source_ref: form.source_ref, payment_date: form.payment_date || undefined, payment_reference: form.payment_reference, notes: form.notes };
                    for (const k of ["net_salary", "employer_cost", ...OPTIONAL.map(([k]) => k)] as const) if (form[k]) body[k] = Number(form[k]);
                    const r = await act.run(() => api.personnel.createPayroll(body), { invalidate: ["payroll"], success: (x) => (x.payment_status === "PAID" ? "Bordro ve ödeme kaydedildi" : "Bordro kaydedildi (ödeme bekliyor)") });
                    if (r) setForm(null);
                }}>
                {form && (<>
                    <Notice tone="blue">Tutarları mali müşavirin bordrosundan girin; sistem hesaplama ya da doğrulama yapmaz.</Notice>
                    <Grid cols={3}>
                        <Field label="Personel" required>
                            <Select required value={form.employee_id} onChange={(e) => setForm({ ...form, employee_id: e.target.value })} placeholder="Seçin"
                                options={employees.map((e) => ({ value: e.id, label: `${e.first_name} ${e.last_name}${e.is_active ? "" : " (ayrıldı)"}` }))} />
                        </Field>
                        <Field label="Net ödenen (TL)" required><Input type="number" min="0.01" step="0.01" required value={form.net_salary} onChange={(e) => setForm({ ...form, net_salary: e.target.value })} /></Field>
                        <Field label="İşveren maliyeti (TL)" required hint="Brüt + işveren SGK + işsizlik payı"><Input type="number" min="0.01" step="0.01" required value={form.employer_cost} onChange={(e) => setForm({ ...form, employer_cost: e.target.value })} /></Field>
                        {OPTIONAL.map(([k, label]) => (
                            <Field key={k} label={`${label} (TL)`}><Input type="number" min="0" step="0.01" value={form[k]} onChange={(e) => setForm({ ...form, [k]: e.target.value })} /></Field>
                        ))}
                        <Field label="Ödeme tarihi" hint="Boş bırakılırsa ödeme bekliyor"><Input type="date" max={today()} value={form.payment_date} onChange={(e) => setForm({ ...form, payment_date: e.target.value })} /></Field>
                    </Grid>
                    <Field label="Bordronun kaynağı" required hint="Mali müşavir, bordro / tahakkuk no"><Input required value={form.source_ref} onChange={(e) => setForm({ ...form, source_ref: e.target.value })} /></Field>
                    <Field label="Ödeme referansı"><Input value={form.payment_reference} onChange={(e) => setForm({ ...form, payment_reference: e.target.value })} /></Field>
                    <Field label="Not"><Textarea value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} /></Field>
                </>)}
            </FormModal>
            <FormModal open={!!pay} onClose={() => setPay(null)} title={`Ödeme — ${pay?.row.employee_name ?? ""}`} pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!pay) return;
                    const r = await act.run(() => api.personnel.payPayroll(pay.row.id, { payment_date: pay.payment_date, payment_reference: pay.payment_reference }), { invalidate: ["payroll"], success: "Ödeme kaydedildi" });
                    if (r) setPay(null);
                }}>
                {pay && (<Grid>
                    <Field label="Ödeme tarihi" required><Input type="date" required max={today()} value={pay.payment_date} onChange={(e) => setPay({ ...pay, payment_date: e.target.value })} /></Field>
                    <Field label="Referans"><Input value={pay.payment_reference} onChange={(e) => setPay({ ...pay, payment_reference: e.target.value })} /></Field>
                </Grid>)}
            </FormModal>
            <FormModal open={!!cancel} onClose={() => setCancel(null)} title="Bordro kaydını iptal et" submitLabel="İptal et" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!cancel) return;
                    const r = await act.run(() => api.personnel.cancelPayroll(cancel.row.id, cancel.reason), { invalidate: ["payroll"], success: "Kayıt iptal edildi" });
                    if (r) setCancel(null);
                }}>
                <Notice tone="blue">Kayıt silinmez; gerekçesiyle iptal edilmiş olarak kalır.</Notice>
                <Field label="Gerekçe" required><Textarea required value={cancel?.reason ?? ""} onChange={(e) => cancel && setCancel({ ...cancel, reason: e.target.value })} /></Field>
            </FormModal>
        </Card>
    );
}
