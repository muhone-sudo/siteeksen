"use client";

import { useState } from "react";
import { Plus } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Page, QueryView, ReadOnlyHint, Select, Stats, StatusBadge, Table, Textarea } from "@/components/ui/kit";
import { date, num, tl, today } from "@/lib/format";
import { CONTRACT_STATUS, opts } from "@/lib/labels";
import type { Contract } from "@/lib/types";

const TYPES = [
    { value: "SERVICE", label: "Hizmet" }, { value: "MAINTENANCE", label: "Bakım" }, { value: "RENTAL", label: "Kira" },
    { value: "EMPLOYMENT", label: "İş" }, { value: "INSURANCE", label: "Sigorta" }, { value: "OTHER", label: "Diğer" },
];
const TYPE_LABEL = Object.fromEntries(TYPES.map((t) => [t.value, t.label]));

export default function ContractsPage() {
    const [status, setStatus] = useState("");
    const list = useApi(["contracts", status], () => api.contracts.list({ status }));
    const summary = useApi(["contracts", "summary"], api.contracts.summary);
    const act = useAction();
    const { canWrite } = useRoles();
    const [open, setOpen] = useState(false);
    const blank = { contract_type: "SERVICE", title: "", party_name: "", party_phone: "", party_email: "", start_date: today(), end_date: "", auto_renew: false, renewal_period_months: "", renewal_notice_days: "30", payment_type: "MONTHLY", monthly_amount: "", yearly_amount: "", notes: "" };
    const [form, setForm] = useState(blank);
    const [terminating, setTerminating] = useState<Contract | null>(null);
    const [reason, setReason] = useState("");
    const s = summary.data?.summary;

    return (
        <Page title="Sözleşmeler" description="Hizmet, bakım, sigorta ve kira sözleşmeleri; bitiş ve ihbar süresi takibi."
            actions={canWrite && (
                <>
                    <Button variant="secondary" disabled={act.pending} onClick={() => act.run(() => api.contracts.expireDue(), { invalidate: ["contracts"], success: (r) => `${r.expired_count} sözleşme süresi doldu olarak işaretlendi` })}>Süresi dolanları işle</Button>
                    <Button onClick={() => { setForm(blank); setOpen(true); }}><Plus className="h-4 w-4" /> Sözleşme ekle</Button>
                </>
            )}>
            {!canWrite && <ReadOnlyHint />}
            <ActionFeedback action={act} />
            <Stats items={[
                { label: "Yürürlükte", value: num(s?.active), tone: "green" },
                { label: "İhbar süresi içinde", value: num(s?.notice_due), tone: "red", hint: "Otomatik yenilenmeden önce karar gerekir" },
                { label: "30 gün içinde bitecek", value: num(s?.expiring_in_30_days), tone: "amber" },
                { label: "Aylık taahhüt", value: tl(s?.monthly_commitment_try) },
            ]} />
            <Card padded={false} title="Sözleşmeler" actions={<Select value={status} onChange={(e) => setStatus(e.target.value)} options={opts(CONTRACT_STATUS)} placeholder="Tüm durumlar" />}>
                <QueryView q={list} empty="Sözleşme yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(c) => c.id} columns={[
                            { header: "Sözleşme", cell: (c) => <div><p className="font-medium">{c.title}</p><p className="text-xs text-gray-500">{TYPE_LABEL[c.contract_type] ?? c.contract_type} · {c.party_name}</p></div> },
                            { header: "Dönem", cell: (c) => `${date(c.start_date)} – ${date(c.end_date)}` },
                            { header: "Kalan", cell: (c) => (c.days_remaining !== undefined ? `${c.days_remaining} gün` : "—") },
                            { header: "Yenileme", cell: (c) => (c.auto_renew ? <Badge tone="blue">Otomatik ({c.renewal_period_months} ay)</Badge> : "—") },
                            { header: "Tutar", cell: (c) => (c.monthly_amount ? `${tl(c.monthly_amount)}/ay` : c.yearly_amount ? `${tl(c.yearly_amount)}/yıl` : "—") },
                            { header: "Durum", cell: (c) => <div className="flex flex-col gap-1"><StatusBadge value={c.status} map={CONTRACT_STATUS} />{c.notice_due && <Badge tone="red">İhbar süresi</Badge>}</div> },
                            { header: "", cell: (c) => canWrite && (c.status === "ACTIVE" || c.status === "EXPIRED") ? (
                                <div className="flex gap-1">
                                    {c.auto_renew || c.renewal_period_months ? <Button size="sm" variant="ghost" disabled={act.pending} onClick={() => act.run(() => api.contracts.renew(c.id), { invalidate: ["contracts"], success: "Sözleşme yenilendi" })}>Yenile</Button> : null}
                                    <Button size="sm" variant="ghost" onClick={() => { setReason(""); setTerminating(c); }}>Feshet</Button>
                                </div>
                            ) : null },
                        ]} />
                    )}
                </QueryView>
            </Card>

            <FormModal open={open} onClose={() => setOpen(false)} title="Sözleşme ekle" wide pending={act.pending} error={act.error}
                onSubmit={async () => {
                    const body: Record<string, unknown> = { ...form };
                    for (const k of ["renewal_period_months", "renewal_notice_days"]) body[k] = form[k as "renewal_notice_days"] ? Number(form[k as "renewal_notice_days"]) : undefined;
                    for (const k of ["monthly_amount", "yearly_amount"]) body[k] = form[k as "monthly_amount"] ? Number(form[k as "monthly_amount"]) : undefined;
                    if (!form.end_date) delete body.end_date;
                    const r = await act.run(() => api.contracts.create(body), { invalidate: ["contracts"], success: "Sözleşme kaydedildi" });
                    if (r) setOpen(false);
                }}>
                <Grid cols={3}>
                    <Field label="Tür" required><Select value={form.contract_type} onChange={(e) => setForm({ ...form, contract_type: e.target.value })} options={TYPES} /></Field>
                    <Field label="Başlık" required><Input required value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} /></Field>
                    <Field label="Karşı taraf" required><Input required value={form.party_name} onChange={(e) => setForm({ ...form, party_name: e.target.value })} /></Field>
                    <Field label="Başlangıç" required><Input type="date" required value={form.start_date} onChange={(e) => setForm({ ...form, start_date: e.target.value })} /></Field>
                    <Field label="Bitiş"><Input type="date" value={form.end_date} onChange={(e) => setForm({ ...form, end_date: e.target.value })} /></Field>
                    <Field label="İhbar süresi (gün)"><Input type="number" value={form.renewal_notice_days} onChange={(e) => setForm({ ...form, renewal_notice_days: e.target.value })} /></Field>
                    <Field label="Otomatik yenileme"><Select value={form.auto_renew ? "1" : "0"} onChange={(e) => setForm({ ...form, auto_renew: e.target.value === "1" })} options={[{ value: "0", label: "Hayır" }, { value: "1", label: "Evet" }]} /></Field>
                    <Field label="Yenileme süresi (ay)"><Input type="number" value={form.renewal_period_months} onChange={(e) => setForm({ ...form, renewal_period_months: e.target.value })} /></Field>
                    <Field label="Ödeme"><Select value={form.payment_type} onChange={(e) => setForm({ ...form, payment_type: e.target.value })} options={[{ value: "MONTHLY", label: "Aylık" }, { value: "YEARLY", label: "Yıllık" }, { value: "ONE_TIME", label: "Tek sefer" }]} /></Field>
                    <Field label="Aylık tutar (TL)"><Input type="number" step="0.01" value={form.monthly_amount} onChange={(e) => setForm({ ...form, monthly_amount: e.target.value })} /></Field>
                    <Field label="Yıllık tutar (TL)"><Input type="number" step="0.01" value={form.yearly_amount} onChange={(e) => setForm({ ...form, yearly_amount: e.target.value })} /></Field>
                    <Field label="Telefon"><Input value={form.party_phone} onChange={(e) => setForm({ ...form, party_phone: e.target.value })} /></Field>
                </Grid>
                <Field label="Not"><Textarea value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} /></Field>
            </FormModal>
            <FormModal open={!!terminating} onClose={() => setTerminating(null)} title="Sözleşmeyi feshet" submitLabel="Feshet" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!terminating) return;
                    const r = await act.run(() => api.contracts.terminate(terminating.id, reason), { invalidate: ["contracts"], success: "Fesih kaydedildi" });
                    if (r) setTerminating(null);
                }}>
                <Field label="Gerekçe" required><Textarea required value={reason} onChange={(e) => setReason(e.target.value)} /></Field>
            </FormModal>
        </Page>
    );
}
