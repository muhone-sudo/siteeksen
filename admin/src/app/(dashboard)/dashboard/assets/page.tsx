"use client";

import { useState } from "react";
import { Plus } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Modal, Notice, Page, QueryView, Select, Stats, StatusBadge, Table, Textarea } from "@/components/ui/kit";
import { date, num, tl, today } from "@/lib/format";
import { ASSET_CONDITION, opts } from "@/lib/labels";
import type { Asset } from "@/lib/types";

const MTYPES = [
    { value: "PREVENTIVE", label: "Periyodik (önleyici)" },
    { value: "CORRECTIVE", label: "Arıza (düzeltici)" },
    { value: "INSPECTION", label: "Muayene / kontrol" },
];

/**
 * Demirbaş kaydı, amortisman (doğrusal, kuruş hassasiyetinde) ve bakım geçmişi.
 * Hurdaya ayırma kurul kararı referansı ister.
 */
export default function AssetsPage() {
    const [due, setDue] = useState(false);
    const list = useApi(["assets", due], () => api.assets.list({ maintenance_due: due ? "true" : undefined }));
    const summary = useApi(["assets", "summary"], api.assets.summary);
    const cats = useApi(["asset-categories"], api.assets.categories);
    const act = useAction();
    const { canWrite, roles } = useRoles();
    const canMaintain = canWrite || roles.includes("STAFF");
    const [open, setOpen] = useState(false);
    const blank = { name: "", category_id: "", asset_code: "", serial_number: "", location: "", purchase_date: "", purchase_price: "", vendor: "", warranty_end: "", depreciation_years: "", condition: "GOOD", maintenance_interval_days: "", notes: "" };
    const [form, setForm] = useState(blank);
    const [detail, setDetail] = useState<Asset | null>(null);
    const detailQ = useApi(["assets", "detail", detail?.id], () => api.assets.get(detail!.id), !!detail);
    const history = useApi(["assets", "maint", detail?.id], () => api.assets.maintenance(detail!.id), !!detail);
    const [maint, setMaint] = useState<null | Record<string, string>>(null);
    const [disposing, setDisposing] = useState<Asset | null>(null);
    const [dispose, setDispose] = useState({ reason: "", decision_ref: "" });
    const s = summary.data;

    return (
        <Page title="Demirbaş" description="Ortak alan demirbaşları, amortisman ve bakım takibi."
            actions={canWrite && <Button onClick={() => { setForm(blank); setOpen(true); }}><Plus className="h-4 w-4" /> Demirbaş ekle</Button>}>
            <ActionFeedback action={act} />
            <Stats items={[
                { label: "Aktif demirbaş", value: num(s?.active) },
                { label: "Bakımı gecikmiş", value: num(s?.maintenance_overdue), tone: "red" },
                { label: "Garantisi 30 günde biten", value: num(s?.warranty_expiring_30_days), tone: "amber" },
                { label: "Bu yıl bakım gideri", value: tl(s?.maintenance_cost_ytd_try) },
            ]} />
            <Card padded={false} title="Demirbaşlar" actions={<label className="flex items-center gap-1 text-sm"><input type="checkbox" checked={due} onChange={(e) => setDue(e.target.checked)} /> Yalnız bakımı gelenler</label>}>
                <QueryView q={list} empty="Demirbaş yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(a) => a.id} columns={[
                            { header: "Demirbaş", cell: (a) => <div><p className="font-medium">{a.name}</p><p className="text-xs text-gray-500">{[a.asset_code, a.category_name, a.location].filter(Boolean).join(" · ")}</p></div> },
                            { header: "Alış", cell: (a) => (a.purchase_price ? `${tl(a.purchase_price)} (${date(a.purchase_date)})` : "—") },
                            { header: "Defter değeri", cell: (a) => tl(a.book_value) },
                            { header: "Sonraki bakım", cell: (a) => a.maintenance_overdue_days ? <Badge tone="red">{a.maintenance_overdue_days} gün gecikti</Badge> : date(a.next_maintenance_date) },
                            { header: "Durum", cell: (a) => <StatusBadge value={a.condition} map={ASSET_CONDITION} /> },
                            { header: "", cell: (a) => <Button size="sm" variant="ghost" onClick={() => setDetail(a)}>Aç</Button> },
                        ]} />
                    )}
                </QueryView>
            </Card>

            <FormModal open={open} onClose={() => setOpen(false)} title="Demirbaş ekle" wide pending={act.pending} error={act.error}
                onSubmit={async () => {
                    const body: Record<string, unknown> = { ...form };
                    for (const k of ["purchase_price"]) body[k] = form.purchase_price ? Number(form.purchase_price) : undefined;
                    for (const k of ["depreciation_years", "maintenance_interval_days"]) body[k] = form[k as "depreciation_years"] ? Number(form[k as "depreciation_years"]) : undefined;
                    for (const k of ["category_id", "purchase_date", "warranty_end"]) if (!form[k as "category_id"]) delete body[k];
                    const r = await act.run(() => api.assets.create(body), { invalidate: ["assets"], success: "Demirbaş kaydedildi" });
                    if (r) setOpen(false);
                }}>
                <Grid cols={3}>
                    <Field label="Ad" required><Input required value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} /></Field>
                    <Field label="Kategori"><Select value={form.category_id} onChange={(e) => setForm({ ...form, category_id: e.target.value })} options={(cats.data?.data ?? []).map((c) => ({ value: c.id, label: c.name }))} placeholder="Yok" /></Field>
                    <Field label="Demirbaş kodu"><Input value={form.asset_code} onChange={(e) => setForm({ ...form, asset_code: e.target.value })} /></Field>
                    <Field label="Seri no"><Input value={form.serial_number} onChange={(e) => setForm({ ...form, serial_number: e.target.value })} /></Field>
                    <Field label="Konum"><Input value={form.location} onChange={(e) => setForm({ ...form, location: e.target.value })} /></Field>
                    <Field label="Durum"><Select value={form.condition} onChange={(e) => setForm({ ...form, condition: e.target.value })} options={opts(ASSET_CONDITION).filter((o) => o.value !== "DISPOSED")} /></Field>
                    <Field label="Alış tarihi"><Input type="date" value={form.purchase_date} onChange={(e) => setForm({ ...form, purchase_date: e.target.value })} /></Field>
                    <Field label="Alış bedeli (TL)"><Input type="number" step="0.01" value={form.purchase_price} onChange={(e) => setForm({ ...form, purchase_price: e.target.value })} /></Field>
                    <Field label="Tedarikçi"><Input value={form.vendor} onChange={(e) => setForm({ ...form, vendor: e.target.value })} /></Field>
                    <Field label="Garanti bitişi"><Input type="date" value={form.warranty_end} onChange={(e) => setForm({ ...form, warranty_end: e.target.value })} /></Field>
                    <Field label="Amortisman (yıl)" hint="Boşsa kategori varsayılanı"><Input type="number" value={form.depreciation_years} onChange={(e) => setForm({ ...form, depreciation_years: e.target.value })} /></Field>
                    <Field label="Bakım aralığı (gün)"><Input type="number" value={form.maintenance_interval_days} onChange={(e) => setForm({ ...form, maintenance_interval_days: e.target.value })} /></Field>
                </Grid>
            </FormModal>

            <Modal open={!!detail} onClose={() => setDetail(null)} title={detail?.name ?? ""} wide>
                <div className="space-y-4">
                    <ActionFeedback action={act} />
                    <QueryView q={detailQ} isEmpty={() => false}>
                        {(d) => d.depreciation ? (
                            <p className="text-sm">Birikmiş amortisman {tl(d.depreciation.accumulated)} · defter değeri <b>{tl(d.depreciation.book_value)}</b> · yıllık {tl(d.depreciation.annual_amount)}{d.depreciation.fully_depreciated ? " · tamamen amorti edildi" : ""}</p>
                        ) : <Notice tone="blue">{d.depreciation_note ?? "Amortisman hesaplanamadı (alış tarihi/bedeli yok)."}</Notice>}
                    </QueryView>
                    <div className="flex gap-2">
                        {canMaintain && detail?.status !== "DISPOSED" && (
                            <Button size="sm" onClick={() => setMaint({ maintenance_type: "PREVENTIVE", description: "", labor_cost: "", parts_cost: "", performed_by: "", performed_at: today(), new_condition: "" })}>Bakım kaydı</Button>
                        )}
                        {canWrite && detail?.status !== "DISPOSED" && <Button size="sm" variant="danger" onClick={() => { setDispose({ reason: "", decision_ref: "" }); setDisposing(detail); }}>Hurdaya ayır</Button>}
                    </div>
                    <QueryView q={history} empty="Bakım kaydı yok">
                        {(h) => (
                            <Table rows={h.data} rowKey={(m) => m.id} columns={[
                                { header: "Tarih", cell: (m) => date(m.performed_at) },
                                { header: "Tür", cell: (m) => MTYPES.find((t) => t.value === m.maintenance_type)?.label ?? m.maintenance_type },
                                { header: "Açıklama", cell: (m) => m.description },
                                { header: "Yapan", cell: (m) => m.performed_by ?? "—" },
                                { header: "Maliyet", cell: (m) => tl(m.total_cost) },
                            ]} />
                        )}
                    </QueryView>
                </div>
            </Modal>

            <FormModal open={!!maint} onClose={() => setMaint(null)} title="Bakım kaydı" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!maint || !detail) return;
                    const body: Record<string, unknown> = { ...maint, labor_cost: Number(maint.labor_cost || 0), parts_cost: Number(maint.parts_cost || 0) };
                    if (!maint.new_condition) delete body.new_condition;
                    const r = await act.run(() => api.assets.addMaintenance(detail.id, body), { invalidate: ["assets"], success: (res) => `Bakım kaydedildi (toplam ${tl(res.total_cost)})` });
                    if (r) setMaint(null);
                }}>
                {maint && (
                    <Grid>
                        <Field label="Tür"><Select value={maint.maintenance_type} onChange={(e) => setMaint({ ...maint, maintenance_type: e.target.value })} options={MTYPES} /></Field>
                        <Field label="Tarih"><Input type="date" value={maint.performed_at} onChange={(e) => setMaint({ ...maint, performed_at: e.target.value })} /></Field>
                        <Field label="İşçilik (TL)"><Input type="number" step="0.01" value={maint.labor_cost} onChange={(e) => setMaint({ ...maint, labor_cost: e.target.value })} /></Field>
                        <Field label="Parça (TL)"><Input type="number" step="0.01" value={maint.parts_cost} onChange={(e) => setMaint({ ...maint, parts_cost: e.target.value })} /></Field>
                        <Field label="Yapan"><Input value={maint.performed_by} onChange={(e) => setMaint({ ...maint, performed_by: e.target.value })} /></Field>
                        <Field label="Yeni durum"><Select value={maint.new_condition} onChange={(e) => setMaint({ ...maint, new_condition: e.target.value })} options={opts(ASSET_CONDITION)} placeholder="Değişmedi" /></Field>
                    </Grid>
                )}
                {maint && <Field label="Açıklama" required><Textarea required value={maint.description} onChange={(e) => setMaint({ ...maint, description: e.target.value })} /></Field>}
            </FormModal>
            <FormModal open={!!disposing} onClose={() => setDisposing(null)} title="Hurdaya ayır" submitLabel="Hurdaya ayır" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!disposing) return;
                    const r = await act.run(() => api.assets.dispose(disposing.id, dispose), { invalidate: ["assets"], success: "Demirbaş hurdaya ayrıldı" });
                    if (r) { setDisposing(null); setDetail(null); }
                }}>
                <Field label="Gerekçe" required><Textarea required value={dispose.reason} onChange={(e) => setDispose({ ...dispose, reason: e.target.value })} /></Field>
                <Field label="Karar referansı" required hint="Yönetim/kurul kararının tarih ve numarası"><Input required value={dispose.decision_ref} onChange={(e) => setDispose({ ...dispose, decision_ref: e.target.value })} /></Field>
            </FormModal>
        </Page>
    );
}
