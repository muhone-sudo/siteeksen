"use client";

import { useState } from "react";
import { Eye, Plus } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Modal, Notice, Page, QueryView, ReadOnlyHint, Select, Stats, StatusBadge, Table, Tabs, Textarea } from "@/components/ui/kit";
import { date, num, tl, today } from "@/lib/format";
import { LEAVE_STATUS } from "@/lib/labels";
import type { Employee, Leave } from "@/lib/types";

const CONTRACT_TYPES = [
    { value: "FULL_TIME", label: "Tam zamanlı" }, { value: "PART_TIME", label: "Yarı zamanlı" },
    { value: "CONTRACT", label: "Sözleşmeli" }, { value: "INTERN", label: "Stajyer" },
];
const LEAVE_TYPES = [
    { value: "ANNUAL", label: "Yıllık izin" }, { value: "SICK", label: "Hastalık" }, { value: "UNPAID", label: "Ücretsiz" },
    { value: "MATERNITY", label: "Doğum" }, { value: "PATERNITY", label: "Babalık" }, { value: "MARRIAGE", label: "Evlilik" },
    { value: "BEREAVEMENT", label: "Ölüm" }, { value: "OTHER", label: "Diğer" },
];
const LEAVE_LABEL = Object.fromEntries(LEAVE_TYPES.map((l) => [l.value, l.label]));

/**
 * Personel. TCKN ve IBAN şifreli saklanır; listede MASKELİ gösterilir.
 * Maskesiz görüntüleme yalnız yöneticiye açıktır ve ayrı denetim kaydı üretir.
 * Görevli (STAFF) maaş/IBAN/SGK bilgisini hiç görmez.
 */
