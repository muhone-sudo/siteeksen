"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Notice, Page, QueryView, Select, Stats, Table, Textarea } from "@/components/ui/kit";
import { date, tl, today } from "@/lib/format";
import type { DaskRow, InsuranceClaim } from "@/lib/types";

const STATE: Record<string, [string, "green" | "amber" | "red" | "gray"]> = {
    VALID: ["Geçerli", "green"], EXPIRING: ["Bitiyor", "amber"], EXPIRED: ["Bitmiş", "red"], MISSING: ["Kayıt yok", "gray"],
};
const CLAIM: Record<string, string> = { REPORTED: "İhbar edildi", EXPERT_ASSIGNED: "Eksper atandı", PAID: "Ödendi", REJECTED: "Reddedildi", CLOSED: "Kapandı" };
const NEXT: Record<string, string[]> = { REPORTED: ["EXPERT_ASSIGNED", "PAID", "REJECTED"], EXPERT_ASSIGNED: ["PAID", "REJECTED"], PAID: ["CLOSED"], REJECTED: ["CLOSED"] };

/**
 * Sigorta (FAZ 7.2): bağımsız bölüm DASK takibi (yükümlülük malikindir — 6305 m.10/3) ve
 * ortak alan hasar/tazminat kaydı. Ortak alan poliçeleri Sözleşmeler'de (INSURANCE) izlenir.
 */
