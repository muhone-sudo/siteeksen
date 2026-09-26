"use client";

import { useState } from "react";
import { Plus } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Button, Card, Field, FormModal, Grid, Input, Notice, Page, QueryView, ReadOnlyHint, Select, StatusBadge, Table, Textarea } from "@/components/ui/kit";
import { date, kurus } from "@/lib/format";
import { CASE_STATUS } from "@/lib/labels";

const CASE_TYPES = [
    { value: "EXECUTION", label: "İcra takibi" },
    { value: "LAWSUIT", label: "Dava" },
    { value: "MORTGAGE", label: "Kanuni ipotek (KMK m.22)" },
];
const BASIS = [
    { value: "OPERATING_BUDGET", label: "Kesinleşmiş işletme projesi" },
    { value: "ASSEMBLY_DECISION", label: "Kat malikleri kurulu kararı" },
    { value: "COURT_ORDER", label: "Mahkeme kararı" },
];

/**
 * İcra ve dava takibi. Borç tutarı tahakkuklardan SUNUCUDA hesaplanır; elle
 * girilmez. Takibin İİK m.68 kapsamında belgeye dayanması gerekir
 * (kesinleşmiş işletme projesi ya da kurul kararı — KMK m.37/son).
 */
export default function LegalPage() {
    const list = useApi(["legal-cases"], api.governance.legalCases);
    const units = useApi(["units"], api.identity.units);
    const act = useAction();
    const { canWrite } = useRoles();
    const [open, setOpen] = useState(false);
    const unitName = (id?: string) => {
        const u = (units.data?.data ?? []).find((x) => x.id === id);
        return u ? `${u.block}-${u.door_number}` : "—";
    };
    const blank = { unit_id: "", case_type: "EXECUTION", basis_document_type: "OPERATING_BUDGET", office_or_court: "", file_no: "", lawyer_name: "", note: "" };
    const [form, setForm] = useState(blank);

    return (
        <Page title="İcra ve dava" description="Ödenmeyen ortak gider borçları için hukuki takip kayıtları."
            actions={canWrite && <Button onClick={() => { setForm(blank); setOpen(true); }}><Plus className="h-4 w-4" /> Takip aç</Button>}>
            {!canWrite && <ReadOnlyHint />}
            <ActionFeedback action={act} />
            <Card padded={false}>
                <QueryView q={list} empty="Takip kaydı yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(c) => c.id} columns={[
                            { header: "Tür", cell: (c) => CASE_TYPES.find((t) => t.value === c.case_type)?.label ?? c.case_type },
                            { header: "Daire", cell: (c) => unitName(c.unit_id) },
                            { header: "Anapara", cell: (c) => kurus(c.principal_kurus) },
                            { header: "Gecikme tazminatı", cell: (c) => kurus(c.late_fee_kurus) },
                            { header: "Dayanak", cell: (c) => BASIS.find((b) => b.value === c.basis_document_type)?.label ?? "—" },
                            { header: "Daire / mahkeme", cell: (c) => [c.office_or_court, c.file_no].filter(Boolean).join(" · ") || "—" },
                            { header: "Durum", cell: (c) => <StatusBadge value={c.status} map={CASE_STATUS} /> },
                            { header: "Açılış", cell: (c) => date(c.filed_at) },
                        ]} />
                    )}
                </QueryView>
            </Card>

            <FormModal open={open} onClose={() => setOpen(false)} title="Hukuki takip aç" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    const r = await act.run(() => api.governance.createLegalCase({ ...form, basis_document_type: form.basis_document_type || undefined }), {
                        invalidate: ["legal-cases"],
                        success: (res) => res.warning ? `Takip açıldı. ${res.warning}` : `Takip açıldı — anapara ${kurus(res.case?.principal_kurus)}`,
                    });
                    if (r) setOpen(false);
                }}>
                <Grid>
                    <Field label="Daire" required>
                        <Select required value={form.unit_id} onChange={(e) => setForm({ ...form, unit_id: e.target.value })} placeholder="Seçin"
                            options={(units.data?.data ?? []).map((u) => ({ value: u.id, label: `${u.block}-${u.door_number}` }))} />
                    </Field>
                    <Field label="Tür"><Select value={form.case_type} onChange={(e) => setForm({ ...form, case_type: e.target.value })} options={CASE_TYPES} /></Field>
                    <Field label="Dayanak belge"><Select value={form.basis_document_type} onChange={(e) => setForm({ ...form, basis_document_type: e.target.value })} options={BASIS} placeholder="Belirtilmedi (uyarı verilir)" /></Field>
                    <Field label="İcra dairesi / mahkeme"><Input value={form.office_or_court} onChange={(e) => setForm({ ...form, office_or_court: e.target.value })} /></Field>
                    <Field label="Dosya no"><Input value={form.file_no} onChange={(e) => setForm({ ...form, file_no: e.target.value })} /></Field>
                    <Field label="Avukat"><Input value={form.lawyer_name} onChange={(e) => setForm({ ...form, lawyer_name: e.target.value })} /></Field>
                </Grid>
                <Field label="Not"><Textarea value={form.note} onChange={(e) => setForm({ ...form, note: e.target.value })} /></Field>
                <Notice tone="blue">Anapara ve gecikme tazminatı, dairenin ödenmemiş tahakkuklarından otomatik hesaplanır.</Notice>
            </FormModal>
        </Page>
    );
}
