"use client";

import { useState } from "react";
import { Plus } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Modal, Notice, Page, QueryView, Select, StatusBadge, Table, Textarea } from "@/components/ui/kit";
import { date, tl, today } from "@/lib/format";
import type { RenovationPermit } from "@/lib/types";

const SCOPE: { value: RenovationPermit["scope"]; label: string; hint: string }[] = [
    { value: "INTERIOR", label: "İç tadilat (taşıyıcıya dokunmayan)", hint: "Yönetim onayı yeterlidir." },
    { value: "STRUCTURAL", label: "Taşıyıcı sistem / esaslı tadilat", hint: "Yapı ruhsatı / belediye izni gerekir (İmar K. m.21). Anayapıya zarar verecek değişiklik yapılamaz (KMK m.19/2)." },
    { value: "COMMON_AREA", label: "Ortak yerde değişiklik", hint: "Bütün kat maliklerinin 4/5 yazılı rızası ya da bu nisapla alınmış genel kurul kararı gerekir (KMK m.19/2)." },
    { value: "FACADE", label: "Dış cephe / balkon / pencere", hint: "Bütün kat maliklerinin 4/5 yazılı rızası ya da bu nisapla alınmış genel kurul kararı gerekir (KMK m.19/2)." },
];
const STATUS = {
    PENDING: ["Onay bekliyor", "amber"], APPROVED: ["Onaylandı", "green"], REJECTED: ["Reddedildi", "red"],
    STOPPED: ["Durduruldu", "red"], COMPLETED: ["Tamamlandı", "gray"], CANCELLED: ["Geri çekildi", "gray"],
} as Record<string, [string, "amber" | "green" | "red" | "gray"]>;
const scopeLabel = (s: string) => SCOPE.find((x) => x.value === s)?.label ?? s;

/**
 * Tadilat izni (FAZ 7.5). Para cezası yoktur: site yönetimi idari para cezası
 * veremez (5326 s. Kabahatler K. m.22); ihlalde çalışma durdurulur, hasar teminattan
 * karşılanır, gerekirse sulh hukuk mahkemesine başvurulur (KMK m.33).
 */
export default function RenovationsPage() {
    const q = useApi(["renovations"], api.renovations.list);
    const units = useApi(["units"], api.identity.units);
    const act = useAction();
    const { canWrite } = useRoles();
    const [open, setOpen] = useState(false);
    const [selected, setSelected] = useState<string | null>(null);
    const [form, setForm] = useState({ unit_id: "", scope: "INTERIOR", description: "", contractor_name: "", contractor_phone: "", start_date: today(), end_date: today() });

    return (
        <Page title="Tadilat izinleri" description="Bağımsız bölüm ve ortak yer tadilatları; onay, komşu bilgilendirme, teminat (KMK m.19, İmar K. m.21)."
            actions={canWrite && <Button onClick={() => setOpen(true)}><Plus className="h-4 w-4" /> Başvuru gir</Button>}>
            <ActionFeedback action={act} />
            <Card padded={false}>
                <QueryView q={q} empty="Tadilat izni yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(p) => p.id} columns={[
                            { header: "Daire", cell: (p) => <b>{p.unit}</b> },
                            { header: "Kapsam", cell: (p) => scopeLabel(p.scope) },
                            { header: "Başvuran", cell: (p) => p.applicant_name || "—" },
                            { header: "Tarih", cell: (p) => `${date(p.start_date)} – ${date(p.end_date)}` },
                            { header: "Durum", cell: (p) => <StatusBadge value={p.status} map={STATUS} /> },
                            { header: "Teminat", cell: (p) => (p.deposit_amount > 0 ? tl(p.deposit_amount) : "—") },
                            { header: "", cell: (p) => <Button size="sm" variant="ghost" onClick={() => setSelected(p.id)}>Aç</Button> },
                        ]} />
                    )}
                </QueryView>
            </Card>

            <FormModal open={open} onClose={() => setOpen(false)} title="Tadilat başvurusu" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    const r = await act.run(() => api.renovations.create(form), { invalidate: ["renovations"], success: (x) => `Başvuru kaydedildi. ${x.requirement}` });
                    if (r) { setOpen(false); setSelected(r.permit.id); }
                }}>
                <Grid>
                    <Field label="Daire" required>
                        <Select required value={form.unit_id} onChange={(e) => setForm({ ...form, unit_id: e.target.value })}
                            options={[{ value: "", label: "Seçin" }, ...(units.data?.data ?? []).map((u) => ({ value: u.id, label: `${u.block}-${u.door_number}` }))]} />
                    </Field>
                    <Field label="Kapsam" required>
                        <Select value={form.scope} onChange={(e) => setForm({ ...form, scope: e.target.value })} options={SCOPE.map(({ value, label }) => ({ value, label }))} />
                    </Field>
                    <Field label="Başlangıç" required><Input type="date" required value={form.start_date} onChange={(e) => setForm({ ...form, start_date: e.target.value })} /></Field>
                    <Field label="Bitiş" required><Input type="date" required value={form.end_date} onChange={(e) => setForm({ ...form, end_date: e.target.value })} /></Field>
                    <Field label="Müteahhit / usta"><Input value={form.contractor_name} onChange={(e) => setForm({ ...form, contractor_name: e.target.value })} /></Field>
                    <Field label="Müteahhit telefonu"><Input value={form.contractor_phone} onChange={(e) => setForm({ ...form, contractor_phone: e.target.value })} /></Field>
                </Grid>
                <Field label="Yapılacak iş" required><Textarea required rows={4} value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} /></Field>
                <Notice tone="blue">{SCOPE.find((s) => s.value === form.scope)?.hint}</Notice>
            </FormModal>

            {selected && <PermitDetail id={selected} canWrite={canWrite} onClose={() => setSelected(null)} />}
        </Page>
    );
}

