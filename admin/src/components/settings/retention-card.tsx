"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Button, Card, Field, FormModal, Input, QueryView, Table, Textarea } from "@/components/ui/kit";
import { date, dateTime } from "@/lib/format";
import type { RetentionRule } from "@/lib/types";

/**
 * KVKK saklama süreleri ve periyodik imha (FAZ 7.8). Süre tanımlanan kategoride kişisel
 * veriler en geç 6 ayda bir anonimleştirilir (İmha Yönetmeliği m.11/2); her işlem imha
 * kaydına yazılır (m.7/3). Süre tanımlanmayan kategori imha edilmez.
 */
export function RetentionCard() {
    const q = useApi(["retention"], api.settings.retention);
    const log = useApi(["retention-log"], api.settings.destructionLog);
    const act = useAction();
    const [edit, setEdit] = useState<{ rule: RetentionRule; months: string; justification: string } | null>(null);
    const inv = { invalidate: ["retention", "retention-log"] };

    return (
        <>
            <ActionFeedback action={act} />
            <Card title="Kişisel veri saklama süreleri" padded={false}
                actions={<Button size="sm" variant="secondary" disabled={act.pending} onClick={() => act.run(() => api.settings.runRetention(), { ...inv, success: (x) => x.note })}>Şimdi imha et</Button>}>
                <QueryView q={q} isEmpty={(d) => d.data.length === 0}>
                    {(d) => (
                        <>
                            <Table rows={d.data} rowKey={(r) => r.category} columns={[
                                { header: "Kategori", cell: (r) => <div><b>{r.title}</b><p className="text-xs text-gray-500">{r.fields}</p></div> },
                                { header: "Saklama", cell: (r) => (r.retention_months ? `${r.retention_months} ay` : <span className="text-red-600">Tanımlı değil</span>) },
                                { header: "Gerekçe", cell: (r) => <span className="text-xs">{r.justification ?? ""}</span> },
                                { header: "Son imha", cell: (r) => (r.last_run_at ? `${dateTime(r.last_run_at)} · ${r.last_run_count} kayıt` : "—") },
                                { header: "", cell: (r) => <Button size="sm" variant="ghost" onClick={() => setEdit({ rule: r, months: String(r.retention_months ?? 12), justification: r.justification ?? "" })}>Düzenle</Button> },
                            ]} />
                            <p className="px-4 py-3 text-xs text-gray-500">{d.note}</p>
                        </>
                    )}
                </QueryView>
            </Card>
            <Card title="İmha kaydı" padded={false}>
                <QueryView q={log} empty="Henüz imha yapılmadı">
                    {(d) => (
                        <Table rows={d.data} rowKey={(e) => e.executed_at + e.category} columns={[
                            { header: "Zaman", cell: (e) => dateTime(e.executed_at) },
                            { header: "Kategori", cell: (e) => e.category },
                            { header: "Yöntem", cell: (e) => (e.method === "ANONYMIZE" ? "Anonimleştirme" : "Silme") },
                            { header: "Kesim", cell: (e) => date(e.cutoff) },
                            { header: "Kayıt", cell: (e) => e.record_count },
                            { header: "Yapan", cell: (e) => (e.executed_by === "scheduler" ? "Otomatik" : "Yönetim") },
                        ]} />
                    )}
                </QueryView>
            </Card>
            <FormModal open={!!edit} onClose={() => setEdit(null)} title={`Saklama süresi — ${edit?.rule.title ?? ""}`} pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!edit) return;
                    const r = await act.run(() => api.settings.setRetention(edit.rule.category, Number(edit.months), edit.justification), { ...inv, success: "Kaydedildi" });
                    if (r) setEdit(null);
                }}>
                {edit && (<>
                    <p className="text-sm text-gray-600 dark:text-gray-400">Koşul: {edit.rule.condition}.</p>
                    <Field label="Saklama süresi (ay)" required><Input type="number" min="1" max="120" required value={edit.months} onChange={(e) => setEdit({ ...edit, months: e.target.value })} /></Field>
                    <Field label="Gerekçe (işleme amacı / hukuki dayanak)" required><Textarea required value={edit.justification} onChange={(e) => setEdit({ ...edit, justification: e.target.value })} /></Field>
                </>)}
            </FormModal>
        </>
    );
}
