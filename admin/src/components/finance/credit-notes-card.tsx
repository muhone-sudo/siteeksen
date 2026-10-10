"use client";

// Alacak dekontu (059, Apsiyon BUG-12): oturulmayan ay, indirim, hatalı tahakkuk gibi
// düzeltmeler sisteme numaralı ve gerekçeli belge olarak işlenir; borç anında düşer.

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Input, Notice, QueryView, Select, Table, Textarea } from "@/components/ui/kit";
import { date, dateTime, kurus } from "@/lib/format";
import type { CreditNote } from "@/lib/types";

export function CreditNotesCard() {
    const list = useApi(["credit-notes"], api.finance.creditNotes);
    const units = useApi(["units"], api.identity.units);
    const act = useAction();
    const { canWrite } = useRoles();
    const [form, setForm] = useState<null | { unit_id: string; assessment_id: string; amount_try: string; reason: string }>(null);
    const open = useApi(["open-assessments", form?.unit_id], () => api.finance.openAssessments(form!.unit_id), !!form?.unit_id);
    const [reversing, setReversing] = useState<null | { note: CreditNote; reason: string }>(null);
    const chosen = open.data?.data.find((a) => a.id === form?.assessment_id);

    return (
        <>
            <ActionFeedback action={act} />
            <Card padded={false} title="Alacak dekontları"
                actions={canWrite && <Button size="sm" onClick={() => setForm({ unit_id: "", assessment_id: "", amount_try: "", reason: "" })}>Dekont kes</Button>}>
                <QueryView q={list} empty="Dekont yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(x) => x.id} columns={[
                            { header: "No", cell: (x) => <span className="font-mono text-xs">{x.document_no}</span> },
                            { header: "Daire / dönem", cell: (x) => `${x.unit} · ${x.period}` },
                            { header: "Tutar", cell: (x) => <b>{kurus(x.amount_kurus)}</b> },
                            { header: "Gerekçe", cell: (x) => x.reason },
                            { header: "Düzenleyen", cell: (x) => `${x.created_by_name ?? ""} · ${dateTime(x.created_at)}` },
                            { header: "Durum", cell: (x) => (x.reversed_at ? <Badge tone="red" >Ters kayıt: {x.reversal_reason}</Badge> : <Badge tone="green">Geçerli</Badge>) },
                            { header: "", cell: (x) => (
                                <div className="flex gap-1">
                                    <Button size="sm" variant="secondary" disabled={act.pending} onClick={() => act.run(() => api.finance.creditNotePdf(x.id, x.document_no))}>PDF</Button>
                                    {canWrite && !x.reversed_at && <Button size="sm" variant="ghost" onClick={() => setReversing({ note: x, reason: "" })}>Ters kayıt</Button>}
                                </div>
                            ) },
                        ]} />
                    )}
                </QueryView>
            </Card>

            <FormModal open={!!form} onClose={() => setForm(null)} title="Alacak dekontu kes" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!form) return;
                    const r = await act.run(() => api.finance.createCreditNote({ assessment_id: form.assessment_id, amount_try: Number(form.amount_try), reason: form.reason }),
                        { invalidate: ["credit-notes", "debtors", "open-assessments"], success: (res) => `Dekont ${res.credit_note.document_no} kesildi` });
                    if (r) setForm(null);
                }}>
                {form && (
                    <>
                        <Notice tone="blue">Dekont borcu düşürür, tahsilat sayılmaz ve tahsilat defterine yazılır. Silinemez; hata ancak gerekçeli ters kayıtla düzeltilir.</Notice>
                        <Field label="Daire" required>
                            <Select required value={form.unit_id} onChange={(e) => setForm({ ...form, unit_id: e.target.value, assessment_id: "" })}
                                options={(units.data?.data ?? []).map((u) => ({ value: u.id, label: `${u.block}-${u.door_number}` }))} placeholder="Seçin" />
                        </Field>
                        {form.unit_id && (
                            <Field label="Tahakkuk" required>
                                <Select required value={form.assessment_id} onChange={(e) => setForm({ ...form, assessment_id: e.target.value })}
                                    options={(open.data?.data ?? []).map((a) => ({ value: a.id, label: `${a.period} · vade ${date(a.due_date)} · kalan ${kurus(a.outstanding_kurus)}` }))}
                                    placeholder={open.data && open.data.data.length === 0 ? "Borcu kalan tahakkuk yok" : "Seçin"} />
                            </Field>
                        )}
                        <Field label="Tutar (TL)" required hint={chosen ? `En çok ${kurus(chosen.max_credit_kurus)}` : undefined}>
                            <Input required type="number" min="0.01" step="0.01" value={form.amount_try} onChange={(e) => setForm({ ...form, amount_try: e.target.value })} />
                        </Field>
                        <Field label="Gerekçe" required hint="Ör. Ocak ayında daire boştu — yönetim kurulu kararı 2026/4">
                            <Textarea required minLength={5} value={form.reason} onChange={(e) => setForm({ ...form, reason: e.target.value })} />
                        </Field>
                    </>
                )}
            </FormModal>

            <FormModal open={!!reversing} onClose={() => setReversing(null)} title={reversing ? `Ters kayıt — ${reversing.note.document_no}` : ""} pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!reversing) return;
                    const r = await act.run(() => api.finance.reverseCreditNote(reversing.note.id, reversing.reason),
                        { invalidate: ["credit-notes", "debtors", "ledger"], success: "Dekontun ters kaydı yapıldı; borç geri yüklendi" });
                    if (r) setReversing(null);
                }}>
                {reversing && <Field label="Gerekçe" required><Textarea required minLength={5} value={reversing.reason} onChange={(e) => setReversing({ ...reversing, reason: e.target.value })} /></Field>}
            </FormModal>
        </>
    );
}
