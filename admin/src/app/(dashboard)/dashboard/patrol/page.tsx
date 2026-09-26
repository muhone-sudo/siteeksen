"use client";

import { useState } from "react";
import { Plus } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Notice, Page, QueryView, Select, Stats, StatusBadge, Table, Tabs } from "@/components/ui/kit";
import { dateTime, num } from "@/lib/format";
import { opts, PATROL_STATUS } from "@/lib/labels";

/**
 * Devriye (güvenlik turu). Turu görevli mobil uygulamadan, noktaları NFC/QR
 * ile okutarak yürütür; bu ekran yönetim içindir: tur ve nokta tanımı,
 * eksik ya da şüpheli hızlı turların izlenmesi.
 */
export default function PatrolPage() {
    const [tab, setTab] = useState<"patrols" | "routes" | "checkpoints">("patrols");
    const [status, setStatus] = useState("");
    const summary = useApi(["patrol", "summary"], api.patrol.summary);
    const patrols = useApi(["patrol", "list", status], () => api.patrol.list({ status }));
    const routes = useApi(["patrol", "routes"], api.patrol.routes);
    const checkpoints = useApi(["patrol", "checkpoints"], api.patrol.checkpoints);
    const act = useAction();
    const { canWrite } = useRoles();
    const [cpForm, setCpForm] = useState<null | Record<string, string>>(null);
    const [routeForm, setRouteForm] = useState<null | { name: string; expected_duration_minutes: string; tolerance_minutes: string; checkpoints: string[] }>(null);
    const s = summary.data?.summary;

    return (
        <Page title="Devriye" description="Güvenlik turları, kontrol noktaları ve tur kalitesi."
            actions={canWrite && (
                <>
                    <Button variant="secondary" onClick={() => setCpForm({ name: "", location: "", building: "", floor: "", nfc_tag_id: "", qr_code: "" })}><Plus className="h-4 w-4" /> Kontrol noktası</Button>
                    <Button onClick={() => setRouteForm({ name: "", expected_duration_minutes: "30", tolerance_minutes: "10", checkpoints: [] })}><Plus className="h-4 w-4" /> Tur tanımla</Button>
                </>
            )}>
            <ActionFeedback action={act} />
            {summary.data?.warning && <Notice tone="amber">{summary.data.warning}</Notice>}
            <Stats items={[
                { label: "Son 7 gün tur", value: num(s?.patrols_last_7_days) },
                { label: "Eksik tamamlanan", value: num(s?.incomplete), tone: "red" },
                { label: "Şüpheli hızlı", value: num(s?.suspiciously_fast), tone: "amber", hint: "Beklenen süreden belirgin kısa" },
                { label: "Bildirilen sorun", value: num(s?.issues_reported), tone: "purple" },
            ]} />
            <Tabs tabs={[{ id: "patrols", label: "Turlar" }, { id: "routes", label: "Tur tanımları" }, { id: "checkpoints", label: "Kontrol noktaları" }]} value={tab} onChange={setTab} />
            <Card padded={false}>
                {tab === "patrols" && (
                    <>
                        <div className="p-4"><Select value={status} onChange={(e) => setStatus(e.target.value)} options={opts(PATROL_STATUS)} placeholder="Tüm durumlar" className="max-w-xs" /></div>
                        <QueryView q={patrols} empty="Tur kaydı yok">
                            {(d) => (
                                <Table rows={d.data} rowKey={(p) => p.id} columns={[
                                    { header: "Başlangıç", cell: (p) => dateTime(p.started_at) },
                                    { header: "Tur", cell: (p) => p.route_name ?? "—" },
                                    { header: "Görevli", cell: (p) => p.guard_name ?? "—" },
                                    { header: "Nokta", cell: (p) => `${p.checkpoints_visited}/${p.checkpoints_expected}` },
                                    { header: "Süre", cell: (p) => (p.actual_duration_minutes !== undefined ? `${p.actual_duration_minutes} dk` : "—") },
                                    { header: "Sorun", cell: (p) => (p.issues_reported > 0 ? <Badge tone="red">{p.issues_reported}</Badge> : "—") },
                                    { header: "Durum", cell: (p) => <div className="flex gap-1"><StatusBadge value={p.status} map={PATROL_STATUS} />{p.too_fast && <Badge tone="amber">Hızlı</Badge>}</div> },
                                ]} />
                            )}
                        </QueryView>
                    </>
                )}
                {tab === "routes" && (
                    <QueryView q={routes} empty="Tur tanımı yok">
                        {(d) => (
                            <Table rows={d.data} rowKey={(r) => r.id} columns={[
                                { header: "Tur", cell: (r) => r.name },
                                { header: "Noktalar", cell: (r) => r.checkpoints.map((c) => c.name ?? c.checkpoint_id).join(" → ") },
                                { header: "Beklenen", cell: (r) => `${r.expected_duration_minutes} dk (±${r.tolerance_minutes})` },
                                { header: "Durum", cell: (r) => (r.is_active ? <Badge tone="green">Aktif</Badge> : <Badge>Pasif</Badge>) },
                            ]} />
                        )}
                    </QueryView>
                )}
                {tab === "checkpoints" && (
                    <QueryView q={checkpoints} empty="Kontrol noktası yok">
                        {(d) => (
                            <Table rows={d.data} rowKey={(c) => c.id} columns={[
                                { header: "Nokta", cell: (c) => c.name },
                                { header: "Konum", cell: (c) => [c.building, c.floor, c.location].filter(Boolean).join(" · ") || "—" },
                                { header: "NFC / QR", cell: (c) => <span className="font-mono text-xs">{[c.nfc_tag_id, c.qr_code].filter(Boolean).join(" · ") || "—"}</span> },
                            ]} />
                        )}
                    </QueryView>
                )}
            </Card>

            <FormModal open={!!cpForm} onClose={() => setCpForm(null)} title="Kontrol noktası" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!cpForm) return;
                    const r = await act.run(() => api.patrol.createCheckpoint(cpForm), { invalidate: ["patrol"], success: "Kontrol noktası eklendi" });
                    if (r) setCpForm(null);
                }}>
                {cpForm && (
                    <Grid>
                        {[["name", "Ad", true], ["location", "Konum"], ["building", "Blok"], ["floor", "Kat"], ["nfc_tag_id", "NFC etiket kimliği"], ["qr_code", "QR kodu"]].map(([k, l, req]) => (
                            <Field key={k as string} label={l as string} required={!!req}>
                                <Input required={!!req} value={cpForm[k as string]} onChange={(e) => setCpForm({ ...cpForm, [k as string]: e.target.value })} />
                            </Field>
                        ))}
                    </Grid>
                )}
            </FormModal>
            <FormModal open={!!routeForm} onClose={() => setRouteForm(null)} title="Tur tanımla" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!routeForm) return;
                    const r = await act.run(() => api.patrol.createRoute({
                        name: routeForm.name,
                        expected_duration_minutes: Number(routeForm.expected_duration_minutes),
                        tolerance_minutes: Number(routeForm.tolerance_minutes),
                        checkpoints: routeForm.checkpoints.map((id, i) => ({ checkpoint_id: id, order: i + 1, optional: false })),
                    }), { invalidate: ["patrol"], success: "Tur tanımlandı" });
                    if (r) setRouteForm(null);
                }}>
                {routeForm && (
                    <>
                        <Grid cols={3}>
                            <Field label="Ad" required><Input required value={routeForm.name} onChange={(e) => setRouteForm({ ...routeForm, name: e.target.value })} /></Field>
                            <Field label="Beklenen süre (dk)"><Input type="number" value={routeForm.expected_duration_minutes} onChange={(e) => setRouteForm({ ...routeForm, expected_duration_minutes: e.target.value })} /></Field>
                            <Field label="Tolerans (dk)"><Input type="number" value={routeForm.tolerance_minutes} onChange={(e) => setRouteForm({ ...routeForm, tolerance_minutes: e.target.value })} /></Field>
                        </Grid>
                        <Field label="Noktalar (sırasıyla)" hint="Seçim sırası tur sırasıdır.">
                            <div className="space-y-1">
                                {(checkpoints.data?.data ?? []).map((c) => {
                                    const idx = routeForm.checkpoints.indexOf(c.id);
                                    return (
                                        <label key={c.id} className="flex items-center gap-2 text-sm">
                                            <input type="checkbox" checked={idx >= 0}
                                                onChange={(e) => setRouteForm({ ...routeForm, checkpoints: e.target.checked ? [...routeForm.checkpoints, c.id] : routeForm.checkpoints.filter((x) => x !== c.id) })} />
                                            {idx >= 0 && <Badge tone="blue">{idx + 1}</Badge>} {c.name}
                                        </label>
                                    );
                                })}
                            </div>
                        </Field>
                    </>
                )}
            </FormModal>
        </Page>
    );
}