export default function PersonnelPage() {
    const [tab, setTab] = useState<"employees" | "leaves">("employees");
    const [showAll, setShowAll] = useState(false);
    const list = useApi(["employees", showAll], () => api.personnel.list(showAll));
    const summary = useApi(["employees", "summary"], api.personnel.summary);
    const leaves = useApi(["leaves"], () => api.personnel.leaves(), tab === "leaves");
    const act = useAction();
    const { canWrite, roles } = useRoles();
    const isManager = roles.includes("MANAGER") || roles.includes("SUPER_ADMIN");
    const [open, setOpen] = useState(false);
    const blank = { first_name: "", last_name: "", position: "", department: "", hire_date: today(), contract_type: "FULL_TIME", tc_number: "", phone: "", email: "", gross_salary: "", net_salary: "", bank_name: "", bank_iban: "", sgk_number: "", annual_leave_days: "14" };
    const [form, setForm] = useState(blank);
    const [revealed, setRevealed] = useState<Employee | null>(null);
    const [terminating, setTerminating] = useState<Employee | null>(null);
    const [termForm, setTermForm] = useState({ reason: "", end_date: today() });
    const [leaveForm, setLeaveForm] = useState<null | { employee_id: string; leave_type: string; start_date: string; end_date: string; reason: string }>(null);
    const [rejecting, setRejecting] = useState<Leave | null>(null);
    const [reason, setReason] = useState("");

    const s = summary.data;
    return (
        <Page title="Personel" description="Personel özlük, izin ve maaş bilgileri (KVKK: özel önemli değil ama hassas kişisel veri)."
            actions={canWrite && (
                <>
                    <Button variant="secondary" onClick={() => setLeaveForm({ employee_id: "", leave_type: "ANNUAL", start_date: today(), end_date: today(), reason: "" })}>İzin gir</Button>
                    <Button onClick={() => { setForm(blank); setOpen(true); }}><Plus className="h-4 w-4" /> Personel ekle</Button>
                </>
            )}>
            {!canWrite && <ReadOnlyHint />}
            <ActionFeedback action={act} />
            <Stats items={[
                { label: "Aktif personel", value: num(s?.total_active), tone: "blue" },
                { label: "Ayrılan", value: num(s?.total_inactive) },
                { label: "Bekleyen izin", value: num(s?.pending_leaves), tone: "amber" },
                { label: "Aylık maaş maliyeti", value: s?.monthly_salary_cost === undefined ? "Yetki yok" : tl(s.monthly_salary_cost), tone: "purple" },
            ]} />
            <Tabs tabs={[{ id: "employees", label: "Personel" }, { id: "leaves", label: "İzinler" }]} value={tab} onChange={setTab} />
            {tab === "employees" && (
                <Card padded={false} actions={<label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={showAll} onChange={(e) => setShowAll(e.target.checked)} /> Ayrılanları da göster</label>} title="Personel listesi">
                    <QueryView q={list} empty="Personel kaydı yok">
                        {(d) => (
                            <Table rows={d.data} rowKey={(e) => e.id} columns={[
                                { header: "Ad Soyad", cell: (e) => <div><p className="font-medium">{e.first_name} {e.last_name}</p><p className="text-xs text-gray-500">{e.position}{e.department ? ` · ${e.department}` : ""}</p></div> },
                                { header: "TCKN", cell: (e) => <span className="font-mono text-xs">{e.tc_number || "—"}</span> },
                                { header: "İşe giriş", cell: (e) => date(e.hire_date) },
                                { header: "Brüt maaş", cell: (e) => (e.salary_visible ? tl(e.gross_salary) : "—") },
                                { header: "İzin (kalan)", cell: (e) => `${e.remaining_leave_days}/${e.annual_leave_days}` },
                                { header: "Durum", cell: (e) => (e.is_active ? <Badge tone="green">Aktif</Badge> : <Badge>Ayrıldı</Badge>) },
                                { header: "", cell: (e) => (
                                    <div className="flex gap-1">
                                        {isManager && (
                                            <Button size="sm" variant="ghost" title="Maskesiz görüntüle (denetim kaydı oluşur)"
                                                onClick={async () => { const r = await act.run(() => api.personnel.get(e.id, true)); if (r) setRevealed(r); }}>
                                                <Eye className="h-3.5 w-3.5" />
                                            </Button>
                                        )}
                                        {canWrite && e.is_active && <Button size="sm" variant="ghost" onClick={() => { setTermForm({ reason: "", end_date: today() }); setTerminating(e); }}>İlişik kes</Button>}
                                    </div>
                                ) },
                            ]} />
                        )}
                    </QueryView>
                </Card>
            )}
            {tab === "leaves" && (
                <Card padded={false} title="İzin talepleri">
                    <QueryView q={leaves} empty="İzin kaydı yok">
                        {(d) => (
                            <Table rows={d.data} rowKey={(l) => l.id} columns={[
                                { header: "Personel", cell: (l) => l.employee_name ?? "—" },
                                { header: "Tür", cell: (l) => LEAVE_LABEL[l.leave_type] ?? l.leave_type },
                                { header: "Tarih", cell: (l) => `${date(l.start_date)} – ${date(l.end_date)}` },
                                { header: "Gün", cell: (l) => num(l.days) },
                                { header: "Durum", cell: (l) => <StatusBadge value={l.status} map={LEAVE_STATUS} /> },
                                { header: "", cell: (l) => canWrite && l.status === "PENDING" ? (
                                    <div className="flex gap-1">
                                        <Button size="sm" disabled={act.pending} onClick={() => act.run(() => api.personnel.approveLeave(l.id), { invalidate: ["leaves", "employees"], success: "İzin onaylandı" })}>Onayla</Button>
                                        <Button size="sm" variant="danger" onClick={() => { setReason(""); setRejecting(l); }}>Reddet</Button>
                                    </div>
                                ) : null },
                            ]} />
                        )}
                    </QueryView>
                </Card>
            )}

            <FormModal open={open} onClose={() => setOpen(false)} title="Personel ekle" wide pending={act.pending} error={act.error}
                onSubmit={async () => {
                    const body: Record<string, unknown> = { ...form, annual_leave_days: Number(form.annual_leave_days) || undefined };
                    for (const k of ["gross_salary", "net_salary"]) body[k] = form[k as "gross_salary"] ? Number(form[k as "gross_salary"]) : undefined;
                    const r = await act.run(() => api.personnel.create(body), { invalidate: ["employees"], success: "Personel kaydedildi" });
                    if (r) setOpen(false);
                }}>
                <Grid cols={3}>
                    <Field label="Ad" required><Input required value={form.first_name} onChange={(e) => setForm({ ...form, first_name: e.target.value })} /></Field>
                    <Field label="Soyad" required><Input required value={form.last_name} onChange={(e) => setForm({ ...form, last_name: e.target.value })} /></Field>
                    <Field label="Görev" required><Input required value={form.position} onChange={(e) => setForm({ ...form, position: e.target.value })} /></Field>
                    <Field label="Bölüm"><Input value={form.department} onChange={(e) => setForm({ ...form, department: e.target.value })} /></Field>
                    <Field label="İşe giriş" required><Input type="date" required value={form.hire_date} onChange={(e) => setForm({ ...form, hire_date: e.target.value })} /></Field>
                    <Field label="Sözleşme"><Select value={form.contract_type} onChange={(e) => setForm({ ...form, contract_type: e.target.value })} options={CONTRACT_TYPES} /></Field>
                    <Field label="TCKN" hint="Algoritmik olarak doğrulanır; şifreli saklanır."><Input value={form.tc_number} onChange={(e) => setForm({ ...form, tc_number: e.target.value })} maxLength={11} /></Field>
                    <Field label="Telefon"><Input value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} /></Field>
                    <Field label="E-posta"><Input type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} /></Field>
                    <Field label="Brüt maaş (TL)"><Input type="number" step="0.01" value={form.gross_salary} onChange={(e) => setForm({ ...form, gross_salary: e.target.value })} /></Field>
                    <Field label="Net maaş (TL)"><Input type="number" step="0.01" value={form.net_salary} onChange={(e) => setForm({ ...form, net_salary: e.target.value })} /></Field>
                    <Field label="Yıllık izin (gün)" hint="İş K. m.53: 1-5 yıl kıdemde en az 14"><Input type="number" value={form.annual_leave_days} onChange={(e) => setForm({ ...form, annual_leave_days: e.target.value })} /></Field>
                    <Field label="Banka"><Input value={form.bank_name} onChange={(e) => setForm({ ...form, bank_name: e.target.value })} /></Field>
                    <Field label="IBAN" hint="mod-97 doğrulanır; şifreli saklanır."><Input value={form.bank_iban} onChange={(e) => setForm({ ...form, bank_iban: e.target.value })} /></Field>
                    <Field label="SGK no"><Input value={form.sgk_number} onChange={(e) => setForm({ ...form, sgk_number: e.target.value })} /></Field>
                </Grid>
            </FormModal>

            <FormModal open={!!terminating} onClose={() => setTerminating(null)} title={terminating ? `İlişik kes — ${terminating.first_name} ${terminating.last_name}` : ""} submitLabel="İlişiği kes" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!terminating) return;
                    const r = await act.run(() => api.personnel.terminate(terminating.id, termForm.reason, termForm.end_date), { invalidate: ["employees"], success: "Ayrılış işlendi" });
                    if (r) setTerminating(null);
                }}>
                <Notice tone="blue">Kayıt silinmez; özlük dosyası yasal saklama süresince korunur.</Notice>
                <Field label="Gerekçe" required><Textarea required value={termForm.reason} onChange={(e) => setTermForm({ ...termForm, reason: e.target.value })} /></Field>
                <Field label="Ayrılış tarihi"><Input type="date" value={termForm.end_date} onChange={(e) => setTermForm({ ...termForm, end_date: e.target.value })} /></Field>
            </FormModal>

            <FormModal open={!!leaveForm} onClose={() => setLeaveForm(null)} title="İzin gir" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!leaveForm) return;
                    const r = await act.run(() => api.personnel.createLeave(leaveForm), { invalidate: ["leaves", "employees"], success: "İzin talebi oluşturuldu (onay bekliyor)" });
                    if (r) setLeaveForm(null);
                }}>
                {leaveForm && (
                    <Grid>
                        <Field label="Personel" required>
                            <Select required value={leaveForm.employee_id} onChange={(e) => setLeaveForm({ ...leaveForm, employee_id: e.target.value })}
                                options={(list.data?.data ?? []).filter((e) => e.is_active).map((e) => ({ value: e.id, label: `${e.first_name} ${e.last_name}` }))} placeholder="Seçin" />
                        </Field>
                        <Field label="Tür"><Select value={leaveForm.leave_type} onChange={(e) => setLeaveForm({ ...leaveForm, leave_type: e.target.value })} options={LEAVE_TYPES} /></Field>
                        <Field label="Başlangıç" required><Input type="date" value={leaveForm.start_date} onChange={(e) => setLeaveForm({ ...leaveForm, start_date: e.target.value })} /></Field>
                        <Field label="Bitiş" required><Input type="date" value={leaveForm.end_date} onChange={(e) => setLeaveForm({ ...leaveForm, end_date: e.target.value })} /></Field>
                    </Grid>
                )}
            </FormModal>

            <FormModal open={!!rejecting} onClose={() => setRejecting(null)} title="İzni reddet" submitLabel="Reddet" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!rejecting) return;
                    const r = await act.run(() => api.personnel.rejectLeave(rejecting.id, reason), { invalidate: ["leaves"], success: "İzin reddedildi" });
                    if (r) setRejecting(null);
                }}>
                <Field label="Gerekçe" required><Textarea required value={reason} onChange={(e) => setReason(e.target.value)} /></Field>
            </FormModal>

            <Modal open={!!revealed} onClose={() => setRevealed(null)} title="Maskesiz bilgiler">
                {revealed && (
                    <div className="space-y-2 text-sm">
                        <Notice tone="amber">Bu görüntüleme denetim kaydına yazıldı (PII_REVEAL, KVKK m.12).</Notice>
                        <p>TCKN: <span className="font-mono">{revealed.tc_number || "—"}</span></p>
                        <p>IBAN: <span className="font-mono">{revealed.bank_iban || "—"}</span></p>
                    </div>
                )}
            </Modal>
        </Page>
    );
}
