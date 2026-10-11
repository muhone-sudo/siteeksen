"use client";

import { useState } from "react";
import { Plus, Upload } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Notice, Page, QueryView, Select, Stats, Table, Textarea } from "@/components/ui/kit";
import { num } from "@/lib/format";
import type { Unit, UnitInput } from "@/lib/types";

const UNIT_TYPES = [
    { value: "APARTMENT", label: "Daire" },
    { value: "SHOP", label: "Dükkân" },
    { value: "OFFICE", label: "Ofis" },
    { value: "PARKING", label: "Otopark" },
    { value: "STORAGE", label: "Depo" },
];
const TYPE_LABEL = Object.fromEntries(UNIT_TYPES.map((t) => [t.value, t.label]));
/** Oturum durumu (067): kayıtlardan hesaplanır — kiracı varsa kiracı oturur; yoksa malik oturur ya da daire boştur. */
const OCCUPANCY: Record<string, { label: string; tone: "green" | "blue" | "gray" | "red" }> = {
    TENANT_OCCUPIED: { label: "Kiracı oturuyor", tone: "blue" },
    OWNER_OCCUPIED: { label: "Malik oturuyor", tone: "green" },
    VACANT: { label: "Boş", tone: "gray" },
    UNREGISTERED: { label: "Kayıtsız", tone: "red" },
};

/**
 * Toplu içe aktarma satırı: `blok;kat;kapı;arsa payı;net m²;brüt m²` (blok ve brüt m² boş
 * olabilir; net m² daire/dükkân/ofiste zorunludur — merkezi ısıtmada sabit pay buna göre dağıtılır; ayraç noktalı virgül ya da sekme). Ondalık için virgül de kabul edilir (virgül varsa nokta binlik ayracı sayılır).
 * Hatalı satır varsa hiçbiri gönderilmez; sunucu da hepsini tek işlemde ekler.
 */
function parseUnits(text: string): { units: UnitInput[]; errors: string[] } {
    const units: UnitInput[] = [];
    const errors: string[] = [];
    // "1.234,5" (Türkçe) ve "1234.5" ikisi de kabul edilir: virgül varsa nokta binlik ayracıdır.
    const toNum = (s: string) => {
        const t = s.trim();
        return Number(t.includes(",") ? t.replace(/\./g, "").replace(",", ".") : t);
    };
    text.split(/\r?\n/).forEach((line, i) => {
        if (!line.trim() || line.trim().startsWith("#")) return;
        const [block = "", floor = "", door = "", share = "", net = "", area = ""] = line.split(/[;\t]/);
        const row = i + 1;
        const f = floor.trim() === "" ? 0 : Number(floor.trim());
        const s = toNum(share);
        if (!door.trim()) return errors.push(`${row}. satır: kapı numarası yok`);
        if (!Number.isInteger(f)) return errors.push(`${row}. satır: kat tam sayı olmalı`);
        if (!(s > 0)) return errors.push(`${row}. satır: arsa payı sıfırdan büyük olmalı`);
        const n = toNum(net);
        if (!net.trim() || !(n > 0)) return errors.push(`${row}. satır: net kullanım alanı (m²) sıfırdan büyük olmalı`);
        const u: UnitInput = { block: block.trim(), floor: f, door_number: door.trim(), share_ratio: s, net_area_m2: n };
        if (area.trim()) {
            const a = toNum(area);
            if (!(a >= 0)) return errors.push(`${row}. satır: brüt alan geçersiz`);
            u.gross_area_m2 = a;
        }
        units.push(u);
    });
    return { units, errors };
}

/**
 * Bağımsız bölümler (site kurulumu, FAZ 8.1). Arsa payı tapudaki paydır ve
 * KMK m.20 gider dağıtımının temelidir; değişiklik yalnızca SONRAKİ tahakkukları etkiler.
 */
