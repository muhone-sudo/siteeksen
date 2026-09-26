"use client";

import { useState } from "react";
import { LogIn, Plus } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Page, QueryView, Select, Stats, Table, Tabs } from "@/components/ui/kit";
import { dateTime, num, tl } from "@/lib/format";

const OWNER_TYPES = [
    { value: "RESIDENT", label: "Sakin" },
    { value: "VISITOR", label: "Ziyaretçi" },
    { value: "STAFF", label: "Personel" },
    { value: "SERVICE", label: "Servis" },
];
const VEHICLE_TYPES = [
    { value: "CAR", label: "Otomobil" },
    { value: "MOTORCYCLE", label: "Motosiklet" },
    { value: "TRUCK", label: "Kamyonet" },
];

export default function ParkingPage() {
    const [tab, setTab] = useState<"inside" | "vehicles" | "zones">("inside");
    const inside = useApi(["parking", "inside"], () => api.parking.logs(true));
    const vehicles = useApi(["parking", "vehicles"], api.parking.vehicles, tab === "vehicles");
    const zones = useApi(["parking", "zones"], api.parking.zones);
    const units = useApi(["units"], api.identity.units);
    const act = useAction();
    const [entry, setEntry] = useState<null | { plate: string; parking_zone_id: string; entry_gate: string }>(null);
    const [vehicle, setVehicle] = useState<null | Record<string, string>>(null);

    const zoneOptions = (zones.data?.data ?? []).map((z) => ({ value: z.id, label: `${z.name} (${z.available_spots}/${z.capacity} boş)` }));
    const totalCap = (zones.data?.data ?? []).reduce((a, z) => a + z.capacity, 0);
    const occupied = (zones.data?.data ?? []).reduce((a, z) => a + z.occupied_count, 0);

    return (
        <Page title="Otopark" description="Araç kaydı, giriş/çıkış ve bölge doluluğu. Doluluk açık giriş kayıtlarından hesaplanır."
            actions={
                <>
                    <Button variant="secondary" onClick={() => setVehicle({ plate: "", unit_id: "", owner_type: "RESIDENT", owner_name: "", vehicle_type: "CAR", brand: "", model: "", color: "", parking_spot: "" })}>
                        <Plus className="h-4 w-4" /> Araç kaydet
                    </Button>
                    <Button onClick={() => setEntry({ plate: "", parking_zone_id: "", entry_gate: "" })}><LogIn className="h-4 w-4" /> Giriş kaydı</Button>
                </>
            }>
            <ActionFeedback action={act} />
            <Stats items={[
                { label: "Şu an içeride", value: num(inside.data?.data.length), tone: "blue" },
                { label: "Toplam kapasite", value: num(totalCap) },
                { label: "Dolu", value: num(occupied), tone: "amber" },
                { label: "Bölge", value: num(zones.data?.data.length) },
            ]} />
            <Tabs tabs={[{ id: "inside", label: "İçeridekiler" }, { id: "vehicles", label: "Kayıtlı araçlar" }, { id: "zones", label: "Bölgeler" }]} value={tab} onChange={setTab} />
            <Card padded={false}>
                {tab === "inside" && (
                    <QueryView q={inside} empty="İçeride araç yok">
                        {(d) => (
                            <Table rows={d.data} rowKey={(l) => l.id} columns={[
                                { header: "Plaka", cell: (l) => <span className="font-mono font-bold">{l.plate}</span> },
                                { header: "Bölge", cell: (l) => l.zone_name ?? "—" },
                                { header: "Giriş", cell: (l) => dateTime(l.entry_at) },
                                { header: "Tür", cell: (l) => (l.is_resident ? <Badge tone="green">Kayıtlı (ücretsiz)</Badge> : <Badge tone="amber">Misafir</Badge>) },
                                { header: "", cell: (l) => (
                                    <Button size="sm" disabled={act.pending} onClick={() => act.run(() => api.parking.exit(l.id), {
                                        invalidate: ["parking"],
                                        success: (r) => `Çıkış: ${r.duration_minutes} dk${r.calculated_fee > 0 ? `, ücret ${tl(r.calculated_fee)}` : ""}`,
                                    })}>Çıkış</Button>
                                ) },
                            ]} />
                        )}
                    </QueryView>
                )}
                {tab === "vehicles" && (
                    <QueryView q={vehicles} empty="Kayıtlı araç yok">
                        {(d) => (
                            <Table rows={d.data} rowKey={(v) => v.id} columns={[
                                { header: "Plaka", cell: (v) => <span className="font-mono font-bold">{v.plate}</span> },
                                { header: "Daire", cell: (v) => v.unit_name ?? "—" },
                                { header: "Sahip", cell: (v) => v.owner_name ?? OWNER_TYPES.find((o) => o.value === v.owner_type)?.label ?? v.owner_type },
                                { header: "Araç", cell: (v) => [v.brand, v.model, v.color].filter(Boolean).join(" ") || "—" },
                                { header: "Durum", cell: (v) => (v.is_active ? <Badge tone="green">Aktif</Badge> : <Badge>Pasif</Badge>) },
                                { header: "", cell: (v) => v.is_active ? (
                                    <Button size="sm" variant="ghost" disabled={act.pending}
                                        onClick={() => act.run(() => api.parking.deactivateVehicle(v.id), { invalidate: ["parking"], success: "Araç pasife alındı" })}>Pasife al</Button>
                                ) : null },
                            ]} />
                        )}
                    </QueryView>
                )}
                {tab === "zones" && (
                    <QueryView q={zones} empty="Otopark bölgesi tanımlı değil">
                        {(d) => (
                            <Table rows={d.data} rowKey={(z) => z.id} columns={[
                                { header: "Bölge", cell: (z) => z.name },
                                { header: "Konum", cell: (z) => z.location ?? "—" },
                                { header: "Doluluk", cell: (z) => `${z.occupied_count} / ${z.capacity}` },
                                { header: "Ücret", cell: (z) => (z.is_paid ? `${tl(z.hourly_fee)}/sa${z.daily_fee ? ` · ${tl(z.daily_fee)}/gün` : ""}` : "Ücretsiz") },
                            ]} />
                        )}
                    </QueryView>
                )}
            </Card>

            <FormModal open={!!entry} onClose={() => setEntry(null)} title="Araç girişi" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!entry) return;
                    const r = await act.run(() => api.parking.entry({ ...entry, parking_zone_id: entry.parking_zone_id || undefined }), {
                        invalidate: ["parking"],
                        success: (res) => (res.is_resident_vehicle ? "Giriş kaydedildi (sitede kayıtlı araç)" : "Giriş kaydedildi (misafir araç — çıkışta ücret hesaplanabilir)"),
                    });
                    if (r) setEntry(null);
                }}>
                {entry && (
                    <Grid>
                        <Field label="Plaka" required><Input required value={entry.plate} onChange={(e) => setEntry({ ...entry, plate: e.target.value.toUpperCase() })} className="font-mono" /></Field>
                        <Field label="Bölge"><Select value={entry.parking_zone_id} onChange={(e) => setEntry({ ...entry, parking_zone_id: e.target.value })} options={zoneOptions} placeholder="Belirtilmedi" /></Field>
                        <Field label="Kapı"><Input value={entry.entry_gate} onChange={(e) => setEntry({ ...entry, entry_gate: e.target.value })} /></Field>
                    </Grid>
                )}
            </FormModal>

            <FormModal open={!!vehicle} onClose={() => setVehicle(null)} title="Araç kaydet" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!vehicle) return;
                    const r = await act.run(() => api.parking.createVehicle(vehicle), { invalidate: ["parking"], success: "Araç kaydedildi" });
                    if (r) setVehicle(null);
                }}>
                {vehicle && (
                    <Grid>
                        <Field label="Plaka" required><Input required value={vehicle.plate} onChange={(e) => setVehicle({ ...vehicle, plate: e.target.value.toUpperCase() })} className="font-mono" /></Field>
                        <Field label="Daire">
                            <Select value={vehicle.unit_id} onChange={(e) => setVehicle({ ...vehicle, unit_id: e.target.value })}
                                options={(units.data?.data ?? []).map((u) => ({ value: u.id, label: `${u.block}-${u.door_number}` }))} placeholder="Yok" />
                        </Field>
                        <Field label="Sahip türü"><Select value={vehicle.owner_type} onChange={(e) => setVehicle({ ...vehicle, owner_type: e.target.value })} options={OWNER_TYPES} /></Field>
                        <Field label="Sahip adı"><Input value={vehicle.owner_name} onChange={(e) => setVehicle({ ...vehicle, owner_name: e.target.value })} /></Field>
                        <Field label="Araç türü"><Select value={vehicle.vehicle_type} onChange={(e) => setVehicle({ ...vehicle, vehicle_type: e.target.value })} options={VEHICLE_TYPES} /></Field>
                        <Field label="Park yeri"><Input value={vehicle.parking_spot} onChange={(e) => setVehicle({ ...vehicle, parking_spot: e.target.value })} /></Field>
                        <Field label="Marka"><Input value={vehicle.brand} onChange={(e) => setVehicle({ ...vehicle, brand: e.target.value })} /></Field>
                        <Field label="Model / renk"><Input value={vehicle.model} onChange={(e) => setVehicle({ ...vehicle, model: e.target.value })} /></Field>
                    </Grid>
                )}
            </FormModal>
        </Page>
    );
}
