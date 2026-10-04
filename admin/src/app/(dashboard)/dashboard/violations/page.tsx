"use client";

import { useState } from "react";
import { Plus } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Modal, Notice, Page, QueryView, Select, StatusBadge, Table, Textarea } from "@/components/ui/kit";
import { date, dateTime } from "@/lib/format";

const CATEGORY: Record<string, string> = {
    NOISE: "Gürültü", PET: "Evcil hayvan", PARKING: "Otopark", WASTE: "Çöp / atık",
    COMMON_AREA: "Ortak alan kullanımı", RENOVATION: "Tadilat", OTHER: "Diğer",
};
const STATUS = {
    OPEN: ["Doğrulama bekliyor", "amber"], VERIFIED: ["Doğrulandı", "blue"],
    DISMISSED: ["Doğrulanmadı", "gray"], RESOLVED: ["Kapandı", "green"],
} as Record<string, [string, "amber" | "blue" | "gray" | "green"]>;
const STAGE: Record<string, string> = {
    NONE: "—", VERBAL_WARNING: "Sözlü uyarı", WRITTEN_WARNING: "Yazılı uyarı", FORMAL_NOTICE: "İhtar", LEGAL: "Hukuki yol (KMK m.33)",
};
const STAGE_ORDER = ["NONE", "VERBAL_WARNING", "WRITTEN_WARNING", "FORMAL_NOTICE", "LEGAL"];
const EVENT: Record<string, string> = {
    REPORTED: "Bildirildi", VERIFIED: "Doğrulandı", DISMISSED: "Doğrulanmadı", RESPONSE: "Savunma", RESOLVED: "Kapatıldı", ...STAGE,
};

/**
 * Kural ihlali (FAZ 7.5). Kurallar yönetim planına atıflıdır (KMK m.28). Para cezası
 * yoktur (5326 s. Kabahatler K. m.22); süreç uyarı → ihtar → sulh hukuk mahkemesi (KMK m.33).
 */
