"use client";

import { useState } from "react";
import { Plus } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Modal, Notice, Page, QueryView, Select, Table, Tabs, Textarea } from "@/components/ui/kit";
import { dateTime } from "@/lib/format";
import type { Sensor, SensorInput } from "@/lib/types";

const TYPES: Record<string, string> = {
    WATER_LEAK: "Su kaçağı", TEMPERATURE: "Sıcaklık", HUMIDITY: "Nem", SMOKE: "Duman", GAS: "Gaz",
    POWER_OUTAGE: "Elektrik kesintisi", TANK_LEVEL: "Depo seviyesi", ELEVATOR_FAULT: "Asansör arızası", DOOR_OPEN: "Kapı açık", OTHER: "Diğer",
};
const BINARY = new Set(["WATER_LEAK", "SMOKE", "GAS", "POWER_OUTAGE", "ELEVATOR_FAULT", "DOOR_OPEN"]);
const STATE: Record<string, { label: string; tone: "green" | "red" | "amber" | "gray" }> = {
    OK: { label: "Normal", tone: "green" }, ALERT: { label: "Alarm", tone: "red" }, OFFLINE: { label: "Sinyal yok", tone: "amber" },
    NO_DATA: { label: "Veri gelmedi", tone: "gray" }, PASSIVE: { label: "Pasif", tone: "gray" },
};
const ALERT_STATUS: Record<string, string> = { OPEN: "Açık", ACKNOWLEDGED: "Onaylandı", CLOSED: "Kapatıldı" };
const EMPTY: SensorInput = { name: "", sensor_type: "TEMPERATURE", location: "", unit_label: "", min_threshold: null, max_threshold: null, offline_after_minutes: 30 };

/**
 * IoT sensörleri (074, FAZ H.4). Cihaz okumayı kendi anahtarıyla gönderir; eşik dışı değer, tetiklenen
 * ikili sensör ya da kesilen sinyal alarm açar ve işletme ekibine bildirim gider.
 */
