"use client";

import { useState } from "react";
import { Plus } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Notice, Page, QueryView, Select, Table, Tabs } from "@/components/ui/kit";
import { date, kurus, num, today } from "@/lib/format";
import { METER_TYPES } from "@/lib/labels";
import type { Allocation, Meter } from "@/lib/types";

const TYPE_LABEL = Object.fromEntries(METER_TYPES.map((t) => [t.value, t.label]));

export default function MetersPage() {
    const [tab, setTab] = useState<"meters" | "readings" | "allocate">("meters");
    const [type, setType] = useState("");
    const meters = useApi(["meters", type], () => api.meters.list({ meter_type: type }));
    const units = useApi(["units"], api.identity.units);
    const readings = useApi(["meter-readings"], () => api.meters.readings(), tab === "readings");
    const act = useAction();
    const { canWrite, roles } = useRoles();
    const canRead = canWrite || roles.includes("STAFF");
    const [newMeter, setNewMeter] = useState<null | { unit_id: string; meter_type: string; serial_number: string; brand: string }>(null);
    const [reading, setReading] = useState<null | { meter: Meter; current_value: string; reading_date: string; reading_type: string; meter_replaced: boolean; reason: string }>(null);
    const [alloc, setAlloc] = useState({ meter_type: "HEAT", from: "", to: today(), total_amount_try: "" });
    const [allocResult, setAllocResult] = useState<{ allocation: Allocation; basis_note: string; note: string; warning?: string } | null>(null);

    return (
        <Page
            title="Sayaç ve ısı payı"
            description="Sayaç okuma, endeks zinciri ve Merkezi Isıtma Yönetmeliğine göre gider paylaştırma."
            actions={canWrite && <Button onClick={() => setNewMeter({ unit_id: "", meter_type: "HEAT", serial_number: "", brand: "" })}><Plus className="h-4 w-4" /> Sayaç ekle</Button>}
        >
            <ActionFeedback action={act} />
            <Tabs tabs={[{ id: "meters", label: "Sayaçlar" }, { id: "readings", label: "Okumalar" }, { id: "allocate", label: "Gider paylaştırma" }]} value={tab} onChange={setTab} />

            {tab === "meters" && (
                <Card padded={false} actions={<Select value={type} onChange={(e) => setType(e.target.value)} options={METER_TYPES} placeholder="Tüm türler" />} title="Sayaçlar">
                    <QueryView q={meters} empty="Sayaç yok">
                        {(d) => (
                            <Table rows={d.data} rowKey={(m) => m.id} columns={[
                                { header: "Daire", cell: (m) => m.unit_name ?? "—" },
                                { header: "Tür", cell: (m) => TYPE_LABEL[m.meter_type] ?? m.meter_type },
                                { header: "Seri no", cell: (m) => <span className="font-mono text-xs">{m.serial_number}</span> },
                                { header: "Son okuma", cell: (m) => (m.last_reading_date ? `${num(m.last_reading_value)} (${date(m.last_reading_date)})` : "—") },
                                { header: "Durum", cell: (m) => (m.is_active ? <Badge tone="green">Aktif</Badge> : <Badge>Pasif</Badge>) },
                                { header: "", cell: (m) => canRead && m.is_active ? (
                                    <Button size="sm" onClick={() => setReading({ meter: m, current_value: "", reading_date: today(), reading_type: "MANUAL", meter_replaced: false, reason: "" })}>Okuma gir</Button>
                                ) : null },
                            ]} />
                        )}
                    </QueryView>
                </Card>
            )}

            {tab === "readings" && (
                <Card padded={false} title="Son okumalar">
                    <QueryView q={readings} empty="Okuma yok">
                        {(d) => (
                            <Table rows={d.data} rowKey={(r) => r.id} columns={[
                                { header: "Tarih", cell: (r) => date(r.reading_date) },
                                { header: "Daire", cell: (r) => r.unit_name ?? "—" },
                                { header: "Seri no", cell: (r) => <span className="font-mono text-xs">{r.serial_number}</span> },
                                { header: "Önceki", cell: (r) => num(r.previous_value) },
                                { header: "Güncel", cell: (r) => num(r.current_value) },
                                { header: "Tüketim", cell: (r) => <b>{num(r.consumption)}</b> },
                                { header: "Tür", cell: (r) => (r.reading_type === "ESTIMATED" ? <Badge tone="amber">Tahmini</Badge> : r.reading_type) },
                                { header: "Okuyan", cell: (r) => r.reader_name ?? "—" },
                            ]} />
                        )}
                    </QueryView>
                </Card>
            )}

            {tab === "allocate" && (
                <Card title="Dönem giderini paylaştır">
                    <p className="mb-3 text-sm text-gray-600">
                        Isıtma gideri %70 ölçülen tüketime, %30 kullanım alanına göre paylaştırılır (oranlar mevzuat tablosundan). Sonuç kuruş hassasiyetindedir; paylar toplamı tutara eşittir.
                    </p>
                    <Grid cols={3}>
                        <Field label="Sayaç türü"><Select value={alloc.meter_type} onChange={(e) => setAlloc({ ...alloc, meter_type: e.target.value })} options={METER_TYPES} /></Field>
                        <Field label="Başlangıç" required><Input type="date" value={alloc.from} onChange={(e) => setAlloc({ ...alloc, from: e.target.value })} /></Field>
                        <Field label="Bitiş" required><Input type="date" value={alloc.to} onChange={(e) => setAlloc({ ...alloc, to: e.target.value })} /></Field>
                        <Field label="Toplam gider (TL)" required><Input type="number" step="0.01" min="0.01" value={alloc.total_amount_try} onChange={(e) => setAlloc({ ...alloc, total_amount_try: e.target.value })} /></Field>
                    </Grid>
                    <div className="mt-3">
                        <Button disabled={!canWrite || act.pending || !alloc.from || !alloc.total_amount_try}
                            onClick={async () => {
                                const r = await act.run(() => api.meters.allocate({ ...alloc, total_amount_try: Number(alloc.total_amount_try) }));
                                if (r) setAllocResult(r);
                            }}>
                            Hesapla
                        </Button>
                    </div>
                    {allocResult && (
                        <div className="mt-4 space-y-3">
                            {allocResult.warning && <Notice tone="amber">{allocResult.warning}</Notice>}
                            <Notice tone="blue">{allocResult.basis_note} {allocResult.note}</Notice>
                            <p className="text-sm">Toplam {kurus(allocResult.allocation.total_kurus)} = tüketim payı {kurus(allocResult.allocation.consumption_part_kurus)} + alan payı {kurus(allocResult.allocation.area_part_kurus)}</p>
                            <Table rows={allocResult.allocation.units} rowKey={(u) => u.unit_id} columns={[
                                { header: "Daire", cell: (u) => u.unit_name },
                                { header: "Tüketim", cell: (u) => num(u.consumption) },
                                { header: "Alan (m²)", cell: (u) => num(u.usable_area) },
                                { header: "Pay", cell: (u) => <b>{kurus(u.total_kurus)}</b> },
                            ]} />
                        </div>
                    )}
                </Card>
            )}

            <FormModal open={!!newMeter} onClose={() => setNewMeter(null)} title="Sayaç ekle" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!newMeter) return;
                    const r = await act.run(() => api.meters.create(newMeter), { invalidate: ["meters"], success: "Sayaç kaydedildi" });
                    if (r) setNewMeter(null);
                }}>
                {newMeter && (
                    <Grid>
                        <Field label="Daire" required>
                            <Select required value={newMeter.unit_id} onChange={(e) => setNewMeter({ ...newMeter, unit_id: e.target.value })}
                                options={(units.data?.data ?? []).map((u) => ({ value: u.id, label: `${u.block}-${u.door_number}` }))} placeholder="Seçin" />
                        </Field>
                        <Field label="Tür" required><Select value={newMeter.meter_type} onChange={(e) => setNewMeter({ ...newMeter, meter_type: e.target.value })} options={METER_TYPES} /></Field>
                        <Field label="Seri no" required><Input required value={newMeter.serial_number} onChange={(e) => setNewMeter({ ...newMeter, serial_number: e.target.value })} /></Field>
                        <Field label="Marka"><Input value={newMeter.brand} onChange={(e) => setNewMeter({ ...newMeter, brand: e.target.value })} /></Field>
                    </Grid>
                )}
            </FormModal>

            <FormModal open={!!reading} onClose={() => setReading(null)} title={reading ? `Okuma — ${reading.meter.unit_name ?? ""} ${reading.meter.serial_number}` : ""} pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!reading) return;
                    const r = await act.run(() => api.meters.addReading({
                        meter_id: reading.meter.id, current_value: reading.current_value, reading_date: reading.reading_date,
                        reading_type: reading.reading_type, meter_replaced: reading.meter_replaced, reason: reading.reason || undefined,
                    }), { invalidate: ["meters", "meter-readings"], success: (res) => `Okuma kaydedildi — tüketim ${num(res.reading.consumption)}` });
                    if (r) setReading(null);
                }}>
                {reading && (
                    <>
                        <p className="text-sm text-gray-600">Son endeks: {num(reading.meter.last_reading_value)} ({date(reading.meter.last_reading_date)})</p>
                        <Grid>
                            <Field label="Endeks" required hint="Ondalık ayırıcı , ya da ."><Input required value={reading.current_value} onChange={(e) => setReading({ ...reading, current_value: e.target.value })} /></Field>
                            <Field label="Okuma tarihi"><Input type="date" value={reading.reading_date} onChange={(e) => setReading({ ...reading, reading_date: e.target.value })} /></Field>
                            <Field label="Okuma türü">
                                <Select value={reading.reading_type} onChange={(e) => setReading({ ...reading, reading_type: e.target.value })}
                                    options={[{ value: "MANUAL", label: "Elle" }, { value: "AUTOMATIC", label: "Otomatik" }, { value: "ESTIMATED", label: "Tahmini" }]} />
                            </Field>
                            <Field label="Sayaç değişti mi?" hint="Endeks düştüyse zorunlu; gerekçe ister.">
                                <Select value={reading.meter_replaced ? "1" : "0"} onChange={(e) => setReading({ ...reading, meter_replaced: e.target.value === "1" })} options={[{ value: "0", label: "Hayır" }, { value: "1", label: "Evet" }]} />
                            </Field>
                        </Grid>
                        {reading.meter_replaced && <Field label="Gerekçe" required><Input required value={reading.reason} onChange={(e) => setReading({ ...reading, reason: e.target.value })} /></Field>}
                    </>
                )}
            </FormModal>
        </Page>
    );
}
