"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Input, QueryView, Table } from "@/components/ui/kit";
import { date, today } from "@/lib/format";
import type { ComplianceItem } from "@/lib/types";

/**
 * İşveren yükümlülük takvimi (FAZ 7.7): SGK işe giriş/ayrılış bildirgesi, MUHSGK ve prim
 * son günleri. Sistem verginin doğup doğmadığına karar vermez; yalnızca süreyi gösterir.
 */
export function ComplianceCard({ canWrite }: { canWrite: boolean }) {
    const q = useApi(["compliance-calendar"], api.personnel.complianceCalendar);
    const act = useAction();
    const [rec, setRec] = useState<{ item: ComplianceItem; date: string } | null>(null);

    return (
        <Card title="Vergi ve SGK yükümlülükleri" padded={false}>
            <ActionFeedback action={act} />
            <QueryView q={q} isEmpty={(d) => d.data.length === 0} empty="Yaklaşan yükümlülük yok">
                {(d) => (
                    <>
                        <Table rows={d.data} rowKey={(i) => i.kind + (i.employee_id ?? "") + (i.period ?? "")} columns={[
                            { header: "Yükümlülük", cell: (i) => i.title },
                            { header: "Son gün", cell: (i) => date(i.due_date) },
                            { header: "Durum", cell: (i) => (i.days_left < 0 ? <Badge tone="red">{-i.days_left} gün geçti</Badge>
                                : i.days_left <= 5 ? <Badge tone="amber">{i.days_left} gün</Badge> : `${i.days_left} gün`) },
                            { header: "Dayanak", cell: (i) => <span className="text-xs text-gray-500">{i.legal_basis}</span> },
                            ...(canWrite ? [{
                                header: "", cell: (i: ComplianceItem) => (i.kind === "SGK_ENTRY" || i.kind === "SGK_EXIT")
                                    ? <Button size="sm" variant="secondary" onClick={() => setRec({ item: i, date: today() })}>Bildirge verildi</Button> : null,
                            }] : []),
                        ]} />
                        <p className="px-4 py-3 text-xs text-gray-500">{d.note}{!d.muhsgk_enabled && " Aylık MUHSGK takvimi site ayarlarından kapatılmış."}</p>
                    </>
                )}
            </QueryView>
            <FormModal open={!!rec} onClose={() => setRec(null)} title="SGK bildirgesi verildi" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!rec || !rec.item.employee_id) return;
                    const body = rec.item.kind === "SGK_ENTRY" ? { entry_date: rec.date } : { exit_date: rec.date };
                    const r = await act.run(() => api.personnel.recordSGK(rec.item.employee_id ?? "", body), { invalidate: ["compliance-calendar"], success: "Bildirge tarihi kaydedildi" });
                    if (r) setRec(null);
                }}>
                <Field label="Bildirgenin verildiği tarih" required>
                    <Input type="date" required value={rec?.date ?? ""} onChange={(e) => rec && setRec({ ...rec, date: e.target.value })} />
                </Field>
            </FormModal>
        </Card>
    );
}