export default function SensorsPage() {
    const { canWrite, isStaff } = useRoles();
    const canAct = canWrite || isStaff;
    const act = useAction();
    const [tab, setTab] = useState<"ACTIVE" | "CLOSED">("ACTIVE");
    const sensors = useApi(["sensors"], api.sensors.list);
    const alerts = useApi(["sensor-alerts", tab], () => api.sensors.alerts(tab));
    const [form, setForm] = useState<(SensorInput & { id?: string; is_active?: boolean }) | null>(null);
    const [key, setKey] = useState<{ key: string; note: string } | null>(null);
    const [history, setHistory] = useState<Sensor | null>(null);
    const [closing, setClosing] = useState<{ id: string; note: string } | null>(null);
    const hist = useApi(["sensor-history", history?.id], () => api.sensors.history(history!.id, 24), !!history);
    const inv = ["sensors", "sensor-alerts"];
    const num = (v: string) => (v.trim() === "" ? null : Number(v));

    return (
        <Page title="Sensörler" description="Su kaçağı, sıcaklık, duman, gaz, depo seviyesi gibi sensörler ve alarmları"
            actions={canWrite && <Button onClick={() => setForm({ ...EMPTY })}><Plus className="h-4 w-4" /> Sensör ekle</Button>}>
            <ActionFeedback action={act} />
            <Card title="Alarmlar" padded={false}
                actions={<Tabs tabs={[{ id: "ACTIVE", label: "Açık" }, { id: "CLOSED", label: "Kapatılmış" }]} value={tab} onChange={setTab} />}>
                <QueryView q={alerts} empty={tab === "ACTIVE" ? "Açık alarm yok" : "Kapatılmış alarm yok"}>
                    {(d) => (
                        <Table rows={d.data} rowKey={(a) => a.id} columns={[
                            { header: "Açılış", cell: (a) => dateTime(a.opened_at) },
                            { header: "Sensör", cell: (a) => <span><b>{a.sensor_name}</b><br /><span className="text-xs text-gray-500">{a.type_label}{a.location ? ` · ${a.location}` : ""}</span></span> },
                            { header: "Olay", cell: (a) => <Badge tone={a.kind === "OFFLINE" ? "amber" : "red"}>{a.kind_label}</Badge> },
                            { header: "Değer", cell: (a) => (a.value ?? "—") + (a.threshold != null ? ` (eşik ${a.threshold})` : "") },
                            { header: "Durum", cell: (a) => <span>{ALERT_STATUS[a.status]}{a.normalized_at && a.status !== "CLOSED" ? <Badge tone="green">normale döndü</Badge> : null}</span> },
                            { header: "Kapatma", cell: (a) => (a.closed_at ? `${dateTime(a.closed_at)} · ${a.closed_by}: ${a.close_note}` : a.acknowledged_at ? `Onay: ${a.acknowledged_by}` : "—") },
                            { header: "", cell: (a) => canAct && a.status !== "CLOSED" && (
                                <span className="flex gap-1">
                                    {a.status === "OPEN" && <Button size="sm" variant="secondary" disabled={act.pending}
                                        onClick={() => act.run(() => api.sensors.acknowledge(a.id), { invalidate: inv, success: "Alarm onaylandı" })}>Onayla</Button>}
                                    <Button size="sm" variant="ghost" onClick={() => setClosing({ id: a.id, note: "" })}>Kapat</Button>
                                </span>
                            ) },
                        ]} />
                    )}
                </QueryView>
            </Card>
            <Card title="Sensörler" padded={false}>
                <QueryView q={sensors} empty="Sensör tanımlanmamış">
                    {(d) => (
                        <Table rows={d.data} rowKey={(s) => s.id} columns={[
                            { header: "Ad", cell: (s) => <b>{s.name}</b> },
                            { header: "Tür", cell: (s) => s.type_label },
                            { header: "Konum", cell: (s) => s.location || "—" },
                            { header: "Son değer", cell: (s) => (s.last_value == null ? "—" : s.binary ? (s.last_value >= 1 ? "Tetiklendi" : "Normal") : `${s.last_value} ${s.unit_label ?? ""}`) },
                            { header: "Eşik", cell: (s) => (s.binary ? "1 = tetik" : `${s.min_threshold ?? "—"} / ${s.max_threshold ?? "—"}`) },
                            { header: "Son sinyal", cell: (s) => (s.last_seen_at ? dateTime(s.last_seen_at) : "—") },
                            { header: "Durum", cell: (s) => <Badge tone={STATE[s.state].tone}>{STATE[s.state].label}</Badge> },
                            { header: "", cell: (s) => (
                                <span className="flex flex-wrap gap-1">
                                    <Button size="sm" variant="ghost" onClick={() => setHistory(s)}>Geçmiş</Button>
                                    {canWrite && <Button size="sm" variant="ghost" onClick={() => setForm({ ...s })}>Düzenle</Button>}
                                    {canWrite && <Button size="sm" variant="ghost" disabled={act.pending} onClick={async () => {
                                        if (!window.confirm("Yeni anahtar üretilecek; eski anahtar hemen geçersiz olur. Devam edilsin mi?")) return;
                                        const r = await act.run(() => api.sensors.rotateKey(s.id), { success: "Anahtar yenilendi" });
                                        if (r) setKey({ key: r.device_key, note: r.note });
                                    }}>Anahtarı yenile</Button>}
                                </span>
                            ) },
                        ]} />
                    )}
                </QueryView>
            </Card>
            <Notice tone="blue">
                Cihaz okumayı <code>POST /api/v1/public/sensors/data</code> ucuna <code>X-Device-Key</code> başlığı ve <code>{"{\"value\": sayı}"}</code> gövdesiyle gönderir.
                İkili sensörlerde (kaçak, duman, gaz, kesinti, arıza, kapı) 1 = tetiklendi, 0 = normaldir. Alarm bildirimi yönetime ve görevlilere gider; sakinlere gitmez.
            </Notice>

            <FormModal open={!!form} onClose={() => setForm(null)} title={form?.id ? "Sensörü düzenle" : "Sensör ekle"} pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!form) return;
                    const body: SensorInput & { is_active?: boolean } = { name: form.name, sensor_type: form.sensor_type, location: form.location, unit_label: form.unit_label,
                        min_threshold: BINARY.has(form.sensor_type) ? null : form.min_threshold, max_threshold: BINARY.has(form.sensor_type) ? null : form.max_threshold,
                        offline_after_minutes: form.offline_after_minutes, ...(form.id ? { is_active: form.is_active } : {}) };
                    if (form.id) {
                        const r = await act.run(() => api.sensors.update(form.id!, body), { invalidate: inv, success: "Sensör güncellendi" });
                        if (r) setForm(null);
                    } else {
                        const r = await act.run(() => api.sensors.create(body), { invalidate: inv, success: "Sensör eklendi" });
                        if (r) { setForm(null); setKey({ key: r.device_key, note: r.note }); }
                    }
                }}>
                {form && (
                    <>
                        <Grid>
                            <Field label="Ad" required><Input required value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="Kazan dairesi sıcaklık" /></Field>
                            <Field label="Tür" required><Select value={form.sensor_type} onChange={(e) => setForm({ ...form, sensor_type: e.target.value })}
                                options={Object.entries(TYPES).map(([value, label]) => ({ value, label }))} /></Field>
                            <Field label="Konum"><Input value={form.location ?? ""} onChange={(e) => setForm({ ...form, location: e.target.value })} placeholder="B blok bodrum" /></Field>
                            {!BINARY.has(form.sensor_type) && <Field label="Birim"><Input value={form.unit_label ?? ""} onChange={(e) => setForm({ ...form, unit_label: e.target.value })} placeholder="°C, %, cm" /></Field>}
                            {!BINARY.has(form.sensor_type) && <Field label="Alt eşik" hint="Altına inerse alarm"><Input type="number" step="any" value={form.min_threshold ?? ""} onChange={(e) => setForm({ ...form, min_threshold: num(e.target.value) })} /></Field>}
                            {!BINARY.has(form.sensor_type) && <Field label="Üst eşik" hint="Üstüne çıkarsa alarm"><Input type="number" step="any" value={form.max_threshold ?? ""} onChange={(e) => setForm({ ...form, max_threshold: num(e.target.value) })} /></Field>}
                            <Field label="Sinyal kesilme süresi (dk)" required hint="Bu süre veri gelmezse alarm açılır (2-1440)">
                                <Input type="number" min={2} max={1440} required value={form.offline_after_minutes ?? 30} onChange={(e) => setForm({ ...form, offline_after_minutes: Number(e.target.value) })} /></Field>
                            {form.id && <Field label="Durum"><Select value={form.is_active === false ? "false" : "true"} onChange={(e) => setForm({ ...form, is_active: e.target.value === "true" })}
                                options={[{ value: "true", label: "Etkin" }, { value: "false", label: "Pasif (izlenmez)" }]} /></Field>}
                        </Grid>
                    </>
                )}
            </FormModal>

            <Modal open={!!key} onClose={() => setKey(null)} title="Cihaz anahtarı">
                {key && (
                    <div className="space-y-3 text-sm">
                        <Notice tone="amber">Bu anahtar bir daha gösterilmez. Şimdi cihaza girin.</Notice>
                        <pre className="select-all overflow-x-auto rounded bg-gray-100 p-3 font-mono dark:bg-gray-900">{key.key}</pre>
                        <p className="text-gray-600 dark:text-gray-300">{key.note}</p>
                    </div>
                )}
            </Modal>

            <Modal open={!!history} onClose={() => setHistory(null)} title={history ? `${history.name} — son 24 saat` : ""}>
                <QueryView q={hist} empty="Son 24 saatte okuma yok">
                    {(d) => (
                        <div className="max-h-96 overflow-y-auto">
                            {d.truncated && <Notice tone="amber">Liste 2000 okumayla sınırlandı.</Notice>}
                            <Table rows={d.data} rowKey={(r) => r.recorded_at} columns={[
                                { header: "Zaman", cell: (r) => dateTime(r.recorded_at) },
                                { header: "Değer", cell: (r) => (history?.binary ? (r.value >= 1 ? "Tetiklendi" : "Normal") : `${r.value} ${history?.unit_label ?? ""}`) },
                            ]} />
                        </div>
                    )}
                </QueryView>
            </Modal>

            <FormModal open={!!closing} onClose={() => setClosing(null)} title="Alarmı kapat" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!closing) return;
                    const r = await act.run(() => api.sensors.close(closing.id, closing.note), { invalidate: inv, success: "Alarm kapatıldı" });
                    if (r) setClosing(null);
                }}>
                {closing && <Field label="Ne yapıldı?" required><Textarea required value={closing.note} onChange={(e) => setClosing({ ...closing, note: e.target.value })} /></Field>}
            </FormModal>
        </Page>
    );
}
