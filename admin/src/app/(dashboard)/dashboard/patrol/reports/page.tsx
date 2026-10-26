"use client";

import { useState } from "react";
import dynamic from "next/dynamic";
import Link from "next/link";
import { api } from "@/lib/api";
import { useApi } from "@/lib/use-api";
import { Badge, Button, Card, Field, Grid, Input, Modal, Notice, Page, QueryView, Stats, StatusBadge, Table } from "@/components/ui/kit";
import { dateTime, num } from "@/lib/format";
import { PATROL_STATUS } from "@/lib/labels";

const PatrolMap = dynamic(() => import("@/components/patrol/patrol-map"), { ssr: false, loading: () => <p className="p-4 text-sm text-gray-500">Harita yükleniyor…</p> });

const iso = (d: Date) => d.toISOString().slice(0, 10);

/**
 * Devriye raporları (075, FAZ H.5): dönem özeti, turlar ve tur ayrıntısı (harita, okutma denemeleri,
 * reddedilen okutmalar ve nedenleri, şüpheli hızlar, konum muaf okutmalar, takip kesintileri).
 */
export default function PatrolReportsPage() {
    const [range, setRange] = useState({ from: iso(new Date(Date.now() - 30 * 86400000)), to: iso(new Date()) });
    const [applied, setApplied] = useState(range);
    const [open, setOpen] = useState<string | null>(null);
    const list = useApi(["patrol", "reports", applied], () => api.patrol.reports(applied));
    const detail = useApi(["patrol", "report", open], () => api.patrol.report(open!), !!open);
    const s = list.data?.summary;
    return (
        <Page title="Devriye raporları" description="Turlar, okutma kanıtları ve konum izi"
            actions={<Link href="/dashboard/patrol" className="inline-flex items-center rounded-lg border border-gray-300 px-3 py-2 text-sm hover:bg-gray-50 dark:border-gray-600 dark:hover:bg-gray-700">Devriye</Link>}>
            <Card title="Dönem">
                <form className="flex flex-wrap items-end gap-3" onSubmit={(e) => { e.preventDefault(); setApplied(range); }}>
                    <Field label="Başlangıç"><Input type="date" value={range.from} onChange={(e) => setRange({ ...range, from: e.target.value })} /></Field>
                    <Field label="Bitiş"><Input type="date" value={range.to} onChange={(e) => setRange({ ...range, to: e.target.value })} /></Field>
                    <Button type="submit">Uygula</Button>
                </form>
            </Card>
            <Stats items={[
                { label: "Tur", value: num(s?.total) },
                { label: "Tamamlanan", value: num(s?.completed), tone: "green" },
                { label: "Eksik", value: num(s?.incomplete), tone: "red" },
                { label: "Reddedilen okutma", value: num(s?.rejected_attempts), tone: "red", hint: "Uzaktan, sahte konumla ya da tanınmayan QR ile deneme" },
                { label: "Şüpheli okutma", value: num(s?.suspicious_scans), tone: "amber", hint: "İki nokta arası fiziksel olarak imkânsız hız" },
                { label: "Ort. süre", value: `${num(s?.avg_duration_minutes)} dk` },
            ]} />
            {s?.top_rejections && s.top_rejections.length > 0 && (
                <Card title="En çok reddedilen okutmalar">
                    <ul className="space-y-1 text-sm">
                        {s.top_rejections.map((t, i) => <li key={i}><b>{t.checkpoint}</b>: {t.reason_text || t.reason} — {t.count} kez</li>)}
                    </ul>
                </Card>
            )}
            <Card padded={false}>
                <QueryView q={list} empty="Bu dönemde tur yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(p) => p.id} columns={[
                            { header: "Başlangıç", cell: (p) => dateTime(p.started_at) },
                            { header: "Tur", cell: (p) => p.route_name || "—" },
                            { header: "Görevli", cell: (p) => p.guard_name || "—" },
                            { header: "Nokta", cell: (p) => `${p.checkpoints_visited}/${p.checkpoints_expected}` },
                            { header: "Süre", cell: (p) => (p.actual_duration_minutes != null ? `${p.actual_duration_minutes} dk` : "—") },
                            { header: "Kanıt", cell: (p) => (
                                <span className="flex flex-wrap gap-1">
                                    {p.rejected_attempts > 0 && <Badge tone="red">{p.rejected_attempts} red</Badge>}
                                    {p.suspicious_scans > 0 && <Badge tone="amber">{p.suspicious_scans} şüpheli</Badge>}
                                    {p.exempt_scans > 0 && <Badge>{p.exempt_scans} muaf</Badge>}
                                    {p.track_points === 0 && <Badge tone="amber">iz yok</Badge>}
                                </span>
                            ) },
                            { header: "Durum", cell: (p) => <StatusBadge value={p.status} map={PATROL_STATUS} /> },
                            { header: "", cell: (p) => <Button size="sm" variant="ghost" onClick={() => setOpen(p.id)}>Ayrıntı</Button> },
                        ]} />
                    )}
                </QueryView>
            </Card>
            <Modal open={!!open} onClose={() => setOpen(null)} title="Tur raporu">
                <QueryView q={detail} empty="Rapor yok">
                    {(r) => (
                        <div className="space-y-3 text-sm">
                            <p><b>{r.patrol.route_name}</b> · {r.patrol.guard_name} · {dateTime(r.patrol.started_at)} → {r.patrol.completed_at ? dateTime(r.patrol.completed_at) : "devam ediyor"}
                                {" "}· nokta {r.patrol.checkpoints_visited ?? 0}/{r.patrol.checkpoints_expected ?? 0}</p>
                            <Grid cols={3}>
                                <span>Red: <b>{r.stats.rejected_attempts}</b></span>
                                <span>Şüpheli: <b>{r.stats.suspicious_scans}</b></span>
                                <span>Konum muaf: <b>{r.stats.exempt_scans}</b></span>
                                <span>İz noktası: <b>{r.stats.track_points}</b>{r.stats.mocked_track_points > 0 ? ` (${r.stats.mocked_track_points} sahte)` : ""}</span>
                                <span>Yürünen: <b>{r.stats.track_distance_m} m</b></span>
                                <span>Kesinti: <b>{r.stats.track_gaps}</b></span>
                            </Grid>
                            <PatrolMap report={r} />
                            {r.gaps.length > 0 && <Notice tone="amber">Takip kesintileri: {r.gaps.map((g) => `${dateTime(g.from)}–${dateTime(g.to)} (${g.minutes} dk)`).join(", ")}</Notice>}
                            <Table rows={r.attempts} rowKey={(a) => a.at + a.checkpoint + a.reason} columns={[
                                { header: "Zaman", cell: (a) => dateTime(a.at) },
                                { header: "Nokta", cell: (a) => a.checkpoint || "Tanınmayan QR" },
                                { header: "Yöntem", cell: (a) => (a.method === "QR" ? "QR" : "Listeden") },
                                { header: "Sonuç", cell: (a) => (a.accepted ? <Badge tone={a.suspicious ? "amber" : "green"}>{a.suspicious ? "Şüpheli" : "Kabul"}</Badge> : <Badge tone="red">{a.reason_text || a.reason}</Badge>) },
                                { header: "Uzaklık / doğruluk", cell: (a) => [a.distance_m != null ? `${Math.round(a.distance_m)} m` : null, a.accuracy_m != null ? `±${Math.round(a.accuracy_m)} m` : null].filter(Boolean).join(" · ") || (a.location_exempt ? "konum muaf" : "—") },
                                { header: "", cell: (a) => (a.is_mocked ? <Badge tone="red">sahte konum</Badge> : null) },
                            ]} />
                            {r.issues && r.issues.length > 0 && (
                                <Card title="Bildirilen sorunlar">
                                    <ul className="list-inside list-disc">{r.issues.map((i, k) => <li key={k}>{i.severity}: {i.description}</li>)}</ul>
                                </Card>
                            )}
                        </div>
                    )}
                </QueryView>
            </Modal>
        </Page>
    );
}
