"use client";

import { useState } from "react";
import { Plus, Trash2 } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Modal, Notice, Page, QueryView, ReadOnlyHint, Select, StatusBadge, Table, Tabs } from "@/components/ui/kit";
import { dateTime, localToRFC3339, num, pct } from "@/lib/format";
import { ASSEMBLY_STATUS, DECISION_STATUS } from "@/lib/labels";
import type { AgendaItem, MajorityResult } from "@/lib/types";

/** Özel nisap kodları — mevzuat tablosundaki (legal_parameters) kodlarla aynıdır. Boş = olağan çoğunluk. */
const MAJORITY = [
    { value: "", label: "Olağan çoğunluk (KMK m.30)" },
    // Etiketler 012_legal_parameters.sql'deki dayanaklarla birebir aynıdır.
    { value: "MAJORITY_INNOVATION", label: "Yenilik ve ilaveler — sayı ve arsa payı çoğunluğu (m.42)" },
    { value: "MAJORITY_CONSTRUCTION_CONSENT", label: "Ortak yerlerde inşaat/değişiklik — 4/5 (m.19/2)" },
    { value: "MAJORITY_MANAGEMENT_PLAN_CHANGE", label: "Yönetim planı değişikliği — 4/5 (m.28)" },
    { value: "UNANIMITY_TRANSFER_ACTS", label: "Temliki tasarruf / kiralama — oybirliği (m.45)" },
];
const NOTICE_METHODS = [
    { value: "IMZA_KARSILIGI", label: "İmza karşılığı elden" },
    { value: "TAAHHUTLU_MEKTUP", label: "Taahhütlü mektup" },
];

/**
 * Kat malikleri kurulu (KMK m.29-33). Akış: planla → çağrı (en az 15 gün önce,
 * imza karşılığı ya da taahhütlü mektup) → hazirun → toplantıyı yap (nisap
 * fotoğrafı) → gündem maddelerinde oylama → maddeyi kapat (çoğunluk hesabı).
 */