export default function ViolationsPage() {
    const rules = useApi(["site-rules"], api.violations.rules);
    const list = useApi(["violations"], api.violations.list);
    const units = useApi(["units"], api.identity.units);
    const act = useAction();
    const { canWrite } = useRoles();
    const [ruleForm, setRuleForm] = useState<{ title: string; category: string; description: string; management_plan_ref: string } | null>(null);
    const [report, setReport] = useState<{ rule_id: string; unit_id: string; description: string } | null>(null);
    const [selected, setSelected] = useState<string | null>(null);

    return (
        <Page title="Kural ihlalleri" description="Yönetim planı kuralları, ihlal bildirimi ve kademeli uyarı süreci (KMK m.18, 28, 33)."
            actions={canWrite && <Button onClick={() => setReport({ rule_id: "", unit_id: "", description: "" })}><Plus className="h-4 w-4" /> İhlal kaydet</Button>}>
            <ActionFeedback action={act} />
            <Notice tone="blue">Site yönetimi para cezası veremez; idari yaptırım yetkisi kanunda gösterilen kamu mercilerindedir (Kabahatler K. m.22). Süreç: uyarı → yazılı uyarı → ihtar → sulh hukuk mahkemesinden hâkimin müdahalesi (KMK m.33).</Notice>
            <Card padded={false}>
                <QueryView q={list} empty="İhlal kaydı yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(v) => v.id} columns={[
                            { header: "Daire", cell: (v) => <b>{v.unit}</b> },
                            { header: "Kural", cell: (v) => v.rule_title },
                            { header: "Olay", cell: (v) => dateTime(v.occurred_at) },
                            { header: "Bildiren", cell: (v) => v.reporter_name || "—" },
                            { header: "Durum", cell: (v) => <StatusBadge value={v.status} map={STATUS} /> },
                            { header: "Kademe", cell: (v) => STAGE[v.stage] },
                            { header: "Son 24 ay", cell: (v) => (v.unit_repeat_count > 1 ? <Badge tone="red">{v.unit_repeat_count} ihlal</Badge> : v.unit_repeat_count) },
                            { header: "", cell: (v) => <Button size="sm" variant="ghost" onClick={() => setSelected(v.id)}>Aç</Button> },
                        ]} />
                    )}
                </QueryView>
            </Card>

            <Card title="Kural kataloğu" actions={canWrite && <Button size="sm" variant="secondary" onClick={() => setRuleForm({ title: "", category: "NOISE", description: "", management_plan_ref: "" })}>Kural ekle</Button>} padded={false}>
                <QueryView q={rules} empty="Kural tanımlanmamış">
                    {(d) => (
                        <Table rows={d.data} rowKey={(r) => r.id} columns={[
                            { header: "Kural", cell: (r) => <b>{r.title}</b> },
                            { header: "Kategori", cell: (r) => CATEGORY[r.category] ?? r.category },
                            { header: "Yönetim planı dayanağı", cell: (r) => r.management_plan_ref },
                            { header: "Durum", cell: (r) => (r.is_active ? <Badge tone="green">Etkin</Badge> : <Badge>Pasif</Badge>) },
                            ...(canWrite ? [{
                                header: "", cell: (r: { id: string; is_active: boolean }) => r.is_active ? (
                                    <Button size="sm" variant="ghost" disabled={act.pending}
                                        onClick={() => act.run(() => api.violations.deactivateRule(r.id), { invalidate: ["site-rules"], success: "Kural pasifleştirildi" })}>Pasifleştir</Button>
                                ) : null,
                            }] : []),
                        ]} />
                    )}
                </QueryView>
            </Card>

            <FormModal open={!!ruleForm} onClose={() => setRuleForm(null)} title="Kural ekle" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!ruleForm) return;
                    const r = await act.run(() => api.violations.createRule(ruleForm), { invalidate: ["site-rules"], success: "Kural eklendi" });
                    if (r) setRuleForm(null);
                }}>
                {ruleForm && (
                    <>
                        <Grid>
                            <Field label="Kural" required><Input required value={ruleForm.title} onChange={(e) => setRuleForm({ ...ruleForm, title: e.target.value })} /></Field>
                            <Field label="Kategori"><Select value={ruleForm.category} onChange={(e) => setRuleForm({ ...ruleForm, category: e.target.value })} options={Object.entries(CATEGORY).map(([value, label]) => ({ value, label }))} /></Field>
                        </Grid>
                        <Field label="Yönetim planı dayanağı" required hint="Yönetim planında karşılığı olmayan kural kat maliklerini bağlamaz (KMK m.28)">
                            <Input required value={ruleForm.management_plan_ref} onChange={(e) => setRuleForm({ ...ruleForm, management_plan_ref: e.target.value })} placeholder="Yönetim planı m.12/3" />
                        </Field>
                        <Field label="Açıklama"><Textarea value={ruleForm.description} onChange={(e) => setRuleForm({ ...ruleForm, description: e.target.value })} /></Field>
                    </>
                )}
            </FormModal>

            <FormModal open={!!report} onClose={() => setReport(null)} title="İhlal kaydet" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!report) return;
                    const r = await act.run(() => api.violations.create(report), { invalidate: ["violations"], success: "İhlal kaydedildi" });
                    if (r) { setReport(null); setSelected(r.violation.id); }
                }}>
                {report && (
                    <>
                        <Grid>
                            <Field label="Kural" required>
                                <Select required value={report.rule_id} onChange={(e) => setReport({ ...report, rule_id: e.target.value })}
                                    options={[{ value: "", label: "Seçin" }, ...(rules.data?.data ?? []).filter((r) => r.is_active).map((r) => ({ value: r.id, label: r.title }))]} />
                            </Field>
                            <Field label="Daire" required>
                                <Select required value={report.unit_id} onChange={(e) => setReport({ ...report, unit_id: e.target.value })}
                                    options={[{ value: "", label: "Seçin" }, ...(units.data?.data ?? []).map((u) => ({ value: u.id, label: `${u.block}-${u.door_number}` }))]} />
                            </Field>
                        </Grid>
                        <Field label="Ne oldu?" required><Textarea required value={report.description} onChange={(e) => setReport({ ...report, description: e.target.value })} /></Field>
                    </>
                )}
            </FormModal>

            {selected && <ViolationDetail id={selected} canWrite={canWrite} onClose={() => setSelected(null)} />}
        </Page>
    );
}

