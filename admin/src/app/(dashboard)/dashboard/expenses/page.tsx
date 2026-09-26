"use client";

import { useState } from "react";
import { Plus } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Modal, Notice, Page, QueryView, ReadOnlyHint, Select, Stats, StatusBadge, Table, Textarea } from "@/components/ui/kit";
import { date, num, tl, today } from "@/lib/format";
import { DISTRIBUTION, EXPENSE_STATUS, opts } from "@/lib/labels";
import type { Expense } from "@/lib/types";

export default function ExpensesPage() {
    const now = new Date();
    const [year, setYear] = useState(now.getFullYear());
    const [status, setStatus] = useState("");
    const list = useApi(["expenses", year, status], () => api.expenses.list({ year, status }));
    const summary = useApi(["expenses", "summary", year], () => api.expenses.summary({ year }));
    const cats = useApi(["expense-categories"], api.expenses.categories);
    const act = useAction();
    const { canWrite } = useRoles();
    const [open, setOpen] = useState(false);
    const [detail, setDetail] = useState<string | null>(null);
    const detailQ = useApi(["expenses", "detail", detail], () => api.expenses.get(detail!), !!detail);
    const [rejecting, setRejecting] = useState<Expense | null>(null);
    const [reason, setReason] = useState("");
    const empty = { category_id: "", description: "", amount: "", expense_date: today(), is_invoiced: true, invoice_reason: "", vendor_name: "", invoice_number: "", distribution_type: "", notes: "" };
    const [form, setForm] = useState(empty);

    const s = summary.data;
    return (
        <Page
            title="Giderler"
            description="Gider kaydı, onay ve bağımsız bölümlere dağıtım. Onaylanan gider seçilen dağıtım kuralıyla paylaştırılır."
            actions={canWrite && <Button onClick={() => { setForm(empty); setOpen(true); }}><Plus className="h-4 w-4" /> Gider ekle</Button>}
        >
            {!canWrite && <ReadOnlyHint />}
            <ActionFeedback action={act} />
            <Stats items={[
                { label: `${year} toplam`, value: tl(s?.total_amount) },
                { label: "Faturalı", value: tl(s?.invoiced_amount), tone: "green" },
                { label: "Faturasız", value: tl(s?.non_invoiced_amount), tone: "amber" },
                { label: "Onay bekleyen", value: num(s?.pending_count), tone: "blue" },
            ]} />
            <Card padded={false} title="Gider kayıtları" actions={
                <div className="flex gap-2">
                    <Select value={String(year)} onChange={(e) => setYear(Number(e.target.value))} options={[0, 1, 2].map((d) => ({ value: String(now.getFullYear() - d), label: String(now.getFullYear() - d) }))} />
                    <Select value={status} onChange={(e) => setStatus(e.target.value)} options={opts(EXPENSE_STATUS)} placeholder="Tüm durumlar" />
                </div>
            }>
                <QueryView q={list} empty="Gider kaydı yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(e) => e.id} columns={[
                            { header: "Tarih", cell: (e) => date(e.expense_date) },
                            { header: "Açıklama", cell: (e) => <div><p className="font-medium">{e.description}</p><p className="text-xs text-gray-500">{e.category_name}{e.vendor_name ? ` · ${e.vendor_name}` : ""}</p></div> },
                            { header: "Tutar", cell: (e) => tl(e.amount) },
                            { header: "Fatura", cell: (e) => (e.is_invoiced ? <Badge tone="green">Var</Badge> : <Badge tone="amber">Yok</Badge>) },
                            { header: "Durum", cell: (e) => <StatusBadge value={e.status} map={EXPENSE_STATUS} /> },
                            { header: "", cell: (e) => (
                                <div className="flex gap-1">
                                    <Button size="sm" variant="ghost" onClick={() => setDetail(e.id)}>Dağıtım</Button>
                                    {canWrite && e.status === "PENDING" && (
                                        <>
                                            <Button size="sm" disabled={act.pending} onClick={() => act.run(() => api.expenses.approve(e.id), { invalidate: ["expenses"], success: "Gider onaylandı" })}>Onayla</Button>
                                            <Button size="sm" variant="danger" onClick={() => { setReason(""); setRejecting(e); }}>Reddet</Button>
                                        </>
                                    )}
                                </div>
                            ) },
                        ]} />
                    )}
                </QueryView>
            </Card>

            <FormModal open={open} onClose={() => setOpen(false)} title="Gider ekle" wide pending={act.pending} error={act.error}
                onSubmit={async () => {
                    const body: Record<string, unknown> = { ...form, amount: Number(form.amount) };
                    if (!form.distribution_type) delete body.distribution_type;
                    if (form.is_invoiced) delete body.invoice_reason;
                    const r = await act.run(() => api.expenses.create(body), { invalidate: ["expenses"], success: "Gider kaydedildi" });
                    if (r) setOpen(false);
                }}>
                <Grid>
                    <Field label="Gider kalemi" required>
                        <Select required value={form.category_id} onChange={(e) => setForm({ ...form, category_id: e.target.value })}
                            options={(cats.data?.data ?? []).map((c) => ({ value: c.id, label: c.name }))} placeholder="Seçin" />
                    </Field>
                    <Field label="Tutar (TL)" required><Input required type="number" step="0.01" min="0.01" value={form.amount} onChange={(e) => setForm({ ...form, amount: e.target.value })} /></Field>
                    <Field label="Gider tarihi" required><Input required type="date" value={form.expense_date} onChange={(e) => setForm({ ...form, expense_date: e.target.value })} /></Field>
                    <Field label="Dağıtım" hint="Boş bırakılırsa kalemin varsayılanı kullanılır.">
                        <Select value={form.distribution_type} onChange={(e) => setForm({ ...form, distribution_type: e.target.value })} options={DISTRIBUTION} placeholder="Kalem varsayılanı" />
                    </Field>
                    <Field label="Tedarikçi"><Input value={form.vendor_name} onChange={(e) => setForm({ ...form, vendor_name: e.target.value })} /></Field>
                    <Field label="Fatura">
                        <Select value={form.is_invoiced ? "1" : "0"} onChange={(e) => setForm({ ...form, is_invoiced: e.target.value === "1" })} options={[{ value: "1", label: "Faturalı" }, { value: "0", label: "Faturasız" }]} />
                    </Field>
                    {form.is_invoiced ? (
                        <Field label="Fatura no"><Input value={form.invoice_number} onChange={(e) => setForm({ ...form, invoice_number: e.target.value })} /></Field>
                    ) : (
                        <Field label="Faturasız gider gerekçesi" required><Input required value={form.invoice_reason} onChange={(e) => setForm({ ...form, invoice_reason: e.target.value })} /></Field>
                    )}
                </Grid>
                <Field label="Açıklama" required><Textarea required value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} /></Field>
            </FormModal>

            <FormModal open={!!rejecting} onClose={() => setRejecting(null)} title="Gideri reddet" submitLabel="Reddet" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!rejecting) return;
                    const r = await act.run(() => api.expenses.reject(rejecting.id, reason), { invalidate: ["expenses"], success: "Gider reddedildi" });
                    if (r) setRejecting(null);
                }}>
                <Field label="Gerekçe" required><Textarea required value={reason} onChange={(e) => setReason(e.target.value)} /></Field>
            </FormModal>

            <Modal open={!!detail} onClose={() => setDetail(null)} title="Dağıtım" wide>
                <QueryView q={detailQ} isEmpty={() => false}>
                    {(e) => (
                        <div className="space-y-3">
                            <p className="text-sm">{e.description} — <b>{tl(e.amount)}</b> ({e.distribution_type}){e.per_unit_amount !== undefined ? ` · daire başı ${tl(e.per_unit_amount)}` : ""}</p>
                            {e.distributions && e.distributions.length > 0 ? (
                                <Table rows={e.distributions} rowKey={(x) => x.unit_id} columns={[
                                    { header: "Daire", cell: (x) => x.unit_name ?? x.unit_id },
                                    { header: "Pay", cell: (x) => tl(x.amount) },
                                    { header: "Ödendi", cell: (x) => (x.is_paid ? "Evet" : "Hayır") },
                                ]} />
                            ) : (
                                <Notice tone="blue">Dağıtım, gider onaylandığında oluşturulur.</Notice>
                            )}
                        </div>
                    )}
                </QueryView>
            </Modal>
        </Page>
    );
}