export default function AssembliesPage() {
    const list = useApi(["assemblies"], api.governance.assemblies);
    const act = useAction();
    const { canWrite } = useRoles();
    const [open, setOpen] = useState(false);
    const [form, setForm] = useState({ kind: "ORDINARY", call_number: 1, scheduled_at: "", location: "", items: [{ title: "", description: "", required_majority_code: "" }] });
    const [selected, setSelected] = useState<string | null>(null);

    return (
        <Page title="Genel kurul" description="Kat malikleri kurulu toplantıları, hazirun, nisap ve kararlar."
            actions={canWrite && <Button onClick={() => setOpen(true)}><Plus className="h-4 w-4" /> Toplantı planla</Button>}>
            {!canWrite && <ReadOnlyHint />}
            <ActionFeedback action={act} />
            <Card padded={false}>
                <QueryView q={list} empty="Toplantı yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(a) => a.id} columns={[
                            { header: "Tarih", cell: (a) => dateTime(a.scheduled_at) },
                            { header: "Tür", cell: (a) => `${a.kind === "ORDINARY" ? "Olağan" : "Olağanüstü"} · ${a.call_number}. toplantı` },
                            { header: "Yer", cell: (a) => a.location ?? "—" },
                            { header: "Çağrı", cell: (a) => dateTime(a.notice_sent_at) },
                            { header: "Durum", cell: (a) => <StatusBadge value={a.status} map={ASSEMBLY_STATUS} /> },
                            { header: "Nisap", cell: (a) => (a.quorum_met === undefined || a.quorum_met === null ? "—" : a.quorum_met ? <Badge tone="green">Sağlandı</Badge> : <Badge tone="red">Yok</Badge>) },
                            { header: "", cell: (a) => <Button size="sm" variant="ghost" onClick={() => setSelected(a.id)}>Aç</Button> },
                        ]} />
                    )}
                </QueryView>
            </Card>

            <FormModal open={open} onClose={() => setOpen(false)} title="Toplantı planla" wide pending={act.pending} error={act.error}
                onSubmit={async () => {
                    const r = await act.run(() => api.governance.createAssembly({
                        kind: form.kind, call_number: form.call_number, scheduled_at: localToRFC3339(form.scheduled_at), location: form.location,
                        agenda_items: form.items.filter((i) => i.title.trim()),
                    }), { invalidate: ["assemblies"], success: "Toplantı planlandı" });
                    if (r) { setOpen(false); setSelected(r.id); }
                }}>
                <Grid>
                    <Field label="Tür"><Select value={form.kind} onChange={(e) => setForm({ ...form, kind: e.target.value })} options={[{ value: "ORDINARY", label: "Olağan" }, { value: "EXTRAORDINARY", label: "Olağanüstü" }]} /></Field>
                    <Field label="Toplantı" hint="İlk toplantıda nisap sağlanmazsa ikinci toplantıda yeter sayı aranmaz (m.30/3).">
                        <Select value={String(form.call_number)} onChange={(e) => setForm({ ...form, call_number: Number(e.target.value) })} options={[{ value: "1", label: "1. toplantı" }, { value: "2", label: "2. toplantı" }]} />
                    </Field>
                    <Field label="Tarih ve saat" required hint="Çağrı en az 15 gün önce yapılmalıdır (m.29)."><Input required type="datetime-local" value={form.scheduled_at} onChange={(e) => setForm({ ...form, scheduled_at: e.target.value })} /></Field>
                    <Field label="Yer"><Input value={form.location} onChange={(e) => setForm({ ...form, location: e.target.value })} /></Field>
                </Grid>
                <div className="space-y-2">
                    <p className="text-sm font-medium">Gündem</p>
                    {form.items.map((it, i) => (
                        <div key={i} className="grid grid-cols-12 gap-2">
                            <Input className="col-span-6" placeholder={`${i + 1}. madde başlığı`} value={it.title}
                                onChange={(e) => setForm({ ...form, items: form.items.map((x, j) => (j === i ? { ...x, title: e.target.value } : x)) })} />
                            <Select className="col-span-5" value={it.required_majority_code} options={MAJORITY}
                                onChange={(e) => setForm({ ...form, items: form.items.map((x, j) => (j === i ? { ...x, required_majority_code: e.target.value } : x)) })} />
                            <Button className="col-span-1" variant="ghost" aria-label="Maddeyi çıkar" onClick={() => setForm({ ...form, items: form.items.filter((_, j) => j !== i) })}><Trash2 className="h-4 w-4" /></Button>
                        </div>
                    ))}
                    <Button size="sm" variant="secondary" onClick={() => setForm({ ...form, items: [...form.items, { title: "", description: "", required_majority_code: "" }] })}>+ Madde</Button>
                </div>
            </FormModal>

            {selected && <AssemblyDetail id={selected} onClose={() => setSelected(null)} canWrite={canWrite} />}
        </Page>
    );
}

