"use client";

import { useState } from "react";
import { Plus } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Notice, Page, QueryView, Select, Table } from "@/components/ui/kit";
import { date, kurus, tl, today } from "@/lib/format";
import type { CommonLease } from "@/lib/types";

const KIND: Record<string, string> = {
    ROOF_FACADE_AD: "Çatı / cephe reklamı", ANTENNA: "Baz istasyonu / anten", CARETAKER_FLAT: "Kapıcı dairesi",
    PARKING: "Otopark", STORAGE: "Depo", SHOP: "Dükkân / ticari alan", OTHER: "Diğer",
};

/**
 * Ortak alan geliri (FAZ 7.6). Kiralama bütün kat maliklerinin oybirliğini ister (KMK m.45);
 * gelir arsa payı oranında paylaştırılır, her malik kendi payını beyan eder.
 */
export default function CommonAreaPage() {
    const leases = useApi(["leases"], api.governance.leases);
    const [year, setYear] = useState(new Date().getFullYear());
    const report = useApi(["income-report", year], () => api.governance.incomeReport(year));
    const assemblies = useApi(["assemblies"], api.governance.assemblies);
    const act = useAction();
    const { canWrite } = useRoles();
    const [form, setForm] = useState<{ area_kind: string; area_name: string; tenant_name: string; tenant_is_business: boolean; start_date: string; monthly_rent: string; assembly: string; agenda_item_id: string } | null>(null);
    const assembly = useApi(["assemblies", form?.assembly ?? ""], () => api.governance.assembly(form?.assembly ?? ""), !!form?.assembly);
    const unanimous = (assembly.data?.agenda_items ?? []).filter((i) => i.decision_status === "ACCEPTED" && i.required_majority_code === "UNANIMITY_TRANSFER_ACTS");
    const [income, setIncome] = useState<{ lease: CommonLease; period: string; gross: string; withholding: string; received_on: string } | null>(null);
    const inv = { invalidate: ["leases", "income-report"] };

    return (
        <Page title="Ortak alan geliri" description="Ortak yer kiralamaları ve gelirin kat maliklerine paylaştırılması (KMK m.45)."
            actions={canWrite && <Button onClick={() => setForm({ area_kind: "ROOF_FACADE_AD", area_name: "", tenant_name: "", tenant_is_business: true, start_date: today(), monthly_rent: "", assembly: "", agenda_item_id: "" })}><Plus className="h-4 w-4" /> Kiralama kaydet</Button>}>
            <ActionFeedback action={act} />
            <Notice tone="blue">Ortak yerin kiraya verilmesi bütün kat maliklerinin oybirliğini ister (KMK m.45). Sığınak kiraya verilemez. Gelir kat maliklerinindir; aksi kararlaştırılmadıkça arsa payı oranında paylaştırılır ve her malik kendi payını beyan eder.</Notice>
            <Card title="Kiralamalar" padded={false}>
                <QueryView q={leases} empty="Kiralama yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(l) => l.id} columns={[
                            { header: "Alan", cell: (l) => <><b>{l.area_name}</b><div className="text-xs text-gray-500">{KIND[l.area_kind] ?? l.area_kind}</div></> },
                            { header: "Kiracı", cell: (l) => <>{l.tenant_name}{l.tenant_is_business && <Badge tone="blue">işyeri</Badge>}</> },
                            { header: "Başlangıç", cell: (l) => date(l.start_date) },
                            { header: "Aylık kira", cell: (l) => tl(l.monthly_rent) },
                            { header: "Karar", cell: (l) => <span className="text-xs">{l.decision_ref}</span> },
                            { header: "Toplam gelir", cell: (l) => tl(l.income_total) },
                            { header: "Durum", cell: (l) => (l.status === "ACTIVE" ? <Badge tone="green">Aktif</Badge> : <Badge>Sona erdi</Badge>) },
                            ...(canWrite ? [{
                                header: "", cell: (l: CommonLease) => l.status === "ACTIVE" ? (
                                    <div className="flex gap-1">
                                        <Button size="sm" onClick={() => setIncome({ lease: l, period: new Date().toISOString().slice(0, 7), gross: String(l.monthly_rent), withholding: "0", received_on: today() })}>Tahsilat gir</Button>
                                        <Button size="sm" variant="ghost" onClick={() => act.run(() => api.governance.endLease(l.id, today()), { ...inv, success: "Kiralama sona erdirildi" })}>Sonlandır</Button>
                                    </div>
                                ) : null,
                            }] : []),
                        ]} />
                    )}
                </QueryView>
            </Card>

            <Card title="Kat maliki payları" actions={<Input type="number" className="w-28" value={year} onChange={(e) => setYear(Number(e.target.value))} />} padded={false}>
                <QueryView q={report} isEmpty={(d) => d.data.length === 0} empty="Bu yıl için gelir yok">
                    {(d) => (
                        <>
                            <Table rows={d.data} rowKey={(r) => r.unit_id} columns={[
                                { header: "Daire", cell: (r) => <b>{r.unit}</b> },
                                { header: "Malik(ler)", cell: (r) => r.owners || "—" },
                                { header: "Brüt pay", cell: (r) => kurus(r.gross_kurus) },
                                { header: "Stopaj", cell: (r) => kurus(r.withholding_kurus) },
                                { header: "Net", cell: (r) => kurus(r.gross_kurus - r.withholding_kurus) },
                            ]} />
                            <p className="px-4 py-3 text-xs text-gray-500">Toplam brüt {kurus(d.total_gross_kurus)}, stopaj {kurus(d.total_withholding_kurus)}. {d.note}</p>
                        </>
                    )}
                </QueryView>
            </Card>

            <FormModal open={!!form} onClose={() => setForm(null)} title="Ortak yer kiralaması" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!form) return;
                    const r = await act.run(() => api.governance.createLease({ ...form, monthly_rent: Number(form.monthly_rent) }), { ...inv, success: "Kiralama kaydedildi" });
                    if (r) setForm(null);
                }}>
                {form && (<>
                    <Grid>
                        <Field label="Alan türü"><Select value={form.area_kind} onChange={(e) => setForm({ ...form, area_kind: e.target.value })} options={Object.entries(KIND).map(([value, label]) => ({ value, label }))} /></Field>
                        <Field label="Alan adı" required><Input required value={form.area_name} onChange={(e) => setForm({ ...form, area_name: e.target.value })} /></Field>
                        <Field label="Kiracı" required><Input required value={form.tenant_name} onChange={(e) => setForm({ ...form, tenant_name: e.target.value })} /></Field>
                        <Field label="Aylık kira (TL)" required><Input type="number" min="0" step="0.01" required value={form.monthly_rent} onChange={(e) => setForm({ ...form, monthly_rent: e.target.value })} /></Field>
                        <Field label="Başlangıç" required><Input type="date" required value={form.start_date} onChange={(e) => setForm({ ...form, start_date: e.target.value })} /></Field>
                        <Field label="Kiracı işyeri mi?"><Select value={form.tenant_is_business ? "1" : "0"} onChange={(e) => setForm({ ...form, tenant_is_business: e.target.value === "1" })} options={[{ value: "1", label: "Evet (stopaj yapar)" }, { value: "0", label: "Hayır" }]} /></Field>
                        <Field label="Genel kurul">
                            <Select value={form.assembly} onChange={(e) => setForm({ ...form, assembly: e.target.value, agenda_item_id: "" })}
                                options={[{ value: "", label: "Seçin" }, ...(assemblies.data?.data ?? []).filter((a) => a.status === "HELD").map((a) => ({ value: a.id, label: `${date(a.held_at ?? a.scheduled_at)} — ${a.call_number}. toplantı` }))]} />
                        </Field>
                        <Field label="Oybirliğiyle kabul edilen madde" required>
                            <Select required value={form.agenda_item_id} onChange={(e) => setForm({ ...form, agenda_item_id: e.target.value })} disabled={!form.assembly}
                                options={[{ value: "", label: unanimous.length ? "Seçin" : "Oybirliği maddesi yok" }, ...unanimous.map((i) => ({ value: i.id, label: `${i.order_no}. ${i.title}` }))]} />
                        </Field>
                    </Grid>
                </>)}
            </FormModal>

            <FormModal open={!!income} onClose={() => setIncome(null)} title={`Kira tahsilatı — ${income?.lease.area_name ?? ""}`} pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!income) return;
                    const r = await act.run(() => api.governance.recordIncome(income.lease.id, {
                        period: income.period, gross_amount: Number(income.gross), withholding_amount: Number(income.withholding || 0), received_on: income.received_on,
                    }), { ...inv, success: (x) => x.note });
                    if (r) setIncome(null);
                }}>
                {income && (<Grid>
                    <Field label="Dönem" required><Input type="month" required value={income.period} onChange={(e) => setIncome({ ...income, period: e.target.value })} /></Field>
                    <Field label="Tahsilat tarihi" required><Input type="date" required value={income.received_on} onChange={(e) => setIncome({ ...income, received_on: e.target.value })} /></Field>
                    <Field label="Brüt kira (TL)" required><Input type="number" min="0" step="0.01" required value={income.gross} onChange={(e) => setIncome({ ...income, gross: e.target.value })} /></Field>
                    {income.lease.tenant_is_business && <Field label="Kiracının kestiği stopaj (TL)" hint="Kiracının ödeme belgesindeki tutar (GVK m.94)"><Input type="number" min="0" step="0.01" value={income.withholding} onChange={(e) => setIncome({ ...income, withholding: e.target.value })} /></Field>}
                </Grid>)}
            </FormModal>
        </Page>
    );
}
