"use client";

import { useState } from "react";
import { Plus, Trash2 } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Modal, Notice, Page, QueryView, ReadOnlyHint, Select, StatusBadge, Table, Tabs, Textarea } from "@/components/ui/kit";
import { date, kurus, tl } from "@/lib/format";
import { BUDGET_STATUS, DISTRIBUTION, OBJECTION_STATUS } from "@/lib/labels";
import type { BudgetItem } from "@/lib/types";

const NOTICE_METHODS = [
    { value: "IMZA_KARSILIGI", label: "İmza karşılığı elden" },
    { value: "TAAHHUTLU_MEKTUP", label: "Taahhütlü mektup" },
    { value: "ELEKTRONIK", label: "Elektronik (yönetim planı öngörüyorsa)" },
];

/**
 * İşletme projesi (KMK m.37). Akış: taslak → tebliğ (7 günlük itiraz süresi
 * başlar) → süre dolup açık itiraz kalmayınca kesinleşme. Kesinleşen proje
 * İİK m.68 anlamında belge niteliği kazanır (icra takibine dayanak).
 */
export default function BudgetsPage() {
    const list = useApi(["budgets"], api.governance.budgets);
    const act = useAction();
    const { canWrite } = useRoles();
    const [open, setOpen] = useState(false);
    const [form, setForm] = useState<{ period_year: number; note: string; items: (BudgetItem & { amountText: string })[] }>({
        period_year: new Date().getFullYear() + 1, note: "", items: [{ name: "", amount: 0, amountText: "", distribution_type: "SHARE_RATIO", kind: "EXPENSE" }],
    });
    const [selected, setSelected] = useState<string | null>(null);

    return (
        <Page title="İşletme projesi" description="Yıllık bütçe ve bağımsız bölüm başına düşen pay (KMK m.37, m.20)."
            actions={canWrite && <Button onClick={() => setOpen(true)}><Plus className="h-4 w-4" /> Proje hazırla</Button>}>
            {!canWrite && <ReadOnlyHint />}
            <ActionFeedback action={act} />
            <Card padded={false}>
                <QueryView q={list} empty="İşletme projesi yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(b) => b.id} columns={[
                            { header: "Yıl", cell: (b) => <b>{b.period_year}</b> },
                            { header: "Toplam", cell: (b) => tl(b.total_amount) },
                            { header: "Durum", cell: (b) => <StatusBadge value={b.status} map={BUDGET_STATUS} /> },
                            { header: "Tebliğ", cell: (b) => date(b.notified_at) },
                            { header: "İtiraz son gün", cell: (b) => date(b.objection_deadline) },
                            { header: "Kesinleşme", cell: (b) => date(b.finalized_at) },
                            { header: "", cell: (b) => <Button size="sm" variant="ghost" onClick={() => setSelected(b.id)}>Aç</Button> },
                        ]} />
                    )}
                </QueryView>
            </Card>

            <FormModal open={open} onClose={() => setOpen(false)} title="İşletme projesi hazırla" wide pending={act.pending} error={act.error}
                onSubmit={async () => {
                    const items = form.items.filter((i) => i.name && Number(i.amountText) > 0)
                        .map(({ amountText, ...i }) => ({ ...i, amount: Number(amountText) }));
                    const r = await act.run(() => api.governance.createBudget({ period_year: form.period_year, note: form.note, items }), {
                        invalidate: ["budgets"], success: (b) => `${b.period_year} projesi taslak olarak hazırlandı (${tl(b.total_amount)})`,
                    });
                    if (r) { setOpen(false); setSelected(r.id); }
                }}>
                <Grid>
                    <Field label="Dönem yılı" required><Input type="number" value={form.period_year} onChange={(e) => setForm({ ...form, period_year: Number(e.target.value) })} /></Field>
                    <Field label="Not"><Input value={form.note} onChange={(e) => setForm({ ...form, note: e.target.value })} /></Field>
                </Grid>
                <div className="space-y-2">
                    <p className="text-sm font-medium">Kalemler</p>
                    {form.items.map((it, i) => (
                        <div key={i} className="grid grid-cols-12 gap-2">
                            <Input className="col-span-4" placeholder="Kalem adı (ör. Kapıcı gideri)" value={it.name}
                                onChange={(e) => setForm({ ...form, items: form.items.map((x, j) => (j === i ? { ...x, name: e.target.value } : x)) })} />
                            <Input className="col-span-2" type="number" step="0.01" min="0" placeholder="Yıllık TL" value={it.amountText}
                                onChange={(e) => setForm({ ...form, items: form.items.map((x, j) => (j === i ? { ...x, amountText: e.target.value } : x)) })} />
                            <Select className="col-span-3" value={it.distribution_type} options={DISTRIBUTION}
                                onChange={(e) => setForm({ ...form, items: form.items.map((x, j) => (j === i ? { ...x, distribution_type: e.target.value } : x)) })} />
                            <Select className="col-span-2" value={it.kind ?? "EXPENSE"} options={[{ value: "EXPENSE", label: "Gider" }, { value: "INCOME", label: "Gelir" }]}
                                onChange={(e) => setForm({ ...form, items: form.items.map((x, j) => (j === i ? { ...x, kind: e.target.value } : x)) })} />
                            <Button className="col-span-1" variant="ghost" aria-label="Kalemi çıkar" onClick={() => setForm({ ...form, items: form.items.filter((_, j) => j !== i) })}><Trash2 className="h-4 w-4" /></Button>
                        </div>
                    ))}
                    <Button size="sm" variant="secondary" onClick={() => setForm({ ...form, items: [...form.items, { name: "", amount: 0, amountText: "", distribution_type: "SHARE_RATIO", kind: "EXPENSE" }] })}>+ Kalem</Button>
                </div>
                <Notice tone="blue">Kapıcı, kaloriferci, bahçıvan ve bekçi giderleri eşit; sigorta ve ortak yer bakım/onarım giderleri arsa payına göre paylaştırılır (KMK m.20). Paylar sunucuda kuruş hassasiyetinde hesaplanır.</Notice>
            </FormModal>

            {selected && <BudgetDetail id={selected} onClose={() => setSelected(null)} canWrite={canWrite} />}
        </Page>
    );
}