function AssemblyDetail({ id, onClose, canWrite }: { id: string; onClose: () => void; canWrite: boolean }) {
    const q = useApi(["assemblies", id], () => api.governance.assembly(id));
    const attendees = useApi(["assemblies", id, "attendees"], () => api.governance.attendees(id));
    const quorum = useApi(["assemblies", id, "quorum"], () => api.governance.quorum(id));
    const units = useApi(["units"], api.identity.units);
    const residents = useApi(["residents", "", ""], () => api.identity.residents());
    const act = useAction();
    const [tab, setTab] = useState<"agenda" | "attendees">("agenda");
    const [method, setMethod] = useState("TAAHHUTLU_MEKTUP");
    const [att, setAtt] = useState({ unit_id: "", attendance_type: "SELF", proxy_holder_id: "" });
    const [voting, setVoting] = useState<AgendaItem | null>(null);
    const [vote, setVote] = useState({ unit_id: "", vote: "FOR" });
    const [result, setResult] = useState<MajorityResult | null>(null);
    const inv = ["assemblies"];

    return (
        <Modal open onClose={onClose} title="Genel kurul" wide>
            <QueryView q={q} isEmpty={() => false}>
                {(a) => {
                    const open = a.status === "PLANNED" || a.status === "NOTIFIED";
                    const attendeeUnits = new Set((attendees.data?.data ?? []).map((x) => x.unit_id));
                    return (
                        <div className="space-y-4">
                            <div className="flex flex-wrap items-center gap-3 text-sm">
                                <b>{dateTime(a.scheduled_at)}</b>
                                <StatusBadge value={a.status} map={ASSEMBLY_STATUS} />
                                <span>{a.call_number}. toplantı</span>
                                {a.notice_method && <span>Çağrı: {a.notice_method}</span>}
                            </div>
                            <ActionFeedback action={act} />
                            {quorum.data && (
                                <Notice tone={quorum.data.met ? "green" : "amber"} title={`Nisap: ${quorum.data.met ? "sağlanıyor" : "sağlanmıyor"}`}>
                                    Katılım {quorum.data.attended_units}/{quorum.data.total_units} daire, arsa payı {num(quorum.data.attended_share_ratio)}/{num(quorum.data.total_share_ratio)}.
                                    {" "}{quorum.data.explanation} <span className="text-xs">({quorum.data.legal_basis})</span>
                                </Notice>
                            )}
                            {canWrite && (
                                <div className="flex flex-wrap items-end gap-2 rounded-lg bg-gray-50 p-3 dark:bg-gray-700/40">
                                    {a.status === "PLANNED" && (
                                        <>
                                            <Field label="Çağrı yöntemi"><Select value={method} onChange={(e) => setMethod(e.target.value)} options={NOTICE_METHODS} /></Field>
                                            <Button disabled={act.pending} onClick={() => act.run(() => api.governance.notifyAssembly(a.id, method), { invalidate: inv, success: "Çağrı kaydedildi" })}>Çağrıyı kaydet</Button>
                                        </>
                                    )}
                                    {open && (
                                        <Button variant="secondary" disabled={act.pending}
                                            onClick={() => act.run(() => api.governance.hold(a.id), { invalidate: inv, success: (r) => `Toplantı yapıldı. Nisap ${r.met ? "sağlandı" : "SAĞLANMADI"}` })}>
                                            Toplantıyı yap (nisap fotoğrafı)
                                        </Button>
                                    )}
                                </div>
                            )}
                            <Tabs tabs={[{ id: "agenda", label: "Gündem ve kararlar" }, { id: "attendees", label: `Hazirun (${attendees.data?.data.length ?? 0})` }]} value={tab} onChange={setTab} />
                            {tab === "agenda" && (
                                <Table rows={a.agenda_items ?? []} rowKey={(i) => i.id} columns={[
                                    { header: "#", cell: (i) => i.order_no },
                                    { header: "Madde", cell: (i) => <div><p className="font-medium">{i.title}</p>{i.decision_text && <p className="text-xs text-gray-500">{i.decision_text}</p>}</div> },
                                    { header: "Nisap", cell: (i) => MAJORITY.find((m) => m.value === (i.required_majority_code ?? ""))?.label ?? i.required_majority_code },
                                    { header: "Oylar (lehte/aleyhte/çekimser)", cell: (i) => `${i.votes_for}/${i.votes_against}/${i.votes_abstain}` },
                                    { header: "Karar", cell: (i) => <StatusBadge value={i.decision_status} map={DECISION_STATUS} /> },
                                    { header: "", cell: (i) => canWrite && a.status === "HELD" && i.decision_status === "PENDING" ? (
                                        <div className="flex gap-1">
                                            <Button size="sm" onClick={() => { setVote({ unit_id: "", vote: "FOR" }); setVoting(i); }}>Oy gir</Button>
                                            <Button size="sm" variant="secondary" disabled={act.pending}
                                                onClick={async () => { const r = await act.run(() => api.governance.closeItem(i.id), { invalidate: inv }); if (r) setResult(r); }}>
                                                Kararı hesapla
                                            </Button>
                                        </div>
                                    ) : null },
                                ]} />
                            )}
                            {tab === "attendees" && (
                                <div className="space-y-3">
                                    {canWrite && open && (
                                        <div className="flex flex-wrap items-end gap-2">
                                            <Field label="Daire">
                                                <Select value={att.unit_id} onChange={(e) => setAtt({ ...att, unit_id: e.target.value })} placeholder="Seçin"
                                                    options={(units.data?.data ?? []).filter((u) => !attendeeUnits.has(u.id)).map((u) => ({ value: u.id, label: `${u.block}-${u.door_number} (arsa payı ${num(u.share_ratio)})` }))} />
                                            </Field>
                                            <Field label="Katılım"><Select value={att.attendance_type} onChange={(e) => setAtt({ ...att, attendance_type: e.target.value })} options={[{ value: "SELF", label: "Bizzat" }, { value: "PROXY", label: "Vekâletle" }]} /></Field>
                                            {att.attendance_type === "PROXY" && (
                                                <Field label="Vekil" hint="m.31: bir vekil toplam oyun %5'inden fazlasını kullanamaz">
                                                    <Select value={att.proxy_holder_id} onChange={(e) => setAtt({ ...att, proxy_holder_id: e.target.value })} placeholder="Seçin"
                                                        options={(residents.data?.data ?? []).map((r) => ({ value: r.user_id, label: `${r.first_name} ${r.last_name}` }))} />
                                                </Field>
                                            )}
                                            <Button disabled={act.pending || !att.unit_id}
                                                onClick={() => act.run(() => api.governance.addAttendee(a.id, { ...att, proxy_holder_id: att.proxy_holder_id || undefined }),
                                                    { invalidate: inv, success: "Hazirune eklendi" })}>Ekle</Button>
                                        </div>
                                    )}
                                    <QueryView q={attendees} empty="Hazirun boş">
                                        {(d) => (
                                            <Table rows={d.data} rowKey={(x) => x.unit_id} columns={[
                                                { header: "Daire", cell: (x) => x.unit_name },
                                                { header: "Katılan", cell: (x) => x.user_name || "—" },
                                                { header: "Katılım", cell: (x) => (x.attendance_type === "PROXY" ? `Vekâlet: ${x.proxy_holder_name ?? ""}` : "Bizzat") },
                                                { header: "Arsa payı", cell: (x) => num(x.share_ratio) },
                                            ]} />
                                        )}
                                    </QueryView>
                                </div>
                            )}
                            <FormModal open={!!voting} onClose={() => setVoting(null)} title={voting ? `Oy — ${voting.title}` : ""} submitLabel="Oyu kaydet" pending={act.pending} error={act.error}
                                onSubmit={async () => {
                                    if (!voting) return;
                                    const r = await act.run(() => api.governance.vote(voting.id, vote.unit_id, vote.vote), { invalidate: inv, success: "Oy kaydedildi" });
                                    if (r) setVote({ unit_id: "", vote: "FOR" });
                                }}>
                                <Grid>
                                    <Field label="Daire (hazirundan)" required>
                                        <Select required value={vote.unit_id} onChange={(e) => setVote({ ...vote, unit_id: e.target.value })} placeholder="Seçin"
                                            options={(attendees.data?.data ?? []).map((x) => ({ value: x.unit_id, label: x.unit_name }))} />
                                    </Field>
                                    <Field label="Oy"><Select value={vote.vote} onChange={(e) => setVote({ ...vote, vote: e.target.value })} options={[{ value: "FOR", label: "Lehte" }, { value: "AGAINST", label: "Aleyhte" }, { value: "ABSTAIN", label: "Çekimser" }]} /></Field>
                                </Grid>
                                <p className="text-xs text-gray-500">Aynı dairenin ikinci oyu öncekinin yerine geçer.</p>
                            </FormModal>
                            <Modal open={!!result} onClose={() => setResult(null)} title="Karar">
                                {result && (
                                    <div className="space-y-2 text-sm">
                                        <Notice tone={result.accepted ? "green" : "red"} title={result.accepted ? "Kabul edildi" : "Reddedildi"}>{result.explanation}</Notice>
                                        <p>Sayı oranı {pct(result.by_count_ratio * 100, 1)} · arsa payı oranı {pct(result.by_share_ratio * 100, 1)}</p>
                                        <p className="text-xs text-gray-500">{result.legal_basis}</p>
                                    </div>
                                )}
                            </Modal>
                        </div>
                    );
                }}
            </QueryView>
        </Modal>
    );
}
