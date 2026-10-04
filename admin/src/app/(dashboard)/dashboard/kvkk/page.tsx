"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Notice, Page, QueryView, Select, Table, Textarea } from "@/components/ui/kit";
import { date } from "@/lib/format";
import type { KVKKRequest } from "@/lib/types";

const TYPE_LABEL: Record<string, string> = {
    INFO: "Bilgi talebi", CORRECTION: "Düzeltme", ERASURE: "Silme / yok etme",
    OBJECTION: "İtiraz", COMPENSATION: "Zararın giderilmesi", OTHER: "Diğer",
};

/**
 * KVKK m.11 ilgili kişi başvuruları. Kanun (m.13/2) başvurunun en geç 30 gün içinde
 * ücretsiz sonuçlandırılmasını ister; ret gerekçeli olmalıdır. Kayıtlar silinmez.
 */
export default function KvkkPage() {
    const q = useApi(["kvkk"], api.identity.kvkkRequests);
    const act = useAction();
    const { canWrite } = useRoles();
    const [answer, setAnswer] = useState<{ r: KVKKRequest; status: string; response: string } | null>(null);

    return (
        <Page title="KVKK başvuruları" description="Sakin ve personelin kişisel verileriyle ilgili başvuruları (KVKK m.11). Yasal yanıt süresi 30 gün (m.13/2).">
            <ActionFeedback action={act} />
            <Card padded={false}>
                <QueryView q={q} empty="Başvuru yok">
                    {(d) => (
                        <Table
                            rows={d.data}
                            rowKey={(r) => r.id}
                            columns={[
                                { header: "Başvuran", cell: (r) => r.applicant_name || "—" },
                                { header: "Tür", cell: (r) => TYPE_LABEL[r.request_type] ?? r.request_type },
                                { header: "Talep", cell: (r) => <span className="line-clamp-2 max-w-md">{r.description}</span> },
                                { header: "Başvuru", cell: (r) => date(r.created_at) },
                                {
                                    header: "Son gün",
                                    cell: (r) => r.status !== "OPEN" ? date(r.due_date)
                                        : r.days_left < 0 ? <Badge tone="red">{date(r.due_date)} · {-r.days_left} gün geçti</Badge>
                                        : r.days_left <= 5 ? <Badge tone="amber">{date(r.due_date)} · {r.days_left} gün</Badge>
                                        : `${date(r.due_date)} · ${r.days_left} gün`,
                                },
                                { header: "Durum", cell: (r) => r.status === "OPEN" ? <Badge tone="blue">Açık</Badge> : r.status === "ANSWERED" ? <Badge tone="green">Yanıtlandı</Badge> : <Badge>Reddedildi</Badge> },
                                ...(canWrite ? [{
                                    header: "",
                                    cell: (r: KVKKRequest) => r.status === "OPEN"
                                        ? <Button size="sm" onClick={() => setAnswer({ r, status: "ANSWERED", response: "" })}>Yanıtla</Button>
                                        : <span className="text-xs text-gray-500">{r.response}</span>,
                                }] : []),
                            ]}
                        />
                    )}
                </QueryView>
            </Card>

            <FormModal
                open={!!answer}
                onClose={() => setAnswer(null)}
                title="Başvuruyu sonuçlandır"
                pending={act.pending}
                error={act.error}
                onSubmit={async () => {
                    if (!answer) return;
                    const r = await act.run(() => api.identity.respondKvkk(answer.r.id, { status: answer.status, response: answer.response }), {
                        invalidate: ["kvkk"], success: "Başvuru sonuçlandırıldı; başvurana bildirildi",
                    });
                    if (r) setAnswer(null);
                }}
            >
                {answer && (
                    <div className="space-y-3">
                        <Notice tone="blue">{answer.r.applicant_name} — {TYPE_LABEL[answer.r.request_type]}: {answer.r.description}</Notice>
                        <Field label="Sonuç">
                            <Select value={answer.status} onChange={(e) => setAnswer({ ...answer, status: e.target.value })}
                                options={[{ value: "ANSWERED", label: "Yanıtlandı / kabul" }, { value: "REJECTED", label: "Reddedildi (gerekçeli)" }]} />
                        </Field>
                        <Field label="Yanıt" required hint="Başvurana iletilir; ret gerekçeli olmalıdır (KVKK m.13/3)">
                            <Textarea required rows={6} value={answer.response} onChange={(e) => setAnswer({ ...answer, response: e.target.value })} />
                        </Field>
                    </div>
                )}
            </FormModal>
        </Page>
    );
}