export default function InsurancePage() {
    const dask = useApi(["dask"], api.insurance.dask);
    const claims = useApi(["claims"], api.insurance.claims);
    const act = useAction();
    const { canWrite } = useRoles();
    const [policy, setPolicy] = useState<{ row: DaskRow; policy_no: string; insurer: string; start_date: string; end_date: string } | null>(null);
    const [claim, setClaim] = useState<{ occurred_on: string; description: string; claimed_amount: string; insurer_ref: string } | null>(null);
    const [move, setMove] = useState<{ c: InsuranceClaim; status: string; paid_amount: string; paid_on: string; note: string } | null>(null);
    const s = dask.data?.summary ?? {};

    return (
        <Page title="Sigorta" description="DASK takibi ve ortak alan hasar kayıtları (6305 s. Afet Sigortaları Kanunu).">
            <ActionFeedback action={act} />
            <Stats items={[
                { label: "Geçerli DASK", value: String(s.VALID ?? 0), tone: "blue" },
                { label: "30 gün içinde bitiyor", value: String(s.EXPIRING ?? 0), tone: "amber" },
                { label: "Bitmiş", value: String(s.EXPIRED ?? 0) },
                { label: "Kayıt yok", value: String(s.MISSING ?? 0) },
            ]} />
            <Card title="Bağımsız bölüm DASK poliçeleri" padded={false}>
                <QueryView q={dask} isEmpty={(d) => d.data.length === 0} empty="Bölüm yok">
                    {(d) => (
                        <>
                            <Table rows={d.data} rowKey={(r) => r.unit_id} columns={[
                                { header: "Daire", cell: (r) => <b>{r.unit}</b> },
                                { header: "Poliçe", cell: (r) => r.policy_no ? `${r.policy_no}${r.insurer ? ` · ${r.insurer}` : ""}` : "—" },
                                { header: "Bitiş", cell: (r) => (r.end_date ? date(r.end_date) : "—") },
                                { header: "Durum", cell: (r) => <Badge tone={STATE[r.state][1]}>{STATE[r.state][0]}</Badge> },
                                ...(canWrite ? [{ header: "", cell: (r: DaskRow) => <Button size="sm" variant="ghost" onClick={() => setPolicy({ row: r, policy_no: "", insurer: "", start_date: today(), end_date: "" })}>Poliçe gir</Button> }] : []),
                            ]} />
                            <p className="px-4 py-3 text-xs text-gray-500">{d.note} Bitişine 30 gün kalan ve bitmiş poliçeler için malike hatırlatma gider; kaydı olmayan bölüme gönderilmez (kayıt yokluğu sigorta yokluğu değildir).</p>
                        </>
                    )}
                </QueryView>
            </Card>
            <Card title="Hasar / tazminat kayıtları" actions={canWrite && <Button size="sm" variant="secondary" onClick={() => setClaim({ occurred_on: today(), description: "", claimed_amount: "", insurer_ref: "" })}>Hasar kaydet</Button>} padded={false}>
                <QueryView q={claims} empty="Hasar kaydı yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(x) => x.id} columns={[
                            { header: "Olay", cell: (x) => date(x.occurred_on) },
                            { header: "Açıklama", cell: (x) => x.description },
                            { header: "Talep", cell: (x) => (x.claimed_amount != null ? tl(x.claimed_amount) : "—") },
                            { header: "Durum", cell: (x) => CLAIM[x.status] ?? x.status },
                            { header: "Ödenen", cell: (x) => (x.paid_amount != null ? `${tl(x.paid_amount)} · ${date(x.paid_on)}` : "—") },
                            ...(canWrite ? [{ header: "", cell: (x: InsuranceClaim) => (NEXT[x.status] ? <Button size="sm" variant="ghost" onClick={() => setMove({ c: x, status: NEXT[x.status][0], paid_amount: "", paid_on: today(), note: "" })}>İlerlet</Button> : null) }] : []),
                        ]} />
                    )}
                </QueryView>
            </Card>

            <FormModal open={!!policy} onClose={() => setPolicy(null)} title={`DASK poliçesi — ${policy?.row.unit ?? ""}`} pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!policy) return;
                    const r = await act.run(() => api.insurance.addDask({ unit_id: policy.row.unit_id, policy_no: policy.policy_no, insurer: policy.insurer, start_date: policy.start_date, end_date: policy.end_date }), { invalidate: ["dask"], success: "Poliçe kaydedildi" });
                    if (r) setPolicy(null);
                }}>
                {policy && (<Grid>
                    <Field label="Poliçe no" required><Input required value={policy.policy_no} onChange={(e) => setPolicy({ ...policy, policy_no: e.target.value })} /></Field>
                    <Field label="Sigorta şirketi"><Input value={policy.insurer} onChange={(e) => setPolicy({ ...policy, insurer: e.target.value })} /></Field>
                    <Field label="Başlangıç" required><Input type="date" required value={policy.start_date} onChange={(e) => setPolicy({ ...policy, start_date: e.target.value })} /></Field>
                    <Field label="Bitiş" required><Input type="date" required value={policy.end_date} onChange={(e) => setPolicy({ ...policy, end_date: e.target.value })} /></Field>
                </Grid>)}
            </FormModal>
            <FormModal open={!!claim} onClose={() => setClaim(null)} title="Hasar kaydı" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!claim) return;
                    const r = await act.run(() => api.insurance.createClaim({ occurred_on: claim.occurred_on, description: claim.description, claimed_amount: claim.claimed_amount ? Number(claim.claimed_amount) : undefined, insurer_ref: claim.insurer_ref }), { invalidate: ["claims"], success: "Hasar kaydedildi" });
                    if (r) setClaim(null);
                }}>
                {claim && (<>
                    <Grid>
                        <Field label="Olay tarihi" required><Input type="date" required value={claim.occurred_on} onChange={(e) => setClaim({ ...claim, occurred_on: e.target.value })} /></Field>
                        <Field label="Talep edilen (TL)"><Input type="number" min="0" step="0.01" value={claim.claimed_amount} onChange={(e) => setClaim({ ...claim, claimed_amount: e.target.value })} /></Field>
                        <Field label="Sigortacı dosya no"><Input value={claim.insurer_ref} onChange={(e) => setClaim({ ...claim, insurer_ref: e.target.value })} /></Field>
                    </Grid>
                    <Field label="Açıklama" required><Textarea required value={claim.description} onChange={(e) => setClaim({ ...claim, description: e.target.value })} /></Field>
                </>)}
            </FormModal>
            <FormModal open={!!move} onClose={() => setMove(null)} title="Hasar durumunu ilerlet" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!move) return;
                    const r = await act.run(() => api.insurance.claimStatus(move.c.id, { status: move.status, paid_amount: move.paid_amount ? Number(move.paid_amount) : undefined, paid_on: move.status === "PAID" ? move.paid_on : undefined, note: move.note }), { invalidate: ["claims"], success: "Güncellendi" });
                    if (r) setMove(null);
                }}>
                {move && (<>
                    <Field label="Yeni durum"><Select value={move.status} onChange={(e) => setMove({ ...move, status: e.target.value })} options={(NEXT[move.c.status] ?? []).map((v) => ({ value: v, label: CLAIM[v] }))} /></Field>
                    {move.status === "PAID" && (<Grid>
                        <Field label="Ödenen tazminat (TL)" required><Input type="number" min="0" step="0.01" required value={move.paid_amount} onChange={(e) => setMove({ ...move, paid_amount: e.target.value })} /></Field>
                        <Field label="Ödeme tarihi" required><Input type="date" required value={move.paid_on} onChange={(e) => setMove({ ...move, paid_on: e.target.value })} /></Field>
                    </Grid>)}
                    <Field label="Not" required={move.status === "REJECTED"}><Textarea value={move.note} onChange={(e) => setMove({ ...move, note: e.target.value })} /></Field>
                    {move.status === "REJECTED" && <Notice tone="amber">Sigortacının ret gerekçesini yazın.</Notice>}
                </>)}
            </FormModal>
        </Page>
    );
}