function ViolationDetail({ id, canWrite, onClose }: { id: string; canWrite: boolean; onClose: () => void }) {
    const q = useApi(["violations", id], () => api.violations.get(id));
    const act = useAction();
    const [modal, setModal] = useState<{ kind: "dismiss" | "resolve" | "escalate"; stage?: string; note: string } | null>(null);
    const inv = { invalidate: ["violations"] };

    return (
        <Modal open onClose={onClose} title="İhlal kaydı" wide>
            <QueryView q={q} isEmpty={() => false}>
                {(v) => (
                    <div className="space-y-4">
                        <div className="flex flex-wrap items-center gap-3 text-sm">
                            <b className="text-lg">{v.unit}</b>
                            <StatusBadge value={v.status} map={STATUS} />
                            <span>{v.rule_title} ({v.management_plan_ref})</span>
                            <span>Kademe: {STAGE[v.stage]}</span>
                        </div>
                        <p className="text-sm">{v.description}</p>
                        <ActionFeedback action={act} />
                        {canWrite && v.status === "OPEN" && (
                            <div className="flex gap-2">
                                <Button disabled={act.pending} onClick={() => act.run(() => api.violations.verify(v.id), { ...inv, success: "Doğrulandı" })}>Doğrula</Button>
                                <Button variant="danger" onClick={() => setModal({ kind: "dismiss", note: "" })}>Doğrulanmadı</Button>
                            </div>
                        )}
                        {canWrite && v.status === "VERIFIED" && (
                            <div className="flex flex-wrap gap-2">
                                {STAGE_ORDER.slice(STAGE_ORDER.indexOf(v.stage) + 1).map((s) => (
                                    <Button key={s} size="sm" variant={s === "LEGAL" ? "danger" : "secondary"} onClick={() => setModal({ kind: "escalate", stage: s, note: "" })}>{STAGE[s]}</Button>
                                ))}
                                <Button size="sm" onClick={() => setModal({ kind: "resolve", note: "" })}>Kapat</Button>
                                <Button size="sm" variant="ghost" onClick={() => setModal({ kind: "dismiss", note: "" })}>Doğrulanmadı</Button>
                            </div>
                        )}
                        <Card title="Olay geçmişi" padded={false}>
                            <Table rows={v.events ?? []} rowKey={(e) => e.created_at + e.event_type} columns={[
                                { header: "Zaman", cell: (e) => dateTime(e.created_at) },
                                { header: "Olay", cell: (e) => EVENT[e.event_type] ?? e.event_type },
                                { header: "Kişi", cell: (e) => e.actor_name || "—" },
                                { header: "Açıklama", cell: (e) => e.note ?? "" },
                            ]} />
                        </Card>
                        <p className="text-xs text-gray-500">Olay geçmişi değiştirilemez; sulh hukuk mahkemesine (KMK m.33) taşınacak dosyanın kaydıdır. Kayıt: {date(v.created_at)}.</p>

                        <FormModal open={!!modal} onClose={() => setModal(null)} pending={act.pending} error={act.error}
                            title={modal?.kind === "escalate" ? STAGE[modal.stage ?? ""] : modal?.kind === "resolve" ? "Kaydı kapat" : "Doğrulanmadı"}
                            onSubmit={async () => {
                                if (!modal) return;
                                const r = await act.run(() => modal.kind === "escalate" ? api.violations.escalate(v.id, modal.stage ?? "", modal.note)
                                    : modal.kind === "resolve" ? api.violations.resolve(v.id, modal.note) : api.violations.dismiss(v.id, modal.note),
                                { ...inv, success: "Kaydedildi" });
                                if (r) setModal(null);
                            }}>
                            {modal?.kind === "escalate" && <Notice tone="amber">Bildirim dairenin bütün aktif sakinlerine (malik ve kiracı) gider; kiracı malikle müteselsil sorumludur (KMK m.18).</Notice>}
                            <Field label="Açıklama" required={modal?.kind !== "escalate" || modal.stage !== "VERBAL_WARNING"}>
                                <Textarea value={modal?.note ?? ""} onChange={(e) => modal && setModal({ ...modal, note: e.target.value })} />
                            </Field>
                        </FormModal>
                    </div>
                )}
            </QueryView>
        </Modal>
    );
}
