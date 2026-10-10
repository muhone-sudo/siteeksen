"use client";

// Geçiş cihazı canlılık izleme (057, Apsiyon BUG-08): cihaz listesi, çevrimdışı olaylar,
// cihaz ekleme (anahtar bir kez gösterilir) ve pasife alma.

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Notice, QueryView, Select, Table } from "@/components/ui/kit";
import { dateTime } from "@/lib/format";

const KINDS = [
    { value: "PTS_CAMERA", label: "Plaka tanıma kamerası" },
    { value: "BARRIER", label: "Bariyer" },
    { value: "TURNSTILE", label: "Turnike" },
    { value: "INTERCOM", label: "Kapı telefonu" },
    { value: "OTHER", label: "Diğer" },
];
const KIND_LABEL = Object.fromEntries(KINDS.map((k) => [k.value, k.label]));

export function DevicesCard() {
    const devices = useApi(["devices"], api.parking.devices);
    const incidents = useApi(["devices", "incidents"], api.parking.deviceIncidents);
    const act = useAction();
    const { canWrite } = useRoles();
    const [form, setForm] = useState<null | { name: string; kind: string; location: string; heartbeat_interval_sec: string }>(null);
    const [issued, setIssued] = useState<null | { device_key: string; note: string }>(null);
    const offline = (devices.data?.data ?? []).filter((d) => d.is_active && !d.online);

    return (
        <>
            <ActionFeedback action={act} />
            {offline.length > 0 && (
                <Notice tone="red" title={`${offline.length} cihaz çevrimdışı`}>
                    {offline.map((d) => d.name).join(", ")}. Geçişleri görevli elle kaydetmelidir; cihazı ve bağlantısını kontrol edin.
                </Notice>
            )}
            <Card padded={false} title="Geçiş cihazları"
                actions={canWrite && <Button size="sm" onClick={() => setForm({ name: "", kind: "PTS_CAMERA", location: "", heartbeat_interval_sec: "60" })}>Cihaz ekle</Button>}>
                <QueryView q={devices} empty="Kayıtlı cihaz yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(x) => x.id} columns={[
                            { header: "Cihaz", cell: (x) => <><b>{x.name}</b><div className="text-xs text-gray-500">{KIND_LABEL[x.kind] ?? x.kind}{x.location ? ` · ${x.location}` : ""}</div></> },
                            { header: "Durum", cell: (x) => (!x.is_active ? <Badge>Pasif</Badge> : x.online ? <Badge tone="green">Çevrimiçi</Badge> : <Badge tone="red">Çevrimdışı</Badge>) },
                            { header: "Son sinyal", cell: (x) => (x.last_seen_at ? dateTime(x.last_seen_at) : "Hiç sinyal yok") },
                            { header: "Eşik", cell: (x) => `${x.heartbeat_interval_sec} sn aralık · ${x.offline_after_sec} sn` },
                            { header: "Bildirdiği durum", cell: (x) => x.last_status ?? "—" },
                            { header: "", cell: (x) => canWrite && x.is_active ? (
                                <Button size="sm" variant="ghost" disabled={act.pending}
                                    onClick={() => act.run(() => api.parking.deactivateDevice(x.id), { invalidate: ["devices"], success: "Cihaz pasife alındı" })}>Pasife al</Button>
                            ) : null },
                        ]} />
                    )}
                </QueryView>
            </Card>
            <Card padded={false} title="Çevrimdışı olayları">
                <QueryView q={incidents} empty="Olay yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(x) => x.id} columns={[
                            { header: "Cihaz", cell: (x) => x.device_name },
                            { header: "Son sinyal", cell: (x) => (x.last_seen_at ? dateTime(x.last_seen_at) : "—") },
                            { header: "Fark edildi", cell: (x) => dateTime(x.detected_at) },
                            { header: "Düzeldi", cell: (x) => (x.recovered_at ? dateTime(x.recovered_at) : <Badge tone="red">Açık</Badge>) },
                        ]} />
                    )}
                </QueryView>
            </Card>

            <FormModal open={!!form} onClose={() => setForm(null)} title="Geçiş cihazı ekle" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!form) return;
                    const r = await act.run(() => api.parking.createDevice({ ...form, heartbeat_interval_sec: Number(form.heartbeat_interval_sec) || 60 }),
                        { invalidate: ["devices"], success: "Cihaz kaydedildi" });
                    if (r) {
                        setForm(null);
                        setIssued({ device_key: r.device_key, note: r.note });
                    }
                }}>
                {form && (
                    <Grid>
                        <Field label="Ad" required><Input required value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} /></Field>
                        <Field label="Tür"><Select value={form.kind} onChange={(e) => setForm({ ...form, kind: e.target.value })} options={KINDS} /></Field>
                        <Field label="Konum"><Input value={form.location} onChange={(e) => setForm({ ...form, location: e.target.value })} /></Field>
                        <Field label="Sinyal aralığı (sn)" hint="Çevrimdışı eşiği bunun 3 katıdır."><Input type="number" min="10" max="3600" value={form.heartbeat_interval_sec} onChange={(e) => setForm({ ...form, heartbeat_interval_sec: e.target.value })} /></Field>
                    </Grid>
                )}
            </FormModal>
            <FormModal open={!!issued} onClose={() => setIssued(null)} title="Cihaz anahtarı" onSubmit={() => setIssued(null)}>
                {issued && (
                    <>
                        <p className="break-all rounded bg-gray-100 p-3 font-mono text-sm dark:bg-gray-800">{issued.device_key}</p>
                        <Notice tone="amber">{issued.note}</Notice>
                    </>
                )}
            </FormModal>
        </>
    );
}
