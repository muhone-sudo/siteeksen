"use client";

import { useState } from "react";
import { Plus } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Input, Modal, Notice, Page, QueryView, StatusBadge, Table, Textarea } from "@/components/ui/kit";
import { dateTime, localToRFC3339 } from "@/lib/format";
import { SURVEY_STATUS } from "@/lib/labels";

/** Memnuniyet ölçümü (NPS: 9-10 destekçi, 7-8 pasif, 0-6 eleştirmen). Yanıtlar anonimdir. */
export default function NpsPage() {
    const list = useApi(["nps"], api.analytics.nps);
    const act = useAction();
    const { canWrite } = useRoles();
    const [open, setOpen] = useState(false);
    const [form, setForm] = useState({ title: "", description: "", ends_at: "" });
    const [view, setView] = useState<string | null>(null);
    const detail = useApi(["nps", "detail", view], () => api.analytics.npsDetail(view!), !!view);
    const comments = useApi(["nps", "comments", view], () => api.analytics.npsComments(view!), !!view);

    return (
        <Page title="Memnuniyet (NPS)" description="Sakin memnuniyeti ölçümü."
            actions={canWrite && <Button onClick={() => { setForm({ title: "", description: "", ends_at: "" }); setOpen(true); }}><Plus className="h-4 w-4" /> Ölçüm başlat</Button>}>
            <ActionFeedback action={act} />
            <Card padded={false}>
                <QueryView q={list} empty="Ölçüm yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(s) => s.id} columns={[
                            { header: "Başlık", cell: (s) => s.title },
                            { header: "Başlangıç", cell: (s) => dateTime(s.starts_at) },
                            { header: "Bitiş", cell: (s) => dateTime(s.ends_at) },
                            { header: "Yanıt", cell: (s) => `${s.responses}/${s.eligible_respondents}` },
                            { header: "Durum", cell: (s) => <StatusBadge value={s.status} map={SURVEY_STATUS} /> },
                            { header: "", cell: (s) => (
                                <div className="flex gap-1">
                                    <Button size="sm" variant="ghost" onClick={() => setView(s.id)}>Sonuç</Button>
                                    {canWrite && s.status === "ACTIVE" && <Button size="sm" variant="secondary" disabled={act.pending} onClick={() => act.run(() => api.analytics.closeNps(s.id), { invalidate: ["nps"], success: "Ölçüm kapatıldı" })}>Kapat</Button>}
                                </div>
                            ) },
                        ]} />
                    )}
                </QueryView>
            </Card>
            <FormModal open={open} onClose={() => setOpen(false)} title="Memnuniyet ölçümü başlat" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    const r = await act.run(() => api.analytics.createNps({ ...form, ends_at: form.ends_at ? localToRFC3339(form.ends_at) : undefined }), { invalidate: ["nps"], success: "Ölçüm başladı" });
                    if (r) setOpen(false);
                }}>
                <Field label="Başlık" required><Input required value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} /></Field>
                <Field label="Açıklama"><Textarea value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} /></Field>
                <Field label="Bitiş"><Input type="datetime-local" value={form.ends_at} onChange={(e) => setForm({ ...form, ends_at: e.target.value })} /></Field>
            </FormModal>
            <Modal open={!!view} onClose={() => setView(null)} title="Ölçüm sonucu" wide>
                <QueryView q={detail} isEmpty={() => false}>
                    {(d) => (
                        <div className="space-y-3 text-sm">
                            {d.result ? (
                                <>
                                    <p className="text-3xl font-bold">{d.result.nps_score} <span className="text-sm font-normal text-gray-500">NPS</span> {!d.result.reliable && <Badge tone="amber">{"10'dan az yanıt — güvenilir değil"}</Badge>}</p>
                                    <p>Destekçi {d.result.promoters} · Pasif {d.result.passives} · Eleştirmen {d.result.detractors} (katılım %{d.participation_pct ?? "—"})</p>
                                    <Notice tone="blue">{d.result.interpretation}</Notice>
                                </>
                            ) : <Notice tone="blue">{d.result_note ?? "Henüz yanıt yok."}</Notice>}
                            <p className="text-xs text-gray-500">{d.method}</p>
                            <QueryView q={comments} empty="Yorum yok">
                                {(c) => (
                                    <Table rows={c.data} rowKey={(x) => `${x.created_at}-${x.comment.slice(0, 8)}`} columns={[
                                        { header: "Puan", cell: (x) => x.score ?? "—" },
                                        { header: "Yorum", cell: (x) => x.comment },
                                        { header: "Tarih", cell: (x) => dateTime(x.created_at) },
                                    ]} />
                                )}
                            </QueryView>
                        </div>
                    )}
                </QueryView>
            </Modal>
        </Page>
    );
}