function PermitDetail({ id, canWrite, onClose }: { id: string; canWrite: boolean; onClose: () => void }) {
    const q = useApi(["renovations", id], () => api.renovations.get(id));
    const residents = useApi(["residents", "owners"], () => api.identity.residents({ role: "OWNER" }), canWrite);
    const act = useAction();
    const [approve, setApprove] = useState({ conditions: "", deposit: "", permit_ref: "", agenda_item_id: "" });
    const [owner, setOwner] = useState("");
    const [docRef, setDocRef] = useState("");
    const [reason, setReason] = useState<{ kind: "reject" | "stop"; text: string } | null>(null);
    const [complete, setComplete] = useState<{ refund: string; note: string } | null>(null);
    const inv = { invalidate: ["renovations"] };

    return (
        <Modal open onClose={onClose} title="Tadilat izni" wide>
            <QueryView q={q} isEmpty={() => false}>
                {({ permit: p, consents }) => (
                    <div className="space-y-4">
                        <div className="flex flex-wrap items-center gap-3 text-sm">
                            <b className="text-lg">{p.unit}</b>
                            <StatusBadge value={p.status} map={STATUS} />
                            <span>{scopeLabel(p.scope)}</span>
                            <span>{date(p.start_date)} – {date(p.end_date)}</span>
                        </div>
                        <p className="text-sm">{p.description}</p>
                        <div className="grid gap-1 text-sm text-gray-600 dark:text-gray-400">
                            {p.contractor_name && <span>Müteahhit: {p.contractor_name} {p.contractor_phone}</span>}
                            {p.work_hours && <span>Çalışma saatleri: {p.work_hours}</span>}
                            {p.conditions && <span>Koşullar: {p.conditions}</span>}
                            {p.deposit_amount > 0 && <span>Teminat: {tl(p.deposit_amount)}{p.deposit_refunded != null && ` · iade ${tl(p.deposit_refunded)}`}</span>}
                            {p.permit_ref && <span>Ruhsat / izin: {p.permit_ref}</span>}
                            {p.decision_note && <span>Ret gerekçesi: {p.decision_note}</span>}
                            {p.stop_reason && <span>Durdurma gerekçesi: {p.stop_reason}</span>}
                            {p.completion_note && <span>Kapanış notu: {p.completion_note}</span>}
                        </div>
                        <ActionFeedback action={act} />

                        {(p.scope === "COMMON_AREA" || p.scope === "FACADE") && (
                            <Card title={`Kat maliki yazılı rızaları (${consents.length}${p.consent_required ? ` / ${p.consent_required}` : ""})`}>
                                <Table rows={consents} rowKey={(c) => c.owner_user_id} columns={[
                                    { header: "Kat maliki", cell: (c) => c.owner_name },
                                    { header: "Belge tarihi", cell: (c) => date(c.consented_on) },
                                    { header: "Belge", cell: (c) => c.document_ref ?? "—" },
                                ]} />
                                {canWrite && p.status === "PENDING" && (
                                    <div className="mt-3 flex flex-wrap items-end gap-2">
                                        <Field label="Kat maliki">
                                            <Select value={owner} onChange={(e) => setOwner(e.target.value)}
                                                options={[{ value: "", label: "Seçin" }, ...Array.from(new Map((residents.data?.data ?? []).filter((r) => r.role === "OWNER" && r.is_active)
                                                    .map((r) => [r.user_id, `${r.first_name} ${r.last_name}`])).entries()).map(([value, label]) => ({ value, label }))]} />
                                        </Field>
                                        <Field label="Belge referansı"><Input value={docRef} onChange={(e) => setDocRef(e.target.value)} placeholder="İmzalı muvafakatname no" /></Field>
                                        <Button disabled={!owner || act.pending} onClick={async () => {
                                            const r = await act.run(() => api.renovations.consent(p.id, { owner_user_id: owner, document_ref: docRef }), {
                                                ...inv, success: (x) => `Rıza kaydedildi: ${x.consent_count} / ${x.consent_required} (${x.owner_count} kat maliki)`,
                                            });
                                            if (r) { setOwner(""); setDocRef(""); }
                                        }}>Rızayı kaydet</Button>
                                    </div>
                                )}
                                <p className="mt-2 text-xs text-gray-500">Rıza, kat malikinin imzalı yazılı beyanı alındıktan sonra kaydedilir (KMK m.19/2: bütün kat maliklerinin beşte dördü, kişi sayısıyla).</p>
                            </Card>
                        )}

                        {canWrite && p.status === "PENDING" && (
                            <div className="space-y-2 rounded-lg bg-gray-50 p-3 dark:bg-gray-700/40">
                                <Grid>
                                    <Field label="Koşullar"><Input value={approve.conditions} onChange={(e) => setApprove({ ...approve, conditions: e.target.value })} placeholder="Asansör koruması, moloz taahhüdü…" /></Field>
                                    <Field label="Teminat (TL)"><Input type="number" min="0" step="0.01" value={approve.deposit} onChange={(e) => setApprove({ ...approve, deposit: e.target.value })} /></Field>
                                    {p.scope === "STRUCTURAL" && <Field label="Yapı ruhsatı / belediye izni no" required><Input value={approve.permit_ref} onChange={(e) => setApprove({ ...approve, permit_ref: e.target.value })} /></Field>}
                                    {(p.scope === "COMMON_AREA" || p.scope === "FACADE") && <Field label="Genel kurul gündem maddesi (rıza yerine, isteğe bağlı)"><Input value={approve.agenda_item_id} onChange={(e) => setApprove({ ...approve, agenda_item_id: e.target.value })} placeholder="Gündem maddesi kimliği" /></Field>}
                                </Grid>
                                <div className="flex flex-wrap gap-2">
                                    <Button disabled={act.pending} onClick={() => act.run(() => api.renovations.approve(p.id, {
                                        conditions: approve.conditions, deposit_amount: Number(approve.deposit || 0), permit_ref: approve.permit_ref, agenda_item_id: approve.agenda_item_id,
                                    }), { ...inv, success: (x) => `İzin onaylandı. Başvuran: ${x.notification.note} Komşular: ${x.neighbors.note}` })}>Onayla</Button>
                                    <Button variant="danger" onClick={() => setReason({ kind: "reject", text: "" })}>Reddet</Button>
                                </div>
                            </div>
                        )}
                        {canWrite && p.status === "APPROVED" && (
                            <div className="flex flex-wrap gap-2">
                                <Button onClick={() => setComplete({ refund: String(p.deposit_amount), note: "" })}>Denetle ve kapat</Button>
                                <Button variant="danger" onClick={() => setReason({ kind: "stop", text: "" })}>Çalışmayı durdur</Button>
                            </div>
                        )}
                        {p.status === "APPROVED" && <Badge tone="blue">Para cezası uygulanmaz; ihlalde çalışma durdurulur, hasar teminattan karşılanır (KMK m.19/3, m.33).</Badge>}

                        <FormModal open={!!reason} onClose={() => setReason(null)} title={reason?.kind === "stop" ? "Çalışmayı durdur" : "Başvuruyu reddet"} pending={act.pending} error={act.error}
                            onSubmit={async () => {
                                if (!reason) return;
                                const r = await act.run(() => (reason.kind === "stop" ? api.renovations.stop(p.id, reason.text) : api.renovations.reject(p.id, reason.text)), { ...inv, success: "Kaydedildi; başvurana bildirildi" });
                                if (r) setReason(null);
                            }}>
                            <Field label="Gerekçe" required><Textarea required value={reason?.text ?? ""} onChange={(e) => reason && setReason({ ...reason, text: e.target.value })} /></Field>
                        </FormModal>
                        <FormModal open={!!complete} onClose={() => setComplete(null)} title="Denetle ve kapat" pending={act.pending} error={act.error}
                            onSubmit={async () => {
                                if (!complete) return;
                                const r = await act.run(() => api.renovations.complete(p.id, { deposit_refunded: Number(complete.refund || 0), note: complete.note }), { ...inv, success: "İzin kapatıldı" });
                                if (r) setComplete(null);
                            }}>
                            {p.deposit_amount > 0 && <Field label={`İade edilecek teminat (en çok ${tl(p.deposit_amount)})`}><Input type="number" min="0" step="0.01" value={complete?.refund ?? ""} onChange={(e) => complete && setComplete({ ...complete, refund: e.target.value })} /></Field>}
                            <Field label="Denetim notu" hint="Teminattan kesinti yapılıyorsa hasar tespiti zorunludur"><Textarea value={complete?.note ?? ""} onChange={(e) => complete && setComplete({ ...complete, note: e.target.value })} /></Field>
                        </FormModal>
                    </div>
                )}
            </QueryView>
        </Modal>
    );
}
