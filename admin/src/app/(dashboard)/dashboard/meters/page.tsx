"use client";

import { useState } from "react";
import Link from "next/link";
import { Plus } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Notice, Page, QueryView, Select, Table, Tabs, Textarea } from "@/components/ui/kit";
import { date, kurus, num, today } from "@/lib/format";
import { METER_TYPES } from "@/lib/labels";
import type { Allocation, Meter, Outlier, StatementObjection } from "@/lib/types";

const TYPE_LABEL = Object.fromEntries(METER_TYPES.map((t) => [t.value, t.label]));

/** "tarih · endeks" — pusuladaki ilk/son okuma. */
function readingAt(d?: string, v?: string) {
    return d ? `${date(d)} · ${num(v)}` : "—";
}

export default function MetersPage() {
    const [tab, setTab] = useState<"meters" | "readings" | "allocate" | "statements" | "objections">("meters");
    const [type, setType] = useState("");
    const meters = useApi(["meters", type], () => api.meters.list({ meter_type: type }));
    const units = useApi(["units"], api.identity.units);
    const readings = useApi(["meter-readings"], () => api.meters.readings(), tab === "readings");
    const statements = useApi(["statements"], api.meters.statements, tab === "statements");
    const objections = useApi(["objections"], () => api.meters.objections(), tab === "objections");
    const [answer, setAnswer] = useState<null | { o: StatementObjection; decision: "ACCEPTED" | "REJECTED"; response: string }>(null);
    const act = useAction();
    const { canWrite, roles } = useRoles();
    const canRead = canWrite || roles.includes("STAFF");
    const [newMeter, setNewMeter] = useState<null | { unit_id: string; meter_type: string; serial_number: string; brand: string }>(null);
    const [reading, setReading] = useState<null | { meter: Meter; current_value: string; reading_date: string; reading_type: string; confirm_anomaly: boolean }>(null);
    const [replace, setReplace] = useState<null | { meter: Meter; removal_value: string; replaced_on: string; new_serial_number: string; new_initial_value: string; reason: string }>(null);
    const [alloc, setAlloc] = useState({ meter_type: "HEAT", from: "", to: today(), total_amount_try: "", publish: false, confirm_outliers: false });
    const areaCheck = useApi(["area-check"], api.meters.areaCheck, tab === "allocate" && canWrite);
    const [allocResult, setAllocResult] = useState<{ allocation: Allocation; basis_note: string; note: string; warning?: string; allocation_id?: string; outliers?: Outlier[]; outlier_warning?: string } | null>(null);
    // Sunucu olağandışı tüketimi (önceki tüketimin 2,5 katı) teyitsiz kaydetmez (056).
    const anomaly = !!reading && !!act.error && act.error.includes("Tüketim sapması");

    return (
        <Page
            title="Sayaç ve ısı payı"
            description="Sayaç okuma, endeks zinciri ve Merkezi Isıtma Yönetmeliğine göre gider paylaştırma."
            actions={canWrite && <Button onClick={() => setNewMeter({ unit_id: "", meter_type: "HEAT", serial_number: "", brand: "" })}><Plus className="h-4 w-4" /> Sayaç ekle</Button>}
        >
            <ActionFeedback action={act} />
            <Tabs tabs={[{ id: "meters", label: "Sayaçlar" }, { id: "readings", label: "Okumalar" }, { id: "allocate", label: "Gider paylaştırma" }, { id: "statements", label: "Tüketim pusulaları" }, { id: "objections", label: "Pusula itirazları" }]} value={tab} onChange={setTab} />

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
                                    <div className="flex gap-1">
                                        <Button size="sm" onClick={() => { act.clear(); setReading({ meter: m, current_value: "", reading_date: today(), reading_type: "MANUAL", confirm_anomaly: false }); }}>Okuma gir</Button>
                                        <Button size="sm" variant="secondary" onClick={() => { act.clear(); setReplace({ meter: m, removal_value: "", replaced_on: today(), new_serial_number: "", new_initial_value: "0", reason: "" }); }}>Sayaç değiştir</Button>
                                    </div>
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
                        Isıtma gideri %70 ölçülen tüketime, %30 bağımsız bölümlerin net (kapalı) kullanım alanına göre paylaştırılır (oranlar mevzuat tablosundan). Sonuç kuruş hassasiyetindedir; paylar toplamı tutara eşittir.
                    </p>
                    {alloc.meter_type === "HEAT" && areaCheck.data && !areaCheck.data.ready && (
                        <Notice tone="amber" title={`${areaCheck.data.missing.length} bölümün net kullanım alanı eksik`}>
                            {areaCheck.data.missing.slice(0, 20).map((m) => m.unit).join(", ")}{areaCheck.data.missing.length > 20 ? " …" : ""}. {areaCheck.data.note}{" "}
                            <Link href="/dashboard/units" className="font-medium underline">Bağımsız Bölümler ekranında tamamlayın.</Link>
                        </Notice>
                    )}
                    <Grid cols={3}>
                        <Field label="Sayaç türü"><Select value={alloc.meter_type} onChange={(e) => setAlloc({ ...alloc, meter_type: e.target.value })} options={METER_TYPES} /></Field>
                        <Field label="Başlangıç" required><Input type="date" value={alloc.from} onChange={(e) => setAlloc({ ...alloc, from: e.target.value })} /></Field>
                        <Field label="Bitiş" required><Input type="date" value={alloc.to} onChange={(e) => setAlloc({ ...alloc, to: e.target.value })} /></Field>
                        <Field label="Toplam gider (TL)" required><Input type="number" step="0.01" min="0.01" value={alloc.total_amount_try} onChange={(e) => setAlloc({ ...alloc, total_amount_try: e.target.value })} /></Field>
                    </Grid>
                    <label className="mt-3 flex items-start gap-2 text-sm">
                        <input type="checkbox" className="mt-1" checked={alloc.publish} onChange={(e) => setAlloc({ ...alloc, publish: e.target.checked })} />
                        <span>Sakinlere <b>yayımla</b> — her bölümün pusulası (ilk/son endeks, tüketim, tüketim ve alan payı) saklanır ve sonradan değiştirilemez. Okuması eksik bölüm varken yayımlanmaz.</span>
                    </label>
                    {alloc.publish && (allocResult?.outliers?.length || act.error?.includes("medyan")) ? (
                        <label className="mt-2 flex items-start gap-2 rounded-lg bg-amber-50 p-3 text-sm text-amber-900 dark:bg-amber-900/20 dark:text-amber-200">
                            <input type="checkbox" className="mt-1" checked={alloc.confirm_outliers} onChange={(e) => setAlloc({ ...alloc, confirm_outliers: e.target.checked })} />
                            <span>Site medyanının 3 katını aşan bölümlerin okumalarını kontrol ettim; doğrular. Yayımı teyit ediyorum (teyit eden ve bölümler pusulayla saklanır).</span>
                        </label>
                    ) : null}
                    <div className="mt-3">
                        <Button disabled={!canWrite || act.pending || !alloc.from || !alloc.total_amount_try}
                            onClick={async () => {
                                const r = await act.run(() => api.meters.allocate({ ...alloc, total_amount_try: Number(alloc.total_amount_try) }),
                                    alloc.publish ? { invalidate: ["statements"] } : undefined);
                                if (r) setAllocResult(r);
                            }}>
                            {alloc.publish ? "Hesapla ve yayımla" : "Hesapla"}
                        </Button>
                    </div>
                    {allocResult && (
                        <div className="mt-4 space-y-3">
                            {allocResult.warning && <Notice tone="amber">{allocResult.warning}</Notice>}
                            {!!allocResult.outliers?.length && (
                                <Notice tone="amber" title="Olağandışı tüketim — site medyanının 3 katından fazla">
                                    {allocResult.outliers.map((o) => `${o.unit_name}: ${num(o.intensity)}${o.basis === "AREA" ? "/m²" : ""} (medyan ${num(o.median)}, ${o.ratio} kat)`).join(" · ")}. {allocResult.outlier_warning}
                                </Notice>
                            )}
                            <Notice tone={allocResult.allocation_id ? "green" : "blue"}>{allocResult.basis_note} {allocResult.note}</Notice>
                            <p className="text-sm">Toplam {kurus(allocResult.allocation.total_kurus)} = tüketim payı {kurus(allocResult.allocation.consumption_part_kurus)} + alan payı {kurus(allocResult.allocation.area_part_kurus)}</p>
                            <Table rows={allocResult.allocation.units} rowKey={(u) => u.unit_id} columns={[
                                { header: "Daire", cell: (u) => u.unit_name },
                                { header: "İlk okuma", cell: (u) => readingAt(u.first_date, u.first_value) },
                                { header: "Son okuma", cell: (u) => <>{readingAt(u.last_date, u.last_value)} {u.meter_replaced && <Badge tone="amber">Sayaç değişti</Badge>}</> },
                                { header: "Tüketim", cell: (u) => num(u.consumption) },
                                { header: "Alan (m²)", cell: (u) => num(u.usable_area) },
                                { header: "Pay", cell: (u) => <b>{kurus(u.total_kurus)}</b> },
                            ]} />
                        </div>
                    )}
                </Card>
            )}

            {tab === "statements" && (
                <Card padded={false} title="Yayımlanmış tüketim pusulaları">
                    <QueryView q={statements} empty="Yayımlanmış paylaştırma yok">
                        {(d) => (
                            <Table rows={d.data} rowKey={(a) => a.id} columns={[
                                { header: "Tür", cell: (a) => TYPE_LABEL[a.meter_type] ?? a.meter_type },
                                { header: "Dönem", cell: (a) => `${date(a.period_from)} – ${date(a.period_to)}` },
                                { header: "Toplam gider", cell: (a) => kurus(a.total_kurus) },
                                { header: "Paylaşım", cell: (a) => `tüketim %${num(a.consumption_share_pct)} · alan %${num(a.area_share_pct)}` },
                                { header: "Yayım", cell: (a) => date(a.published_at) },
                                { header: "", cell: (a) => <Button size="sm" variant="secondary" disabled={act.pending} onClick={() => act.run(() => api.meters.statementPdf(a.id))}>PDF</Button> },
                            ]} />
                        )}
                    </QueryView>
                </Card>
            )}

            {tab === "objections" && (
                <Card padded={false} title="Tüketim pusulasına itirazlar">
                    <QueryView q={objections} empty="İtiraz yok">
                        {(d) => (
                            <Table rows={d.data} rowKey={(o) => o.id} columns={[
                                { header: "Daire / pusula", cell: (o) => <>{o.unit} · {TYPE_LABEL[o.meter_type] ?? o.meter_type}<div className="text-xs text-gray-500">{date(o.period_from)} – {date(o.period_to)} · {kurus(o.total_kurus)}</div></> },
                                { header: "İtiraz eden", cell: (o) => <>{o.user_name}<div className="text-xs text-gray-500">{date(o.created_at)}</div></> },
                                { header: "Gerekçe", cell: (o) => o.reason },
                                { header: "Durum", cell: (o) => o.status === "OPEN" ? <Badge tone="amber">Yanıt bekliyor</Badge>
                                    : <><Badge tone={o.status === "ACCEPTED" ? "green" : "red"}>{o.status === "ACCEPTED" ? "Kabul" : "Ret"}</Badge><div className="text-xs text-gray-500">{o.response} — {o.responded_by_name}</div></> },
                                { header: "", cell: (o) => canWrite && o.status === "OPEN" ? <Button size="sm" onClick={() => { act.clear(); setAnswer({ o, decision: "ACCEPTED", response: "" }); }}>Yanıtla</Button> : null },
                            ]} />
                        )}
                    </QueryView>
                </Card>
            )}

            <FormModal open={!!answer} onClose={() => setAnswer(null)} title={answer ? `İtiraz — ${answer.o.unit}` : ""} pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!answer) return;
                    const r = await act.run(() => api.meters.respondObjection(answer.o.id, answer.decision, answer.response), { invalidate: ["objections"], success: (x) => x.message });
                    if (r) setAnswer(null);
                }}>
                {answer && (
                    <>
                        <Notice tone="blue">Gerekçe: {answer.o.reason}</Notice>
                        <Field label="Karar" required>
                            <Select value={answer.decision} onChange={(e) => setAnswer({ ...answer, decision: e.target.value as "ACCEPTED" | "REJECTED" })}
                                options={[{ value: "ACCEPTED", label: "Kabul" }, { value: "REJECTED", label: "Ret" }]} />
                        </Field>
                        <Field label="Açıklama" required hint="Kabulde düzeltmenin nasıl yapılacağını yazın (yeniden okuma, alacak dekontu vb.). Yayımlanmış pusula değişmez.">
                            <Textarea required minLength={5} value={answer.response} onChange={(e) => setAnswer({ ...answer, response: e.target.value })} />
                        </Field>
                    </>
                )}
            </FormModal>

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
                        reading_type: reading.reading_type, confirm_anomaly: reading.confirm_anomaly || undefined,
                    }), { invalidate: ["meters", "meter-readings"], success: (res) => `Okuma kaydedildi — tüketim ${num(res.reading.consumption)}` });
                    if (r) setReading(null);
                }}>
                {reading && (
                    <>
                        <p className="text-sm text-gray-600">Son endeks: {num(reading.meter.last_reading_value)} ({date(reading.meter.last_reading_date)}). Endeks düştüyse sayaç değişmiştir: “Sayaç değiştir” ile söküm ve montaj endeksini girin.</p>
                        <Grid>
                            <Field label="Endeks" required hint="Ondalık ayırıcı , ya da ."><Input required value={reading.current_value} onChange={(e) => setReading({ ...reading, current_value: e.target.value, confirm_anomaly: false })} /></Field>
                            <Field label="Okuma tarihi"><Input type="date" value={reading.reading_date} onChange={(e) => setReading({ ...reading, reading_date: e.target.value })} /></Field>
                            <Field label="Okuma türü">
                                <Select value={reading.reading_type} onChange={(e) => setReading({ ...reading, reading_type: e.target.value })}
                                    options={[{ value: "MANUAL", label: "Elle" }, { value: "AUTOMATIC", label: "Otomatik" }, { value: "ESTIMATED", label: "Tahmini" }]} />
                            </Field>
                        </Grid>
                        {anomaly && (
                            <label className="flex items-start gap-2 rounded-lg bg-amber-50 p-3 text-sm text-amber-900 dark:bg-amber-900/20 dark:text-amber-200">
                                <input type="checkbox" className="mt-1" checked={reading.confirm_anomaly} onChange={(e) => setReading({ ...reading, confirm_anomaly: e.target.checked })} />
                                <span>Sayacı yeniden kontrol ettim; endeks doğru. Olağandışı tüketimi teyit ediyorum (oran ve teyit eden kayda geçer).</span>
                            </label>
                        )}
                    </>
                )}
            </FormModal>

            <FormModal open={!!replace} onClose={() => setReplace(null)} title={replace ? `Sayaç değişimi — ${replace.meter.unit_name ?? ""} ${replace.meter.serial_number}` : ""} pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!replace) return;
                    const { meter, ...body } = replace;
                    const r = await act.run(() => api.meters.replace(meter.id, body), { invalidate: ["meters", "meter-readings"], success: "Sayaç değiştirildi" });
                    if (r) setReplace(null);
                }}>
                {replace && (
                    <>
                        <p className="text-sm text-gray-600">
                            Eski sayacın söküm endeksi bir okuma olarak yazılır ve sayaç pasife alınır; yeni sayaç montaj endeksiyle açılır. Dönem tüketimi iki sayaçtan toplanır: (söküm − son okuma) + (yeni son okuma − montaj). Son endeks: {num(replace.meter.last_reading_value)} ({date(replace.meter.last_reading_date)}).
                        </p>
                        <Grid>
                            <Field label="Eski sayacın söküm endeksi" required><Input required value={replace.removal_value} onChange={(e) => setReplace({ ...replace, removal_value: e.target.value })} /></Field>
                            <Field label="Değişim tarihi" required><Input type="date" required value={replace.replaced_on} onChange={(e) => setReplace({ ...replace, replaced_on: e.target.value })} /></Field>
                            <Field label="Yeni sayacın seri no" required><Input required value={replace.new_serial_number} onChange={(e) => setReplace({ ...replace, new_serial_number: e.target.value })} /></Field>
                            <Field label="Yeni sayacın montaj endeksi" required><Input required value={replace.new_initial_value} onChange={(e) => setReplace({ ...replace, new_initial_value: e.target.value })} /></Field>
                        </Grid>
                        <Field label="Gerekçe" required><Input required value={replace.reason} onChange={(e) => setReplace({ ...replace, reason: e.target.value })} /></Field>
                    </>
                )}
            </FormModal>
        </Page>
    );
}
