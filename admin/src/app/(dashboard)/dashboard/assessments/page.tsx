"use client";

import { useState } from "react";
import { Plus, Trash2 } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Notice, Page, QueryView, ReadOnlyHint, Select, Table } from "@/components/ui/kit";
import { date, pct, tl, today } from "@/lib/format";
import { OpeningBalances } from "@/components/finance/opening-balances";

/**
 * Aylık aidat tahakkuku (KMK m.20). Tutar, seçilen gider kalemlerinin dağıtım
 * türüne göre (eşit / arsa payı / alan) sunucuda kuruş hassasiyetinde
 * dağıtılır; istemci pay hesaplamaz.
 */
export default function AssessmentsPage() {
    const year = new Date().getFullYear();
    const [y, setY] = useState(year);
    const q = useApi(["assessments", "overview", y], () => api.finance.overview(y));
    const cats = useApi(["finance-categories"], api.finance.categories);
    const act = useAction();
    const { canWrite } = useRoles();
    const [open, setOpen] = useState(false);
    const now = new Date();
    const [form, setForm] = useState({
        period_year: now.getFullYear(),
        period_month: now.getMonth() + 1,
        due_date: today(),
        items: [{ category_id: "", amount: "" }],
    });
    const [lateAsOf, setLateAsOf] = useState(today());

    // Sayaç bazlı (METER_READING) ve özel (CUSTOM) kalemler tahakkukta paylaştırılmaz;
    // sunucu reddeder (ısınma sayaç modülünde ısı payıyla hesaplanır). Seçtirilmez.
    const catOptions = (cats.data?.data ?? [])
        .filter((c) => ["EQUAL", "SHARE_RATIO", "AREA_M2"].includes(c.distribution_type))
        .map((c) => ({ value: c.id, label: `${c.name} — ${c.distribution_type}` }));

    return (
        <Page
            title="Aidat tahakkuku"
            description="Dönemlik tahakkuk, gider kalemlerinin dağıtım kuralına göre her bağımsız bölüme paylaştırılır (KMK m.20)."
            actions={canWrite && <Button onClick={() => setOpen(true)}><Plus className="h-4 w-4" /> Tahakkuk oluştur</Button>}
        >
            {!canWrite && <ReadOnlyHint />}
            <ActionFeedback action={act} />
            <Card title="Dönemler" actions={<Select value={String(y)} onChange={(e) => setY(Number(e.target.value))} options={[year - 1, year, year + 1].map((v) => ({ value: String(v), label: String(v) }))} />} padded={false}>
                <QueryView q={q} empty={`${y} için tahakkuk yok`}>
                    {(d) => (
                        <Table
                            rows={d.data}
                            rowKey={(p) => p.period}
                            columns={[
                                { header: "Dönem", cell: (p) => p.period },
                                { header: "Vade", cell: (p) => date(p.due_date) },
                                { header: "Tahakkuk", cell: (p) => tl(p.total_amount) },
                                { header: "Tahsil edilen", cell: (p) => tl(p.collected_amount) },
                                { header: "Oran", cell: (p) => pct(p.rate, 1) },
                                { header: "Durum", cell: (p) => (p.status === "completed" ? <Badge tone="green">Tamamlandı</Badge> : <Badge tone="amber">Açık</Badge>) },
                            ]}
                        />
                    )}
                </QueryView>
            </Card>

            <OpeningBalances canWrite={canWrite} />

            {canWrite && (
                <Card title="Gecikme tazminatı (KMK m.20/2)">
                    <p className="mb-3 text-sm text-gray-600">
                        Vadesi geçmiş ödenmemiş ASIL borca aylık %5 işler (oran mevzuat tablosundan). Aynı gün tekrar çalıştırmak tutarı değiştirmez.
                    </p>
                    <div className="flex flex-wrap items-end gap-2">
                        <Field label="Hesap tarihi"><Input type="date" value={lateAsOf} onChange={(e) => setLateAsOf(e.target.value)} /></Field>
                        <Button
                            disabled={act.pending}
                            onClick={() =>
                                act.run(() => api.finance.accrueLateFees(lateAsOf), {
                                    invalidate: ["assessments", "debtors"],
                                    success: (r) => `${r.processed_count} tahakkuka toplam ${r.total_fee_try} TL tazminat işlendi (oran ${r.monthly_rate}, ${r.legal_basis})`,
                                })
                            }
                        >
                            Tazminatı işlet
                        </Button>
                    </div>
                </Card>
            )}

            <FormModal
                open={open}
                onClose={() => setOpen(false)}
                title="Tahakkuk oluştur"
                wide
                pending={act.pending}
                error={act.error}
                onSubmit={async () => {
                    const expense_items = form.items
                        .filter((i) => i.category_id && Number(i.amount) > 0)
                        .map((i) => ({ category_id: i.category_id, amount: Number(i.amount) }));
                    const r = await act.run(
                        () => api.finance.createAssessment({ period_year: form.period_year, period_month: form.period_month, due_date: form.due_date, expense_items }),
                        { invalidate: ["assessments", "dashboard"], success: (res) => `${res.data.length} bağımsız bölüme tahakkuk yazıldı` }
                    );
                    if (r) setOpen(false);
                }}
            >
                <Grid cols={3}>
                    <Field label="Yıl" required><Input type="number" value={form.period_year} onChange={(e) => setForm({ ...form, period_year: Number(e.target.value) })} /></Field>
                    <Field label="Ay" required>
                        <Select value={String(form.period_month)} onChange={(e) => setForm({ ...form, period_month: Number(e.target.value) })}
                            options={Array.from({ length: 12 }, (_, i) => ({ value: String(i + 1), label: String(i + 1).padStart(2, "0") }))} />
                    </Field>
                    <Field label="Son ödeme" required><Input type="date" required value={form.due_date} onChange={(e) => setForm({ ...form, due_date: e.target.value })} /></Field>
                </Grid>
                <div className="space-y-2">
                    <p className="text-sm font-medium">Gider kalemleri</p>
                    {form.items.map((it, i) => (
                        <div key={i} className="flex gap-2">
                            <Select className="flex-1" value={it.category_id} options={catOptions} placeholder="Kalem seçin"
                                onChange={(e) => setForm({ ...form, items: form.items.map((x, j) => (j === i ? { ...x, category_id: e.target.value } : x)) })} />
                            <Input className="w-40" type="number" step="0.01" min="0" placeholder="Tutar (TL)" value={it.amount}
                                onChange={(e) => setForm({ ...form, items: form.items.map((x, j) => (j === i ? { ...x, amount: e.target.value } : x)) })} />
                            <Button variant="ghost" onClick={() => setForm({ ...form, items: form.items.filter((_, j) => j !== i) })} aria-label="Kalemi çıkar"><Trash2 className="h-4 w-4" /></Button>
                        </div>
                    ))}
                    <Button variant="secondary" size="sm" onClick={() => setForm({ ...form, items: [...form.items, { category_id: "", amount: "" }] })}>+ Kalem</Button>
                </div>
                <Notice tone="blue">Aynı dönem için ikinci tahakkuk oluşturulamaz. Paylar sunucuda kuruş hassasiyetinde hesaplanır; toplam, kalem tutarlarına birebir eşittir.</Notice>
            </FormModal>
        </Page>
    );
}
