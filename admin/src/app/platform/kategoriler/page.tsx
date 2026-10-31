"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Notice, Page, QueryView, Select, Table } from "@/components/ui/kit";
import { kurus } from "@/lib/format";
import type { MpCategory } from "@/lib/types";

const SCOPE: Record<string, string> = { RESIDENT: "Sakin", MANAGEMENT: "Site yönetimi", BOTH: "İkisi" };
type Form = Omit<MpCategory, "id"> & { id?: string; fee: string };

/** Kategori ve talep ücretleri (FAZ M4.3, K14): ücret kategoriye göre sabit; kimin talep açabileceği kategoride. */
export default function PlatformCategoriesPage() {
    const list = useApi(["mp-categories"], api.market.platform.categories);
    const act = useAction();
    const [f, setF] = useState<Form | null>(null);
    return (
        <Page title="Kategoriler ve talep ücretleri" description="Tedarikçinin talebi kabul ederken ödediği ücret"
            actions={<Button onClick={() => setF({ name: "", parent_id: null, request_fee_kurus: 0, buyer_scope: "RESIDENT", is_active: true, sort_order: 0, fee: "" })}>Kategori ekle</Button>}>
            <ActionFeedback action={act} />
            <Notice tone="blue">Site alımları kendi kategorilerindedir (ör. &quot;Site temizliği&quot; yalnız site yönetimi). Ücret değişikliği işlem kaydına yazılır ve yeni kabullerde geçerli olur.</Notice>
            <Card padded={false}>
                <QueryView q={list} empty="Kategori yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(c) => c.id} columns={[
                            { header: "Kategori", cell: (c) => <span className="font-medium">{c.name}</span> },
                            { header: "Üst", cell: (c) => d.data.find((x) => x.id === c.parent_id)?.name ?? "—" },
                            { header: "Talep ücreti", cell: (c) => kurus(c.request_fee_kurus) },
                            { header: "Kim açar", cell: (c) => SCOPE[c.buyer_scope] },
                            { header: "Durum", cell: (c) => (c.is_active ? <Badge tone="green">Etkin</Badge> : <Badge>Pasif</Badge>) },
                            { header: "", cell: (c) => <Button size="sm" variant="ghost" onClick={() => setF({ ...c, fee: String(c.request_fee_kurus / 100) })}>Düzenle</Button> },
                        ]} />
                    )}
                </QueryView>
            </Card>
            {f && (
                <FormModal open title={f.id ? "Kategoriyi düzenle" : "Kategori ekle"} onClose={() => setF(null)} pending={act.pending} error={act.error}
                    onSubmit={async () => {
                        const { id, fee, ...rest } = f;
                        const r = await act.run(() => api.market.platform.saveCategory(id ?? null, { ...rest, request_fee_kurus: Math.round(Number(fee.replace(",", ".")) * 100) || 0 }),
                            { invalidate: ["mp-categories", "market-meta"], success: "Kategori kaydedildi" });
                        if (r) setF(null);
                    }}>
                    <Field label="Ad" required><Input value={f.name} onChange={(e) => setF({ ...f, name: e.target.value })} /></Field>
                    <Grid>
                        <Field label="Talep ücreti (TL)" required><Input inputMode="decimal" value={f.fee} onChange={(e) => setF({ ...f, fee: e.target.value })} /></Field>
                        <Field label="Kim talep açabilir" required>
                            <Select value={f.buyer_scope} onChange={(e) => setF({ ...f, buyer_scope: e.target.value as MpCategory["buyer_scope"] })}
                                options={Object.entries(SCOPE).map(([value, label]) => ({ value, label }))} />
                        </Field>
                    </Grid>
                    <Grid>
                        <Field label="Üst kategori">
                            <Select value={f.parent_id ?? ""} placeholder="(yok)" onChange={(e) => setF({ ...f, parent_id: e.target.value || null })}
                                options={(list.data?.data ?? []).filter((c) => c.id !== f.id).map((c) => ({ value: c.id, label: c.name }))} />
                        </Field>
                        <Field label="Sıra"><Input type="number" value={f.sort_order} onChange={(e) => setF({ ...f, sort_order: Number(e.target.value) })} /></Field>
                    </Grid>
                    <label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={f.is_active} onChange={(e) => setF({ ...f, is_active: e.target.checked })} /> Etkin</label>
                </FormModal>
            )}
        </Page>
    );
}
