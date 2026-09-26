"use client";

import { useState } from "react";
import { Pin, Plus } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Modal, Notice, Page, QueryView, Select, StatusBadge, Table, Textarea } from "@/components/ui/kit";
import { dateTime, localToRFC3339, num } from "@/lib/format";
import { PRIORITY } from "@/lib/labels";

const CATEGORIES = [
    { value: "GENERAL", label: "Genel" },
    { value: "MAINTENANCE", label: "Bakım / arıza" },
    { value: "FINANCIAL", label: "Mali" },
    { value: "EMERGENCY", label: "Acil" },
    { value: "ASSEMBLY", label: "Genel kurul (hatırlatma)" },
];
const CAT_LABEL = Object.fromEntries(CATEGORIES.map((c) => [c.value, c.label]));

export default function AnnouncementsPage() {
    const q = useApi(["announcements"], () => api.announcements.list({ include_expired: "true" }));
    const act = useAction();
    const { canWrite } = useRoles();
    const [open, setOpen] = useState(false);
    const [form, setForm] = useState({ title: "", content: "", category: "GENERAL", priority: "NORMAL", is_pinned: false, expires_at: "" });
    const [statsFor, setStatsFor] = useState<string | null>(null);
    const stats = useApi(["announcements", "stats", statsFor], () => api.announcements.readStats(statsFor!), !!statsFor);

    return (
        <Page
            title="Duyurular"
            description="Yayımlanan duyuru sakinlere uygulama içi bildirim olarak iletilir."
            actions={canWrite && <Button onClick={() => setOpen(true)}><Plus className="h-4 w-4" /> Duyuru yayımla</Button>}
        >
            <ActionFeedback action={act} />
            <Card padded={false}>
                <QueryView q={q} empty="Duyuru yok">
                    {(d) => (
                        <Table
                            rows={d.data}
                            rowKey={(a) => a.id}
                            columns={[
                                { header: "Başlık", cell: (a) => <div className="flex items-start gap-2">{a.is_pinned && <Pin className="mt-0.5 h-3.5 w-3.5 text-primary" />}<div><p className="font-medium">{a.title}</p><p className="line-clamp-2 text-xs text-gray-500">{a.content}</p></div></div> },
                                { header: "Kategori", cell: (a) => <Badge>{CAT_LABEL[a.category] ?? a.category}</Badge> },
                                { header: "Öncelik", cell: (a) => <StatusBadge value={a.priority} map={PRIORITY} /> },
                                { header: "Yayım", cell: (a) => dateTime(a.published_at) },
                                { header: "Okunma", cell: (a) => (a.read_count === undefined ? "—" : num(a.read_count)) },
                                {
                                    header: "",
                                    cell: (a) => (
                                        <div className="flex gap-1">
                                            <Button size="sm" variant="ghost" onClick={() => setStatsFor(a.id)}>İstatistik</Button>
                                            {canWrite && (
                                                <Button size="sm" variant="ghost" disabled={act.pending}
                                                    onClick={() => act.run(() => api.announcements.pin(a.id, !a.is_pinned), { invalidate: ["announcements"] })}>
                                                    {a.is_pinned ? "Sabitlemeyi kaldır" : "Sabitle"}
                                                </Button>
                                            )}
                                        </div>
                                    ),
                                },
                            ]}
                        />
                    )}
                </QueryView>
            </Card>

            <FormModal
                open={open}
                onClose={() => setOpen(false)}
                title="Duyuru yayımla"
                submitLabel="Yayımla"
                pending={act.pending}
                error={act.error}
                onSubmit={async () => {
                    const r = await act.run(
                        () => api.announcements.create({ ...form, expires_at: form.expires_at ? localToRFC3339(form.expires_at) : undefined }),
                        {
                            invalidate: ["announcements"],
                            success: (res) => `Duyuru yayımlandı. Bildirim: ${res.notification.sent} gönderildi, ${res.notification.pending} kuyrukta, ${res.notification.suppressed} engellendi`,
                        }
                    );
                    if (r) {
                        setOpen(false);
                        setForm({ title: "", content: "", category: "GENERAL", priority: "NORMAL", is_pinned: false, expires_at: "" });
                    }
                }}
            >
                <Field label="Başlık" required><Input required value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} /></Field>
                <Field label="İçerik" required><Textarea required rows={5} value={form.content} onChange={(e) => setForm({ ...form, content: e.target.value })} /></Field>
                <Grid>
                    <Field label="Kategori"><Select value={form.category} onChange={(e) => setForm({ ...form, category: e.target.value })} options={CATEGORIES} /></Field>
                    <Field label="Öncelik"><Select value={form.priority} onChange={(e) => setForm({ ...form, priority: e.target.value })} options={Object.entries(PRIORITY).map(([v, [l]]) => ({ value: v, label: l }))} /></Field>
                    <Field label="Yayından kalkış"><Input type="datetime-local" value={form.expires_at} onChange={(e) => setForm({ ...form, expires_at: e.target.value })} /></Field>
                    <Field label="Sabitle">
                        <Select value={form.is_pinned ? "1" : "0"} onChange={(e) => setForm({ ...form, is_pinned: e.target.value === "1" })} options={[{ value: "0", label: "Hayır" }, { value: "1", label: "Evet" }]} />
                    </Field>
                </Grid>
                {form.category === "ASSEMBLY" && (
                    <Notice tone="amber">
                        Genel kurul çağrısı KMK m.29 gereği imza karşılığı ya da taahhütlü mektupla yapılır. Bu duyuru yalnızca hatırlatmadır; çağrının yerine geçmez.
                    </Notice>
                )}
            </FormModal>

            <Modal open={!!statsFor} onClose={() => setStatsFor(null)} title="Okunma istatistiği">
                <QueryView q={stats} isEmpty={() => false}>
                    {(s) => (
                        <div className="space-y-3 text-sm">
                            <p>Sakin: <b>{s.stats.total_residents}</b> · Okuyan: <b>{s.stats.read_count}</b> · Okumayan: <b>{s.stats.unread_count}</b></p>
                            <Notice tone="blue">{s.note}</Notice>
                        </div>
                    )}
                </QueryView>
            </Modal>
        </Page>
    );
}