export default function UnitsPage() {
    const q = useApi(["units"], api.identity.units);
    const act = useAction();
    const { canWrite } = useRoles();
    const empty: UnitInput = { block: "", floor: 0, door_number: "", share_ratio: 0, gross_area_m2: undefined, net_area_m2: undefined, unit_type: "APARTMENT", is_commercial: false };
    const [form, setForm] = useState<UnitInput | null>(null);
    const [editId, setEditId] = useState<string | null>(null);
    const [bulkOpen, setBulkOpen] = useState(false);
    const [bulkText, setBulkText] = useState("");
    const parsed = parseUnits(bulkText);

    const startEdit = (u: Unit) => {
        setEditId(u.id);
        setForm({
            block: u.block, floor: u.floor, door_number: u.door_number, share_ratio: u.share_ratio,
            gross_area_m2: u.gross_area_m2 || undefined, net_area_m2: u.net_area_m2 || undefined, unit_type: u.unit_type, is_commercial: u.is_commercial,
            owner_occupied: u.owner_occupied ?? true,
        });
    };

    return (
        <Page
            title="Bağımsız bölümler"
            description="Daire, dükkân ve diğer bölümler. Arsa payı gider dağıtımının (KMK m.20) temelidir."
            actions={canWrite && (
                <div className="flex gap-2">
                    <Button variant="secondary" onClick={() => setBulkOpen(true)}><Upload className="h-4 w-4" /> Toplu ekle</Button>
                    <Button onClick={() => { setEditId(null); setForm(empty); }}><Plus className="h-4 w-4" /> Bölüm ekle</Button>
                </div>
            )}
        >
            <ActionFeedback action={act} />
            <QueryView q={q} empty="Henüz bağımsız bölüm yok. Site kurulumuna bölümleri ekleyerek başlayın.">
                {(d) => (
                    <>
                        <Stats items={[
                            { label: "Bölüm", value: num(d.data.length) },
                            { label: "Toplam arsa payı", value: num(d.data.reduce((a, u) => a + Number(u.share_ratio || 0), 0)) },
                            { label: "Ticari", value: num(d.data.filter((u) => u.is_commercial).length) },
                            { label: "Boş", value: num(d.data.filter((u) => u.occupancy === "VACANT").length) },
                            { label: "Kayıtsız", value: num(d.data.filter((u) => u.occupancy === "UNREGISTERED").length) },
                        ]} />
                        {d.data.some((u) => u.owner_missing) && (
                            <Notice tone="amber" title="Maliki kayıtlı olmayan daireler">
                                {d.data.filter((u) => u.owner_missing).map((u) => `${u.block ? u.block + "-" : ""}${u.door_number}`).join(", ")} — kiracı kayıtlı ama malik yok. Malik giderleri bu dairelerde yönetimde bekler; maliki kaydedin.
                            </Notice>
                        )}
                        <Card padded={false}>
                            <Table
                                rows={d.data}
                                rowKey={(u) => u.id}
                                columns={[
                                    { header: "Blok", cell: (u) => u.block || "—" },
                                    { header: "Kapı", cell: (u) => u.door_number },
                                    { header: "Kat", cell: (u) => u.floor },
                                    { header: "Tür", cell: (u) => TYPE_LABEL[u.unit_type] ?? u.unit_type },
                                    { header: "Arsa payı", cell: (u) => num(u.share_ratio) },
                                    { header: "Net m²", cell: (u) => (u.net_area_m2 ? num(u.net_area_m2) : ["APARTMENT", "SHOP", "OFFICE"].includes(u.unit_type) ? <Badge tone="red">Eksik</Badge> : "—") },
                                    { header: "Brüt m²", cell: (u) => (u.gross_area_m2 ? num(u.gross_area_m2) : "—") },
                                    { header: "Oturum", cell: (u) => (u.occupancy ? <Badge tone={OCCUPANCY[u.occupancy].tone}>{OCCUPANCY[u.occupancy].label}</Badge> : "—") },
                                    { header: "", cell: (u) => (u.is_commercial ? <Badge tone="amber">Ticari</Badge> : null) },
                                    ...(canWrite ? [{ header: "", cell: (u: Unit) => (
                                        <div className="flex gap-1">
                                            <Button size="sm" variant="ghost" onClick={() => startEdit(u)}>Düzenle</Button>
                                            <Button size="sm" variant="ghost" disabled={act.pending} title="Vadesi geçmiş borç yoksa karekodlu belge üretir"
                                                onClick={async () => {
                                                    const r = await act.run(() => api.finance.clearance(u.id), { success: (x) => `Borcu yoktur belgesi üretildi (geçerlilik ${x.expires_at}). ${x.note}` });
                                                    if (r) await act.run(() => api.finance.clearancePdf(r.id));
                                                }}>Borcu yoktur</Button>
                                        </div>
                                    ) }] : []),
                                ]}
                            />
                        </Card>
                    </>
                )}
            </QueryView>

            <FormModal
                open={!!form}
                onClose={() => setForm(null)}
                title={editId ? "Bölümü düzenle" : "Bölüm ekle"}
                pending={act.pending}
                error={act.error}
                onSubmit={async () => {
                    if (!form) return;
                    const r = editId
                        ? await act.run(() => api.identity.updateUnit(editId, form), { invalidate: ["units"], success: "Bölüm güncellendi" })
                        : await act.run(() => api.identity.createUnits([form]), { invalidate: ["units"], success: "Bölüm eklendi" });
                    if (r) setForm(null);
                }}
            >
                {form && (
                    <Grid>
                        <Field label="Blok" hint="Bloksuz yapılarda boş bırakın"><Input value={form.block ?? ""} onChange={(e) => setForm({ ...form, block: e.target.value })} /></Field>
                        <Field label="Kapı no" required><Input required value={form.door_number ?? ""} onChange={(e) => setForm({ ...form, door_number: e.target.value })} /></Field>
                        <Field label="Kat"><Input type="number" step="1" value={form.floor ?? 0} onChange={(e) => setForm({ ...form, floor: Number(e.target.value) })} /></Field>
                        <Field label="Arsa payı" required hint="Tapudaki pay (ör. 120 / 10000 için 120)">
                            <Input required type="number" step="0.0001" min="0.0001" value={form.share_ratio || ""} onChange={(e) => setForm({ ...form, share_ratio: Number(e.target.value) })} />
                        </Field>
                        <Field label="Net kullanım alanı (m²)" required={["APARTMENT", "SHOP", "OFFICE"].includes(form.unit_type ?? "APARTMENT")} hint="Kapalı kullanım alanı; ısıtma giderinin sabit payı buna göre dağıtılır">
                            <Input required={["APARTMENT", "SHOP", "OFFICE"].includes(form.unit_type ?? "APARTMENT")} type="number" step="0.01" min="0.01" value={form.net_area_m2 ?? ""} onChange={(e) => setForm({ ...form, net_area_m2: e.target.value === "" ? undefined : Number(e.target.value) })} />
                        </Field>
                        <Field label="Brüt m²"><Input type="number" step="0.01" min="0" value={form.gross_area_m2 ?? ""} onChange={(e) => setForm({ ...form, gross_area_m2: e.target.value === "" ? undefined : Number(e.target.value) })} /></Field>
                        <Field label="Tür"><Select value={form.unit_type ?? "APARTMENT"} onChange={(e) => setForm({ ...form, unit_type: e.target.value })} options={UNIT_TYPES} /></Field>
                        <Field label="Ticari mi?" hint="Ticari bölümler bazı gider kalemlerinden muaf tutulabilir">
                            <Select value={form.is_commercial ? "1" : "0"} onChange={(e) => setForm({ ...form, is_commercial: e.target.value === "1" })} options={[{ value: "0", label: "Hayır" }, { value: "1", label: "Evet" }]} />
                        </Field>
                        {editId && (
                            <Field label="Kiracı yokken" hint="Kiracı kayıtlıyken kiracı oturur. Boş dairede kullanım ve malik giderlerinin tamamı malike düşer.">
                                <Select value={form.owner_occupied === false ? "0" : "1"} onChange={(e) => setForm({ ...form, owner_occupied: e.target.value === "1" })}
                                    options={[{ value: "1", label: "Malik oturuyor" }, { value: "0", label: "Daire boş" }]} />
                            </Field>
                        )}
                    </Grid>
                )}
            </FormModal>

            <FormModal
                open={bulkOpen}
                onClose={() => setBulkOpen(false)}
                title="Toplu bölüm ekle"
                pending={act.pending}
                error={act.error}
                onSubmit={async () => {
                    if (parsed.errors.length || parsed.units.length === 0) return;
                    const r = await act.run(() => api.identity.createUnits(parsed.units), {
                        invalidate: ["units"],
                        success: (x) => `${x.created} bölüm eklendi`,
                    });
                    if (r) { setBulkOpen(false); setBulkText(""); }
                }}
            >
                <p className="text-sm text-gray-600 dark:text-gray-400">
                    Her satıra bir bölüm: <code>blok;kat;kapı;arsa payı;net m²;brüt m²</code> (Excel&apos;den kopyalanan sekmeli satırlar da olur).
                    Bir satır bile hatalıysa hiçbiri eklenmez.
                </p>
                <Textarea rows={10} value={bulkText} onChange={(e) => setBulkText(e.target.value)} placeholder={"A;0;1;120,5;82;95\nA;1;2;130;90;\nB;2;1;149,5;95;110"} />
                {parsed.errors.length > 0
                    ? <Notice tone="red" title="Düzeltilmesi gereken satırlar">{parsed.errors.slice(0, 10).join(" · ")}</Notice>
                    : parsed.units.length > 0 && <Notice tone="blue">{parsed.units.length} bölüm eklenecek, toplam arsa payı {num(parsed.units.reduce((a, u) => a + (u.share_ratio ?? 0), 0))}.</Notice>}
            </FormModal>
        </Page>
    );
}
