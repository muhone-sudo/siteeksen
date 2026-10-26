"use client";

import { useState } from "react";
import { Plus } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import Link from "next/link";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Notice, Page, QueryView, Select, Stats, StatusBadge, Table, Tabs, Textarea } from "@/components/ui/kit";
import { printQr } from "@/lib/qr-print";
import type { Checkpoint } from "@/lib/types";
import { dateTime, num } from "@/lib/format";
import { opts, PATROL_STATUS } from "@/lib/labels";

/**
 * Devriye (güvenlik turu). Turu görevli yönetici uygulamasından yürütür; noktaları QR ile okuturken
 * konumu noktanın konumuyla karşılaştırılır (075). Bu ekran yönetim içindir: tur ve nokta tanımı,
 * nokta konumu/yarıçapı/muafiyeti, QR yazdırma, eksik ya da şüpheli turların izlenmesi.
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
    const [gpsForm, setGpsForm] = useState<null | { id: string; name: string; latitude: string; longitude: string; radius_m: string; location_check: string; exempt_reason: string }>(null);
    const s = summary.data?.summary;

    return (
        <Page title="Devriye" description="Güvenlik turları, kontrol noktaları ve tur kalitesi."
            actions={canWrite && (
                <>
                    <Link href="/dashboard/patrol/reports" className="inline-flex items-center rounded-lg border border-gray-300 px-3 py-2 text-sm hover:bg-gray-50 dark:border-gray-600 dark:hover:bg-gray-700">Raporlar ve harita</Link>
                    {(checkpoints.data?.data ?? []).some((c) => c.qr_value) && <Button variant="secondary" onClick={() => void printQr(checkpoints.data?.data ?? [])}>Tüm QR&apos;ları yazdır</Button>}
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
                                { header: "GPS", cell: (c) => (c.location_check === "EXEMPT"
                                    ? <Badge tone="amber">Konum muaf</Badge>
                                    : c.latitude != null ? <span className="text-xs">{c.latitude.toFixed(5)}, {c.longitude?.toFixed(5)} · {c.radius_m} m</span> : <Badge tone="red">Konum yok</Badge>) },
                                ...(canWrite ? [{ header: "", cell: (c: Checkpoint) => (
                                    <span className="flex flex-wrap gap-1">
                                        <Button size="sm" variant="ghost" onClick={() => setGpsForm({ id: c.id, name: c.name, latitude: c.latitude?.toString() ?? "", longitude: c.longitude?.toString() ?? "",
                                            radius_m: String(c.radius_m ?? 30), location_check: c.location_check ?? "REQUIRED", exempt_reason: c.exempt_reason ?? "" })}>Konum / yarıçap</Button>
                                        {c.qr_value && <Button size="sm" variant="ghost" onClick={() => void printQr([c])}>QR yazdır</Button>}
                                        <Button size="sm" variant="ghost" disabled={act.pending} onClick={async () => {
                                            if (!window.confirm("Eski QR baskısı hemen geçersiz olur. Yenilensin mi?")) return;
                                            const r = await act.run(() => api.patrol.rotateQr(c.id), { invalidate: ["patrol"], success: "QR yenilendi; yenisini yazdırıp asın" });
                                            if (r) void printQr([{ ...c, qr_value: r.qr_value }]);
                                        }}>QR yenile</Button>
                                    </span>
                                ) }] : []),
                            ]} />
                        )}
                    </QueryView>
                )}
            </Card>

            <FormModal open={!!gpsForm} onClose={() => setGpsForm(null)} title={gpsForm ? `${gpsForm.name} — konum doğrulaması` : ""} pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!gpsForm) return;
                    const body: { radius_m: number; location_check: string; exempt_reason?: string; latitude?: number; longitude?: number } = {
                        radius_m: Number(gpsForm.radius_m), location_check: gpsForm.location_check,
                        ...(gpsForm.location_check === "EXEMPT" ? { exempt_reason: gpsForm.exempt_reason } : {}),
                        ...(gpsForm.latitude.trim() && gpsForm.longitude.trim() ? { latitude: Number(gpsForm.latitude), longitude: Number(gpsForm.longitude) } : {}),
                    };
                    const r = await act.run(() => api.patrol.updateCheckpoint(gpsForm.id, body), { invalidate: ["patrol"], success: "Nokta güncellendi" });
                    if (r) setGpsForm(null);
                }}>
                {gpsForm && (
                    <>
                        <Notice tone="blue">En doğru yöntem: yönetici uygulamasında Devriye → Nokta kurulumu → &quot;Konumu buradan al&quot; (noktanın yanında, ≤20 m hassasiyet). Buradan elle girilen koordinat da kabul edilir.</Notice>
                        <Grid cols={3}>
                            <Field label="Enlem"><Input value={gpsForm.latitude} onChange={(e) => setGpsForm({ ...gpsForm, latitude: e.target.value })} placeholder="41.01234" /></Field>
                            <Field label="Boylam"><Input value={gpsForm.longitude} onChange={(e) => setGpsForm({ ...gpsForm, longitude: e.target.value })} placeholder="29.01234" /></Field>
                            <Field label="Yarıçap (m)" required hint="5-500; okutmada izin verilen uzaklık + ölçüm hatası"><Input type="number" min={5} max={500} required value={gpsForm.radius_m} onChange={(e) => setGpsForm({ ...gpsForm, radius_m: e.target.value })} /></Field>
                        </Grid>
                        <Field label="Konum denetimi">
                            <Select value={gpsForm.location_check} onChange={(e) => setGpsForm({ ...gpsForm, location_check: e.target.value })}
                                options={[{ value: "REQUIRED", label: "Zorunlu (önerilen)" }, { value: "EXEMPT", label: "Muaf — GPS çekmeyen kapalı alan" }]} />
                        </Field>
                        {gpsForm.location_check === "EXEMPT" && (
                            <Field label="Muafiyet gerekçesi" required hint="Muaf noktada okutma yalnız QR ile yapılır ve raporda ayrıca işaretlenir.">
                                <Textarea required value={gpsForm.exempt_reason} onChange={(e) => setGpsForm({ ...gpsForm, exempt_reason: e.target.value })} />
                            </Field>
                        )}
                    </>
                )}
            </FormModal>
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