function BudgetDetail({ id, onClose, canWrite }: { id: string; onClose: () => void; canWrite: boolean }) {
    const q = useApi(["budgets", id], () => api.governance.budget(id));
    const objections = useApi(["budgets", id, "objections"], () => api.governance.objections(id));
    const act = useAction();
    const [tab, setTab] = useState<"items" | "shares" | "objections">("items");
    const [method, setMethod] = useState("TAAHHUTLU_MEKTUP");
    const [decisionRef, setDecisionRef] = useState("");
    const [resolving, setResolving] = useState<{ id: string; status: string } | null>(null);
    const [resolution, setResolution] = useState("");

    return (
        <Modal open onClose={onClose} title="İşletme projesi" wide>
            <QueryView q={q} isEmpty={() => false}>
                {(b) => (
                    <div className="space-y-4">
                        <div className="flex flex-wrap items-center gap-3 text-sm">
                            <b className="text-lg">{b.period_year}</b>
                            <StatusBadge value={b.status} map={BUDGET_STATUS} />
                            <span>Toplam {tl(b.total_amount)}</span>
                            {b.objection_deadline && <span>İtiraz son gün: {date(b.objection_deadline)}</span>}
                            {b.open_objections > 0 && <Badge tone="red">{b.open_objections} açık itiraz</Badge>}
                        </div>
                        <ActionFeedback action={act} />
                        {canWrite && b.status === "DRAFT" && (
                            <div className="flex flex-wrap items-end gap-2 rounded-lg bg-gray-50 p-3 dark:bg-gray-700/40">
                                <Field label="Tebliğ yöntemi"><Select value={method} onChange={(e) => setMethod(e.target.value)} options={NOTICE_METHODS} /></Field>
                                <Button disabled={act.pending} onClick={() => act.run(() => api.governance.notifyBudget(b.id, method), { invalidate: ["budgets"], success: "Tebliğ işlendi; 7 günlük itiraz süresi başladı (KMK m.37/2)" })}>Tebliğ et</Button>
                            </div>
                        )}
                        {canWrite && b.status === "NOTIFIED" && (
                            <div className="flex flex-wrap items-end gap-2 rounded-lg bg-gray-50 p-3 dark:bg-gray-700/40">
                                <Field label="Karar / tutanak referansı"><Input value={decisionRef} onChange={(e) => setDecisionRef(e.target.value)} /></Field>
                                <Button disabled={act.pending} onClick={() => act.run(() => api.governance.finalizeBudget(b.id, decisionRef), { invalidate: ["budgets"], success: "Proje kesinleşti" })}>Kesinleştir</Button>
                                <p className="text-xs text-gray-500">İtiraz süresi dolmadan ya da açık itiraz varken kesinleşmez.</p>
                            </div>
                        )}
                        <Tabs tabs={[{ id: "items", label: "Kalemler" }, { id: "shares", label: "Daire payları" }, { id: "objections", label: "İtirazlar" }]} value={tab} onChange={setTab} />
                        {tab === "items" && (
                            <Table rows={b.items ?? []} rowKey={(i) => i.id ?? i.name} columns={[
                                { header: "Kalem", cell: (i) => i.name },
                                { header: "Tutar", cell: (i) => tl(i.amount) },
                                { header: "Dağıtım", cell: (i) => DISTRIBUTION.find((d) => d.value === i.distribution_type)?.label ?? i.distribution_type },
                                { header: "Tür", cell: (i) => (i.kind === "INCOME" ? <Badge tone="green">Gelir</Badge> : "Gider") },
                            ]} />
                        )}
                        {tab === "shares" && (
                            <Table rows={b.unit_shares ?? []} rowKey={(s) => s.unit_id} columns={[
                                { header: "Daire", cell: (s) => s.unit_name ?? s.unit_id },
                                { header: "Yıllık", cell: (s) => kurus(s.annual_kurus) },
                                { header: "Aylık", cell: (s) => <b>{kurus(s.monthly_kurus)}</b> },
                                { header: "Döküm", cell: (s) => <span className="text-xs text-gray-500">{Object.entries(s.breakdown ?? {}).map(([k, v]) => `${k}: ${kurus(v)}`).join(" · ")}</span> },
                            ]} />
                        )}
                        {tab === "objections" && (
                            <QueryView q={objections} empty="İtiraz yok">
                                {(o) => (
                                    <Table rows={o.data} rowKey={(x) => x.id} columns={[
                                        { header: "Tarih", cell: (x) => date(x.submitted_at) },
                                        { header: "Gerekçe", cell: (x) => x.reason },
                                        { header: "Süresinde", cell: (x) => (x.in_time ? <Badge tone="green">Evet</Badge> : <Badge tone="amber">Süre dışı</Badge>) },
                                        { header: "Durum", cell: (x) => <StatusBadge value={x.status} map={OBJECTION_STATUS} /> },
                                        { header: "", cell: (x) => canWrite && x.status === "OPEN" ? (
                                            <div className="flex gap-1">
                                                <Button size="sm" onClick={() => { setResolution(""); setResolving({ id: x.id, status: "ACCEPTED" }); }}>Kabul</Button>
                                                <Button size="sm" variant="danger" onClick={() => { setResolution(""); setResolving({ id: x.id, status: "REJECTED" }); }}>Ret</Button>
                                            </div>
                                        ) : null },
                                    ]} />
                                )}
                            </QueryView>
                        )}
                        <FormModal open={!!resolving} onClose={() => setResolving(null)} title={resolving?.status === "ACCEPTED" ? "İtirazı kabul et" : "İtirazı reddet"} pending={act.pending} error={act.error}
                            onSubmit={async () => {
                                if (!resolving) return;
                                const r = await act.run(() => api.governance.resolveObjection(b.id, resolving.id, resolving.status, resolution), { invalidate: ["budgets"], success: "İtiraz sonuçlandırıldı" });
                                if (r) setResolving(null);
                            }}>
                            <Field label="Karar açıklaması"><Textarea value={resolution} onChange={(e) => setResolution(e.target.value)} /></Field>
                        </FormModal>
                    </div>
                )}
            </QueryView>
        </Modal>
    );
}
