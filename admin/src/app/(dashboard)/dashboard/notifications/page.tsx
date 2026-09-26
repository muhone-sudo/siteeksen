"use client";

import { useState } from "react";
import { Send } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Notice, Page, QueryView, Select, Stats, StatusBadge, Table, Tabs, Textarea } from "@/components/ui/kit";
import { dateTime, num } from "@/lib/format";
import { NOTIFY_STATUS, opts } from "@/lib/labels";

const CHANNELS = [
    { value: "IN_APP", label: "Uygulama içi" },
    { value: "PUSH", label: "Anlık bildirim" },
    { value: "SMS", label: "SMS" },
    { value: "EMAIL", label: "E-posta" },
];
const CH_LABEL = Object.fromEntries(CHANNELS.map((c) => [c.value, c.label]));

/**
 * Bildirim merkezi. Push/SMS/e-posta sağlayıcıları BAĞLI DEĞİLDİR: bu kanallara
 * yazılan bildirim "kuyrukta" bekler, gönderildi sayılmaz. Ticari ileti
 * (COMMERCIAL) alıcının açık onayı yoksa engellenir (6563 s. Kanun m.6).
 */
export default function NotificationsPage() {
    const [tab, setTab] = useState<"outbox" | "prefs">("outbox");
    const [status, setStatus] = useState("");
    const [channel, setChannel] = useState("");
    const outbox = useApi(["notifications", "outbox", status, channel], () => api.notifications.outbox({ status, channel }));
    const summary = useApi(["notifications", "summary"], api.notifications.summary);
    const prefs = useApi(["notifications", "prefs"], api.notifications.preferences, tab === "prefs");
    const residents = useApi(["residents", "", ""], () => api.identity.residents());
    const act = useAction();
    const [open, setOpen] = useState(false);
    const [form, setForm] = useState({ recipient_user_id: "", channel: "IN_APP", category: "TRANSACTIONAL", subject: "", body: "" });

    const s = summary.data?.summary;
    return (
        <Page title="Bildirimler" description="Giden bildirim kuyruğu ve kanal durumu."
            actions={<Button onClick={() => setOpen(true)}><Send className="h-4 w-4" /> Bildirim gönder</Button>}>
            <ActionFeedback action={act} />
            <Stats items={[
                { label: "Toplam", value: num(s?.total) },
                { label: "Gönderildi", value: num(s?.sent), tone: "green" },
                { label: "Kuyrukta", value: num(s?.pending), tone: "amber", hint: s?.pending_note },
                { label: "Engellendi / başarısız", value: `${num(s?.suppressed)} / ${num(s?.failed)}`, tone: "red" },
            ]} />
            <Tabs tabs={[{ id: "outbox", label: "Giden kutusu" }, { id: "prefs", label: "Kendi tercihlerim" }]} value={tab} onChange={setTab} />
            {tab === "outbox" && (
                <Card padded={false} actions={
                    <div className="flex gap-2">
                        <Select value={status} onChange={(e) => setStatus(e.target.value)} options={opts(NOTIFY_STATUS)} placeholder="Tüm durumlar" />
                        <Select value={channel} onChange={(e) => setChannel(e.target.value)} options={CHANNELS} placeholder="Tüm kanallar" />
                    </div>
                } title="Kuyruk">
                    <QueryView q={outbox} empty="Bildirim yok">
                        {(d) => (
                            <Table rows={d.data} rowKey={(n) => n.id} columns={[
                                { header: "Zaman", cell: (n) => dateTime(n.created_at) },
                                { header: "Alıcı", cell: (n) => n.recipient_name ?? n.recipient_masked },
                                { header: "Kanal", cell: (n) => CH_LABEL[n.channel] ?? n.channel },
                                { header: "Konu", cell: (n) => <div><p className="font-medium">{n.subject ?? n.topic}</p><p className="line-clamp-1 text-xs text-gray-500">{n.body}</p></div> },
                                { header: "Durum", cell: (n) => <div><StatusBadge value={n.status} map={NOTIFY_STATUS} />{n.suppress_reason && <p className="mt-1 text-xs text-gray-500">{n.suppress_reason}</p>}</div> },
                            ]} />
                        )}
                    </QueryView>
                </Card>
            )}
            {tab === "prefs" && (
                <Card title="Kanal tercihlerim">
                    <QueryView q={prefs} isEmpty={() => false}>
                        {(d) => (
                            <div className="space-y-3">
                                <Notice tone="blue">{d.note}</Notice>
                                <Table rows={d.data} rowKey={(p) => `${p.channel}-${p.category}`} columns={[
                                    { header: "Kanal", cell: (p) => CH_LABEL[p.channel] ?? p.channel },
                                    { header: "Tür", cell: (p) => (p.category === "COMMERCIAL" ? "Ticari" : "Bilgilendirme") },
                                    { header: "Durum", cell: (p) => (p.enabled ? <Badge tone="green">Açık</Badge> : <Badge>Kapalı</Badge>) },
                                    { header: "Onay", cell: (p) => (p.consent_at ? `${dateTime(p.consent_at)} (${p.consent_source ?? "—"})` : "—") },
                                    { header: "", cell: (p) => (
                                        <Button size="sm" variant="secondary" disabled={act.pending}
                                            onClick={() => act.run(() => api.notifications.setPreference({ channel: p.channel, category: p.category, enabled: !p.enabled, consent_source: "PANEL" }),
                                                { invalidate: ["notifications"], success: "Tercih güncellendi" })}>
                                            {p.enabled ? "Kapat" : "Aç"}
                                        </Button>
                                    ) },
                                ]} />
                            </div>
                        )}
                    </QueryView>
                </Card>
            )}

            <FormModal open={open} onClose={() => setOpen(false)} title="Bildirim gönder" submitLabel="Gönder" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    const r = await act.run(() => api.notifications.send(form), {
                        invalidate: ["notifications"],
                        success: (res) => `Bildirim durumu: ${NOTIFY_STATUS[res.notification.status]?.[0] ?? res.notification.status}${res.notification.reason ? ` (${res.notification.reason})` : ""}`,
                    });
                    if (r) setOpen(false);
                }}>
                <Field label="Alıcı" required>
                    <Select required value={form.recipient_user_id} onChange={(e) => setForm({ ...form, recipient_user_id: e.target.value })}
                        options={(residents.data?.data ?? []).map((r) => ({ value: r.user_id, label: `${r.first_name} ${r.last_name} (${r.unit})` }))} placeholder="Seçin" />
                </Field>
                <Grid>
                    <Field label="Kanal"><Select value={form.channel} onChange={(e) => setForm({ ...form, channel: e.target.value })} options={CHANNELS} /></Field>
                    <Field label="Tür" hint="Ticari ileti yalnızca açık onayı olan alıcıya gider.">
                        <Select value={form.category} onChange={(e) => setForm({ ...form, category: e.target.value })} options={[{ value: "TRANSACTIONAL", label: "Bilgilendirme" }, { value: "COMMERCIAL", label: "Ticari" }]} />
                    </Field>
                </Grid>
                <Field label="Konu"><Input value={form.subject} onChange={(e) => setForm({ ...form, subject: e.target.value })} /></Field>
                <Field label="İleti" required><Textarea required value={form.body} onChange={(e) => setForm({ ...form, body: e.target.value })} /></Field>
            </FormModal>
        </Page>
    );
}
