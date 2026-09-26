"use client";

import { useState } from "react";
import { Plus } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Button, Card, Field, FormModal, Grid, Input, Page, QueryView, Select, Stats, StatusBadge, Table } from "@/components/ui/kit";
import { dateTime, num } from "@/lib/format";
import { opts, PACKAGE_STATUS } from "@/lib/labels";
import type { Package } from "@/lib/types";

/**
 * Kargo kabul ve teslim. Teslim alınan kargo ilgili dairenin sakinlerine
 * uygulama içi bildirimle duyurulur; bildirim içeriğine gönderici/takip no
 * YAZILMAZ (kilit ekranında görünebilir — KVKK m.4 ölçülülük).
 */
export default function PackagesPage() {
    const [status, setStatus] = useState("");
    const [pending, setPending] = useState(true);
    const list = useApi(["packages", status, pending], () => api.packages.list({ status, pending: pending ? "true" : undefined }));
    const summary = useApi(["packages", "summary"], api.packages.summary);
    const units = useApi(["units"], api.identity.units);
    const act = useAction();
    const [open, setOpen] = useState(false);
    const blank = { unit_id: "", recipient_name: "", carrier: "", tracking_number: "", package_type: "PACKAGE", storage_location: "", notes: "" };
    const [form, setForm] = useState(blank);
    const [delivering, setDelivering] = useState<Package | null>(null);
    const [toName, setToName] = useState("");
    const [returning, setReturning] = useState<Package | null>(null);
    const [reason, setReason] = useState("");
    const s = summary.data;

    return (
        <Page title="Kargo" description="Site yönetimine bırakılan kargoların kabulü, sakine bildirimi ve teslimi."
            actions={<Button onClick={() => { setForm(blank); setOpen(true); }}><Plus className="h-4 w-4" /> Kargo kabul</Button>}>
            <ActionFeedback action={act} />
            <Stats items={[
                { label: "Bekleyen", value: num(s?.pending), tone: "amber" },
                { label: "Haber verilmemiş", value: num(s?.not_notified), tone: "red" },
                { label: "7 günden eski", value: num(s?.waiting_over_7_days), hint: s ? `En eski ${s.oldest_waiting_days} gün` : undefined },
                { label: "Teslim edilen", value: num(s?.delivered), tone: "green" },
            ]} />
            <Card padded={false} title="Kargolar" actions={
                <div className="flex items-center gap-2">
                    <label className="flex items-center gap-1 text-sm"><input type="checkbox" checked={pending} onChange={(e) => setPending(e.target.checked)} /> Yalnız bekleyenler</label>
                    <Select value={status} onChange={(e) => setStatus(e.target.value)} options={opts(PACKAGE_STATUS)} placeholder="Tüm durumlar" />
                </div>
            }>
                <QueryView q={list} empty="Kargo yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(p) => p.id} columns={[
                            { header: "Daire", cell: (p) => p.unit_name ?? "—" },
                            { header: "Alıcı", cell: (p) => p.recipient_name },
                            { header: "Firma / takip", cell: (p) => [p.carrier, p.tracking_number].filter(Boolean).join(" · ") || "—" },
                            { header: "Kabul", cell: (p) => dateTime(p.received_at) },
                            { header: "Bekleme", cell: (p) => (p.waiting_days !== undefined ? `${p.waiting_days} gün` : "—") },
                            { header: "Durum", cell: (p) => <StatusBadge value={p.status} map={PACKAGE_STATUS} /> },
                            { header: "", cell: (p) => (p.status === "RECEIVED" || p.status === "NOTIFIED") ? (
                                <div className="flex gap-1">
                                    <Button size="sm" variant="ghost" disabled={act.pending} onClick={() => act.run(() => api.packages.notify(p.id), { invalidate: ["packages"], success: "Haber verildiği kaydedildi" })}>
                                        {p.notification_sent ? "Hatırlat" : "Haber verildi"}
                                    </Button>
                                    <Button size="sm" onClick={() => { setToName(p.recipient_name); setDelivering(p); }}>Teslim et</Button>
                                    <Button size="sm" variant="ghost" onClick={() => { setReason(""); setReturning(p); }}>İade</Button>
                                </div>
                            ) : p.delivered_to_name ? <span className="text-xs text-gray-500">Teslim alan: {p.delivered_to_name}</span> : null },
                        ]} />
                    )}
                </QueryView>
            </Card>

            <FormModal open={open} onClose={() => setOpen(false)} title="Kargo kabul" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    const r = await act.run(() => api.packages.create(form), {
                        invalidate: ["packages"],
                        success: (res) => res.notification ? `Kargo kaydedildi — sakinlere bildirim: ${res.notification.sent} gönderildi` : "Kargo kaydedildi",
                    });
                    if (r) setOpen(false);
                }}>
                <Grid>
                    <Field label="Daire" required>
                        <Select required value={form.unit_id} onChange={(e) => setForm({ ...form, unit_id: e.target.value })} placeholder="Seçin"
                            options={(units.data?.data ?? []).map((u) => ({ value: u.id, label: `${u.block}-${u.door_number}` }))} />
                    </Field>
                    <Field label="Alıcı adı" required><Input required value={form.recipient_name} onChange={(e) => setForm({ ...form, recipient_name: e.target.value })} /></Field>
                    <Field label="Kargo firması"><Input value={form.carrier} onChange={(e) => setForm({ ...form, carrier: e.target.value })} /></Field>
                    <Field label="Takip no"><Input value={form.tracking_number} onChange={(e) => setForm({ ...form, tracking_number: e.target.value })} /></Field>
                    <Field label="Tür"><Select value={form.package_type} onChange={(e) => setForm({ ...form, package_type: e.target.value })} options={[{ value: "PACKAGE", label: "Paket" }, { value: "ENVELOPE", label: "Zarf" }, { value: "LARGE", label: "Büyük" }]} /></Field>
                    <Field label="Konulduğu yer"><Input value={form.storage_location} onChange={(e) => setForm({ ...form, storage_location: e.target.value })} /></Field>
                </Grid>
            </FormModal>
            <FormModal open={!!delivering} onClose={() => setDelivering(null)} title="Teslim et" submitLabel="Teslim et" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!delivering) return;
                    const r = await act.run(() => api.packages.deliver(delivering.id, toName), { invalidate: ["packages"], success: "Teslim kaydedildi" });
                    if (r) setDelivering(null);
                }}>
                <Field label="Teslim alan kişi" required hint="Kayıp kargoda sorumluluk bu kayda dayanır."><Input required value={toName} onChange={(e) => setToName(e.target.value)} /></Field>
            </FormModal>
            <FormModal open={!!returning} onClose={() => setReturning(null)} title="Kargo firmasına iade" submitLabel="İade et" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!returning) return;
                    const r = await act.run(() => api.packages.returnToCarrier(returning.id, reason), { invalidate: ["packages"], success: "İade kaydedildi" });
                    if (r) setReturning(null);
                }}>
                <Field label="Gerekçe" required><Input required value={reason} onChange={(e) => setReason(e.target.value)} /></Field>
            </FormModal>
        </Page>
    );
}
