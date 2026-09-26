"use client";

import { useState } from "react";
import { Plus } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Notice, Page, QueryView, Select, Stats, Table, Tabs } from "@/components/ui/kit";
import { dateTime, num, tl } from "@/lib/format";
import type { InventoryItem } from "@/lib/types";

const UNITS = ["ADET", "KG", "LT", "METRE", "M2", "M3", "PAKET", "KUTU"].map((u) => ({ value: u, label: u }));
const REFS = [
    { value: "PURCHASE", label: "Satın alma" }, { value: "USAGE", label: "Kullanım" }, { value: "RETURN", label: "İade" },
    { value: "WASTE", label: "Fire" }, { value: "ADJUSTMENT", label: "Sayım farkı" },
];

/**
 * Sarf malzeme stoğu. Miktarlar metin olarak gönderilir ("2,5") — ondalık
 * kaybı olmasın. Sayım düzeltmesi (ADJUST) yalnız yönetim yapabilir ve
 * gerekçe ister; görevli yalnızca giriş/çıkış girer.
 */
export default function InventoryPage() {
    const [tab, setTab] = useState<"items" | "movements">("items");
    const [low, setLow] = useState(false);
    const [search, setSearch] = useState("");
    const items = useApi(["inventory", low, search], () => api.inventory.list({ q: search, below_minimum: low ? "true" : undefined }));
    const summary = useApi(["inventory", "summary"], api.inventory.summary);
    const movements = useApi(["inventory", "movements"], () => api.inventory.movements(), tab === "movements");
    const cats = useApi(["inventory-categories"], api.inventory.categories);
    const act = useAction();
    const { canWrite, roles } = useRoles();
    const canMove = canWrite || roles.includes("STAFF");
    const [open, setOpen] = useState(false);
    const blank = { name: "", unit: "ADET", category_id: "", sku: "", minimum_stock: "", location: "" };
    const [form, setForm] = useState(blank);
    const [moving, setMoving] = useState<InventoryItem | null>(null);
    const [mv, setMv] = useState({ movement_type: "IN", quantity: "", unit_price: "", reference_type: "", notes: "" });
    const s = summary.data;

    return (
        <Page title="Stok" description="Temizlik, bakım ve sarf malzemesi stoğu."
            actions={canWrite && <Button onClick={() => { setForm(blank); setOpen(true); }}><Plus className="h-4 w-4" /> Kalem ekle</Button>}>
            <ActionFeedback action={act} />
            <Stats items={[
                { label: "Kalem", value: num(s?.item_count) },
                { label: "Asgari altında", value: num(s?.below_minimum), tone: "amber" },
                { label: "Tükenen", value: num(s?.out_of_stock), tone: "red" },
                { label: "Stok değeri", value: tl(s?.total_value_try) },
            ]} />
            <Tabs tabs={[{ id: "items", label: "Kalemler" }, { id: "movements", label: "Hareketler" }]} value={tab} onChange={setTab} />
            {tab === "items" && (
                <Card padded={false} title="Kalemler" actions={
                    <div className="flex items-center gap-2">
                        <Input placeholder="Ad ya da stok kodu" value={search} onChange={(e) => setSearch(e.target.value)} className="w-48" />
                        <label className="flex items-center gap-1 text-sm"><input type="checkbox" checked={low} onChange={(e) => setLow(e.target.checked)} /> Asgari altı</label>
                    </div>
                }>
                    <QueryView q={items} empty="Stok kalemi yok">
                        {(d) => (
                            <Table rows={d.data} rowKey={(i) => i.id} columns={[
                                { header: "Kalem", cell: (i) => <div><p className="font-medium">{i.name}</p><p className="text-xs text-gray-500">{[i.sku, i.category_name, i.location].filter(Boolean).join(" · ")}</p></div> },
                                { header: "Stok", cell: (i) => <span className={i.below_minimum ? "font-bold text-red-600" : ""}>{num(i.current_stock)} {i.unit}</span> },
                                { header: "Asgari", cell: (i) => `${num(i.minimum_stock)} ${i.unit}` },
                                { header: "Birim maliyet", cell: (i) => tl(i.unit_price) },
                                { header: "Değer", cell: (i) => tl(i.stock_value) },
                                { header: "", cell: (i) => (
                                    <div className="flex items-center gap-1">
                                        {i.below_minimum && <Badge tone="red">Asgari altı</Badge>}
                                        {canMove && <Button size="sm" onClick={() => { setMv({ movement_type: "IN", quantity: "", unit_price: "", reference_type: "", notes: "" }); setMoving(i); }}>Hareket</Button>}
                                    </div>
                                ) },
                            ]} />
                        )}
                    </QueryView>
                </Card>
            )}
            {tab === "movements" && (
                <Card padded={false} title="Son hareketler">
                    <QueryView q={movements} empty="Hareket yok">
                        {(d) => (
                            <Table rows={d.data} rowKey={(m) => m.id} columns={[
                                { header: "Zaman", cell: (m) => dateTime(m.created_at) },
                                { header: "Kalem", cell: (m) => m.item_name ?? "—" },
                                { header: "Tür", cell: (m) => ({ IN: <Badge tone="green">Giriş</Badge>, OUT: <Badge tone="amber">Çıkış</Badge>, ADJUST: <Badge tone="purple">Sayım</Badge> }[m.movement_type] ?? m.movement_type) },
                                { header: "Miktar", cell: (m) => `${num(m.quantity)} ${m.unit ?? ""}` },
                                { header: "Stok", cell: (m) => `${num(m.previous_stock)} → ${num(m.new_stock)}` },
                                { header: "Giren", cell: (m) => m.created_by_name ?? "—" },
                                { header: "Not", cell: (m) => m.notes ?? "" },
                            ]} />
                        )}
                    </QueryView>
                </Card>
            )}

            <FormModal open={open} onClose={() => setOpen(false)} title="Stok kalemi ekle" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    const body: Record<string, unknown> = { ...form };
                    if (!form.category_id) delete body.category_id;
                    if (!form.minimum_stock) delete body.minimum_stock;
                    const r = await act.run(() => api.inventory.create(body), { invalidate: ["inventory"], success: "Kalem eklendi (açılış stoğu 0 — mevcut stoğu sayım düzeltmesiyle girin)" });
                    if (r) setOpen(false);
                }}>
                <Grid>
                    <Field label="Ad" required><Input required value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} /></Field>
                    <Field label="Birim" required><Select value={form.unit} onChange={(e) => setForm({ ...form, unit: e.target.value })} options={UNITS} /></Field>
                    <Field label="Kategori"><Select value={form.category_id} onChange={(e) => setForm({ ...form, category_id: e.target.value })} options={(cats.data?.data ?? []).map((c) => ({ value: c.id, label: c.name }))} placeholder="Yok" /></Field>
                    <Field label="Stok kodu"><Input value={form.sku} onChange={(e) => setForm({ ...form, sku: e.target.value })} /></Field>
                    <Field label="Asgari stok"><Input value={form.minimum_stock} onChange={(e) => setForm({ ...form, minimum_stock: e.target.value })} placeholder="ör. 5" /></Field>
                    <Field label="Konum"><Input value={form.location} onChange={(e) => setForm({ ...form, location: e.target.value })} /></Field>
                </Grid>
            </FormModal>
            <FormModal open={!!moving} onClose={() => setMoving(null)} title={moving ? `Stok hareketi — ${moving.name}` : ""} pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!moving) return;
                    const body: Record<string, unknown> = { ...mv, unit_price: mv.unit_price ? Number(mv.unit_price) : undefined };
                    if (!mv.reference_type) delete body.reference_type;
                    const r = await act.run(() => api.inventory.move(moving.id, body), {
                        invalidate: ["inventory"],
                        success: (res) => `Yeni stok: ${num(res.movement.new_stock)} ${moving.unit}${res.warning ? ` — ${res.warning}` : ""}`,
                    });
                    if (r) setMoving(null);
                }}>
                {moving && <p className="text-sm">Mevcut stok: <b>{num(moving.current_stock)} {moving.unit}</b></p>}
                <Grid>
                    <Field label="Tür">
                        <Select value={mv.movement_type} onChange={(e) => setMv({ ...mv, movement_type: e.target.value })}
                            options={[{ value: "IN", label: "Giriş" }, { value: "OUT", label: "Çıkış" }, ...(canWrite ? [{ value: "ADJUST", label: "Sayım düzeltmesi" }] : [])]} />
                    </Field>
                    <Field label={mv.movement_type === "ADJUST" ? "Sayılan stok" : "Miktar"} required><Input required value={mv.quantity} onChange={(e) => setMv({ ...mv, quantity: e.target.value })} placeholder="ör. 2,5" /></Field>
                    {mv.movement_type === "IN" && <Field label="Birim fiyat (TL)"><Input type="number" step="0.01" value={mv.unit_price} onChange={(e) => setMv({ ...mv, unit_price: e.target.value })} /></Field>}
                    <Field label="Dayanak"><Select value={mv.reference_type} onChange={(e) => setMv({ ...mv, reference_type: e.target.value })} options={REFS} placeholder="Belirtilmedi" /></Field>
                </Grid>
                <Field label={mv.movement_type === "ADJUST" ? "Gerekçe (zorunlu)" : "Not"}><Input required={mv.movement_type === "ADJUST"} value={mv.notes} onChange={(e) => setMv({ ...mv, notes: e.target.value })} /></Field>
                {mv.movement_type === "ADJUST" && <Notice tone="amber">Sayım düzeltmesi stoğu tek kalemde değiştirir; gerekçesi denetim için saklanır.</Notice>}
            </FormModal>
        </Page>
    );
}
