"use client";

import { useState } from "react";
import { Plus, Trash2 } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Modal, Notice, Page, QueryView, Select, StatusBadge, Table, Textarea } from "@/components/ui/kit";
import { dateTime, localToRFC3339 } from "@/lib/format";
import { opts, SURVEY_STATUS } from "@/lib/labels";

const TYPES = [
    { value: "POLL", label: "Kamuoyu yoklaması" },
    { value: "SURVEY", label: "Anket" },
    { value: "VOTE", label: "Malikler arası danışma oylaması" },
];

/**
 * Anket ve danışma oylaması. Bu oylamalar genel kurul KARARI DEĞİLDİR
 * (KMK m.29-32 kararları yalnız usulüne uygun toplanan kurulda alınır).
 */
export default function SurveysPage() {
    const [status, setStatus] = useState("");
    const list = useApi(["surveys", status], () => api.surveys.list(status));
    const act = useAction();
    const [open, setOpen] = useState(false);
    const blank = { title: "", description: "", survey_type: "POLL", is_anonymous: true, is_weighted: false, allow_comments: true, show_results_before_end: false, ends_at: "", options: ["", ""] };
    const [form, setForm] = useState(blank);
    const [view, setView] = useState<string | null>(null);
    const detail = useApi(["surveys", "detail", view], () => api.surveys.get(view!), !!view);
    const [cancelling, setCancelling] = useState<string | null>(null);
    const [reason, setReason] = useState("");

    return (
        <Page title="Anketler" description="Sakinlere anket ve danışma oylaması. Yayımlanan anket sakinlere bildirim olarak düşer."
            actions={<Button onClick={() => { setForm(blank); setOpen(true); }}><Plus className="h-4 w-4" /> Anket oluştur</Button>}>
            <Notice tone="amber">Anket sonuçları genel kurul kararı yerine geçmez. Bağlayıcı kararlar Genel Kurul ekranından, usulüne uygun çağrı ve nisapla alınır.</Notice>
            <ActionFeedback action={act} />
            <Card padded={false} title="Anketler" actions={<Select value={status} onChange={(e) => setStatus(e.target.value)} options={opts(SURVEY_STATUS)} placeholder="Tüm durumlar" />}>
                <QueryView q={list} empty="Anket yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(s) => s.id} columns={[
                            { header: "Başlık", cell: (s) => <div><p className="font-medium">{s.title}</p><p className="text-xs text-gray-500">{TYPES.find((t) => t.value === s.survey_type)?.label}{s.is_weighted ? " · arsa payı ağırlıklı" : ""}{s.is_anonymous ? " · anonim" : ""}</p></div> },
                            { header: "Bitiş", cell: (s) => dateTime(s.ends_at) },
                            { header: "Katılım", cell: (s) => `${s.total_votes}/${s.eligible_voters} (%${s.participation_rate})` },
                            { header: "Durum", cell: (s) => <StatusBadge value={s.status} map={SURVEY_STATUS} /> },
                            { header: "", cell: (s) => (
                                <div className="flex gap-1">
                                    <Button size="sm" variant="ghost" onClick={() => setView(s.id)}>Sonuç</Button>
                                    {s.status === "DRAFT" && <Button size="sm" disabled={act.pending} onClick={() => act.run(() => api.surveys.publish(s.id), { invalidate: ["surveys"], success: (r) => `Yayımlandı${r.notification ? ` — ${r.notification.sent} sakine bildirim` : ""}` })}>Yayımla</Button>}
                                    {s.status === "ACTIVE" && <Button size="sm" variant="secondary" disabled={act.pending} onClick={() => act.run(() => api.surveys.close(s.id), { invalidate: ["surveys"], success: "Anket kapatıldı" })}>Kapat</Button>}
                                    {(s.status === "DRAFT" || s.status === "ACTIVE") && <Button size="sm" variant="ghost" onClick={() => { setReason(""); setCancelling(s.id); }}>İptal</Button>}
                                </div>
                            ) },
                        ]} />
                    )}
                </QueryView>
            </Card>

            <FormModal open={open} onClose={() => setOpen(false)} title="Anket oluştur" wide pending={act.pending} error={act.error}
                onSubmit={async () => {
                    const body = { ...form, options: form.options.map((o) => o.trim()).filter(Boolean), ends_at: form.ends_at ? localToRFC3339(form.ends_at) : undefined };
                    const r = await act.run(() => api.surveys.create(body), { invalidate: ["surveys"], success: "Anket taslak olarak oluşturuldu; yayımlayınca oylama başlar" });
                    if (r) setOpen(false);
                }}>
                <Field label="Başlık" required><Input required value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} /></Field>
                <Field label="Açıklama"><Textarea value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} /></Field>
                <Grid cols={3}>
                    <Field label="Tür"><Select value={form.survey_type} onChange={(e) => setForm({ ...form, survey_type: e.target.value })} options={TYPES} /></Field>
                    <Field label="Bitiş"><Input type="datetime-local" value={form.ends_at} onChange={(e) => setForm({ ...form, ends_at: e.target.value })} /></Field>
                    <Field label="Anonim"><Select value={form.is_anonymous ? "1" : "0"} onChange={(e) => setForm({ ...form, is_anonymous: e.target.value === "1" })} options={[{ value: "1", label: "Evet" }, { value: "0", label: "Hayır" }]} /></Field>
                    <Field label="Arsa payı ağırlıklı"><Select value={form.is_weighted ? "1" : "0"} onChange={(e) => setForm({ ...form, is_weighted: e.target.value === "1" })} options={[{ value: "0", label: "Hayır" }, { value: "1", label: "Evet" }]} /></Field>
                    <Field label="Yorum"><Select value={form.allow_comments ? "1" : "0"} onChange={(e) => setForm({ ...form, allow_comments: e.target.value === "1" })} options={[{ value: "1", label: "Açık" }, { value: "0", label: "Kapalı" }]} /></Field>
                    <Field label="Sonuç bitmeden görünsün"><Select value={form.show_results_before_end ? "1" : "0"} onChange={(e) => setForm({ ...form, show_results_before_end: e.target.value === "1" })} options={[{ value: "0", label: "Hayır" }, { value: "1", label: "Evet" }]} /></Field>
                </Grid>
                <div className="space-y-2">
                    <p className="text-sm font-medium">Seçenekler (en az 2)</p>
                    {form.options.map((o, i) => (
                        <div key={i} className="flex gap-2">
                            <Input value={o} placeholder={`${i + 1}. seçenek`} onChange={(e) => setForm({ ...form, options: form.options.map((x, j) => (j === i ? e.target.value : x)) })} />
                            <Button variant="ghost" aria-label="Seçeneği çıkar" onClick={() => setForm({ ...form, options: form.options.filter((_, j) => j !== i) })}><Trash2 className="h-4 w-4" /></Button>
                        </div>
                    ))}
                    <Button size="sm" variant="secondary" onClick={() => setForm({ ...form, options: [...form.options, ""] })}>+ Seçenek</Button>
                </div>
            </FormModal>

            <Modal open={!!view} onClose={() => setView(null)} title="Anket sonucu" wide>
                <QueryView q={detail} isEmpty={() => false}>
                    {(d) => (
                        <div className="space-y-3">
                            <p className="font-medium">{d.survey.title}</p>
                            {!d.results_visible && d.results_note && <Notice tone="blue">{d.results_note}</Notice>}
                            <Table rows={d.survey.options ?? []} rowKey={(o) => o.id} columns={[
                                { header: "Seçenek", cell: (o) => o.option_text },
                                { header: "Oy", cell: (o) => o.vote_count ?? "—" },
                                { header: "Oran", cell: (o) => (o.percentage ? `%${o.percentage}` : "—") },
                                ...(d.survey.is_weighted ? [{ header: "Arsa payı", cell: (o: { weighted_share?: string }) => o.weighted_share ?? "—" }] : []),
                            ]} />
                            <p className="text-xs text-gray-500">{d.legal_notice}</p>
                            {d.survey.is_anonymous && <Badge>Anonim</Badge>}
                        </div>
                    )}
                </QueryView>
            </Modal>
            <FormModal open={!!cancelling} onClose={() => setCancelling(null)} title="Anketi iptal et" submitLabel="İptal et" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!cancelling) return;
                    const r = await act.run(() => api.surveys.cancel(cancelling, reason), { invalidate: ["surveys"], success: "Anket iptal edildi" });
                    if (r) setCancelling(null);
                }}>
                <Field label="Gerekçe" required><Textarea required value={reason} onChange={(e) => setReason(e.target.value)} /></Field>
            </FormModal>
        </Page>
    );
}
