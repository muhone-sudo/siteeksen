"use client";

import { useState } from "react";
import Link from "next/link";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Button, Card, Field, FormModal, Notice, Page, QueryView, Select, StatusBadge, Table, Textarea, Input } from "@/components/ui/kit";
import { dateTime } from "@/lib/format";
import { REQUEST_STATUS } from "@/components/market/labels";

/** Usta & Hizmet — site adına alım (FAZ M10, K12): yönetici talep açar; kurul ve denetçi okur. */
export default function SiteMarketPage() {
    const { roles } = useRoles();
    const manager = roles.includes("MANAGER");
    const list = useApi(["mp-site-requests"], api.market.buyer.requests);
    const meta = useApi(["market-meta"], api.market.meta);
    const act = useAction();
    const [form, setForm] = useState<{ category_id: string; description: string; preferred_time: string } | null>(null);
    const [count, setCount] = useState<number | null>(null);
    const cats = (meta.data?.categories ?? []).filter((c) => c.buyer_scope !== "RESIDENT");
    const pick = async (category_id: string) => {
        setForm((f) => f && { ...f, category_id });
        setCount(null);
        if (category_id) setCount((await api.market.buyer.matchCount(category_id)).count);
    };
    return (
        <Page title="Usta & Hizmet" description="Site adına teklif toplayın; teklifleri karşılaştırıp seçilen teklifi gidere ya da sözleşmeye çevirin"
            actions={manager ? <Button onClick={() => { setForm({ category_id: "", description: "", preferred_time: "" }); setCount(null); }}>Teklif topla</Button> : undefined}>
            <ActionFeedback action={act} />
            {!manager && <Notice tone="blue">Site adına talebi yönetici açar ve teklif seçer; kurul üyeleri ve denetçi talepleri ve teklifleri görür (KMK m.41).</Notice>}
            <Card padded={false}>
                <QueryView q={list} empty="Site adına açılmış talep yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(r) => r.id} columns={[
                            { header: "Tarih", cell: (r) => dateTime(r.created_at) },
                            { header: "Kategori", cell: (r) => <Link className="font-medium text-primary hover:underline" href={`/dashboard/usta-hizmet/${r.id}`}>{r.category_name}</Link> },
                            { header: "Açıklama", cell: (r) => <span className="line-clamp-2 text-sm">{r.description}</span> },
                            { header: "Kabul", cell: (r) => `${r.accepted_count}/${r.max_accepts}` },
                            { header: "Durum", cell: (r) => <StatusBadge value={r.status} map={REQUEST_STATUS} /> },
                        ]} />
                    )}
                </QueryView>
            </Card>
            {form && (
                <FormModal open title="Site adına teklif topla" submitLabel="Talebi gönder" pending={act.pending} error={act.error} onClose={() => setForm(null)}
                    onSubmit={async () => {
                        const r = await act.run(() => api.market.buyer.create(form), { invalidate: ["mp-site-requests"], success: (x) => `Talep ${x.dispatched} işletmeye iletildi` });
                        if (r) setForm(null);
                    }}>
                    <Field label="Kategori" required>
                        <Select value={form.category_id} onChange={(e) => void pick(e.target.value)}
                            options={[{ value: "", label: "Seçin" }, ...cats.map((c) => ({ value: c.id, label: c.name }))]} />
                    </Field>
                    {form.category_id && (
                        <p className={`text-sm ${count === 0 ? "text-red-600" : "text-gray-600"}`}>
                            {count === null ? "Uygun işletmeler aranıyor…" : count === 0 ? "Sitenizin bölgesinde bu kategoride onaylı işletme yok; talep açılamaz."
                                : `Sitenizin bölgesinde bu kategoride ${count} onaylı işletme var. Sitede görevli kişilerin işletmelerine talep gönderilmez.`}
                        </p>
                    )}
                    <Field label="Ne yapılacak?" required><Textarea value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} /></Field>
                    <Field label="Uygun zaman"><Input value={form.preferred_time} onChange={(e) => setForm({ ...form, preferred_time: e.target.value })} /></Field>
                    <p className="text-xs text-gray-500">Talebi kabul eden işletmeler sizin adınızı, telefonunuzu ve site adresini görür.</p>
                </FormModal>
            )}
        </Page>
    );
}
