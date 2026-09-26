"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Page, QueryView, Select, StatusBadge, Table, Tabs, Textarea } from "@/components/ui/kit";
import { dateTime, tl } from "@/lib/format";
import { opts, RESERVATION_STATUS } from "@/lib/labels";
import type { Reservation } from "@/lib/types";

export default function ReservationsPage() {
    const [tab, setTab] = useState<"list" | "facilities">("list");
    const [status, setStatus] = useState("PENDING");
    const [facility, setFacility] = useState("");
    const list = useApi(["reservations", status, facility], () => api.reservations.list({ status, facility_id: facility }));
    const facilities = useApi(["facilities"], api.reservations.facilities);
    const act = useAction();
    const { canWrite } = useRoles();
    const [rejecting, setRejecting] = useState<Reservation | null>(null);
    const [cancelling, setCancelling] = useState<Reservation | null>(null);
    const [reason, setReason] = useState("");

    return (
        <Page title="Rezervasyon" description="Ortak alan rezervasyonları. Çakışma, kapasite ve haftalık kota sunucuda denetlenir; rezervasyonu sakin mobil uygulamadan yapar.">
            <ActionFeedback action={act} />
            <Tabs tabs={[{ id: "list", label: "Rezervasyonlar" }, { id: "facilities", label: "Tesisler" }]} value={tab} onChange={setTab} />
            {tab === "list" && (
                <Card padded={false} title="Rezervasyonlar" actions={
                    <div className="flex gap-2">
                        <Select value={status} onChange={(e) => setStatus(e.target.value)} options={opts(RESERVATION_STATUS)} placeholder="Tüm durumlar" />
                        <Select value={facility} onChange={(e) => setFacility(e.target.value)} options={(facilities.data?.data ?? []).map((f) => ({ value: f.id, label: f.name }))} placeholder="Tüm tesisler" />
                    </div>
                }>
                    <QueryView q={list} empty="Rezervasyon yok">
                        {(d) => (
                            <Table rows={d.data} rowKey={(r) => r.id} columns={[
                                { header: "Tesis", cell: (r) => r.facility_name ?? "—" },
                                { header: "Sakin", cell: (r) => <div><p>{r.resident_name ?? "—"}</p><p className="text-xs text-gray-500">{r.unit_name}</p></div> },
                                { header: "Zaman", cell: (r) => `${dateTime(r.start_time)} – ${new Date(r.end_time).toLocaleTimeString("tr-TR", { hour: "2-digit", minute: "2-digit" })}` },
                                { header: "Kişi", cell: (r) => r.guest_count },
                                { header: "Ücret", cell: (r) => (r.total_fee > 0 ? tl(r.total_fee) : "—") },
                                { header: "Durum", cell: (r) => <StatusBadge value={r.status} map={RESERVATION_STATUS} /> },
                                { header: "", cell: (r) => canWrite ? (
                                    <div className="flex gap-1">
                                        {r.status === "PENDING" && (
                                            <>
                                                <Button size="sm" disabled={act.pending} onClick={() => act.run(() => api.reservations.approve(r.id), { invalidate: ["reservations"], success: "Rezervasyon onaylandı; sakine bildirim düştü" })}>Onayla</Button>
                                                <Button size="sm" variant="danger" onClick={() => { setReason(""); setRejecting(r); }}>Reddet</Button>
                                            </>
                                        )}
                                        {(r.status === "PENDING" || r.status === "APPROVED") && <Button size="sm" variant="ghost" onClick={() => { setReason(""); setCancelling(r); }}>İptal</Button>}
                                    </div>
                                ) : null },
                            ]} />
                        )}
                    </QueryView>
                </Card>
            )}
            {tab === "facilities" && (
                <Card padded={false} title="Tesisler">
                    <QueryView q={facilities} empty="Tesis tanımlı değil">
                        {(d) => (
                            <Table rows={d.data} rowKey={(f) => f.id} columns={[
                                { header: "Tesis", cell: (f) => f.name },
                                { header: "Saat", cell: (f) => `${f.available_from} – ${f.available_to}` },
                                { header: "Kapasite", cell: (f) => f.capacity ?? "—" },
                                { header: "Ücret", cell: (f) => (f.is_paid ? `${tl(f.hourly_fee)}/sa` : "Ücretsiz") },
                                { header: "Onay", cell: (f) => (f.requires_approval ? <Badge tone="amber">Onaylı</Badge> : <Badge tone="green">Otomatik</Badge>) },
                                { header: "Durum", cell: (f) => (f.maintenance_mode ? <Badge tone="red">Bakımda</Badge> : f.is_active ? <Badge tone="green">Açık</Badge> : <Badge>Kapalı</Badge>) },
                            ]} />
                        )}
                    </QueryView>
                </Card>
            )}

            <FormModal open={!!rejecting} onClose={() => setRejecting(null)} title="Rezervasyonu reddet" submitLabel="Reddet" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!rejecting) return;
                    const r = await act.run(() => api.reservations.reject(rejecting.id, reason), { invalidate: ["reservations"], success: "Reddedildi; sakine gerekçeyle bildirim düştü" });
                    if (r) setRejecting(null);
                }}>
                <Field label="Gerekçe" required><Textarea required value={reason} onChange={(e) => setReason(e.target.value)} /></Field>
            </FormModal>
            <FormModal open={!!cancelling} onClose={() => setCancelling(null)} title="Rezervasyonu iptal et" submitLabel="İptal et" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!cancelling) return;
                    const r = await act.run(() => api.reservations.cancel(cancelling.id, reason), { invalidate: ["reservations"], success: "Rezervasyon iptal edildi" });
                    if (r) setCancelling(null);
                }}>
                <Field label="Gerekçe"><Textarea value={reason} onChange={(e) => setReason(e.target.value)} /></Field>
            </FormModal>
        </Page>
    );
}
