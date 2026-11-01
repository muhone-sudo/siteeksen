"use client";

import { useEffect, useRef, useState } from "react";
import dynamic from "next/dynamic";
import { useParams, useRouter } from "next/navigation";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Notice, Page, QueryView, Select, StatusBadge, Table, Textarea } from "@/components/ui/kit";
import { kurus } from "@/lib/format";
import { BUSINESS_STATUS, PHOTO_STATUS, SERVICE_AREA } from "@/components/market/labels";
import { ServicePhoto } from "@/components/market/service-photo";
import { FieldGroup } from "@/components/market/field-group";
import type { MpBusiness, MpBusinessInput, MpService, MpServiceInput } from "@/lib/types";

const LocationPicker = dynamic(() => import("@/components/market/location-picker"), {
    ssr: false, loading: () => <p className="p-4 text-sm text-gray-500">Harita yükleniyor…</p>,
});

const EMPTY: MpBusinessInput = {
    name: "", description: "", phone: "", address: "", city: "", district: "", latitude: null, longitude: null,
    service_area: "KM", radius_km: 10, category_ids: [],
};

/** İşletme ekleme/düzenleme (FAZ M3): bilgiler, harita konumu, hizmet alanı, kategoriler; kayıtlıysa hizmet kalemleri. */
export default function SupplierBusinessPage() {
    const { id } = useParams<{ id: string }>();
    const isNew = id === "yeni";
    const b = useApi(["market-business", id], () => api.market.business(id), !isNew);
    if (isNew) return <BusinessEditor />;
    return (
        <QueryView q={b}>{(x) => <BusinessEditor existing={x} />}</QueryView>
    );
}

function BusinessEditor({ existing }: { existing?: MpBusiness }) {
    const router = useRouter();
    const meta = useApi(["market-meta"], api.market.meta);
    const act = useAction();
    const [f, setF] = useState<MpBusinessInput>(existing ? { ...existing } : EMPTY);
    useEffect(() => { if (existing) setF({ ...existing }); }, [existing]);
    const closed = existing?.status === "CLOSED";
    const toggleCat = (cid: string) => setF({ ...f, category_ids: f.category_ids.includes(cid) ? f.category_ids.filter((c) => c !== cid) : [...f.category_ids, cid] });

    const save = () => act.run(async () => {
        const body = { ...f, radius_km: f.service_area === "KM" ? f.radius_km : null };
        if (existing) return api.market.updateBusiness(existing.id, body);
        const created = await api.market.createBusiness(body);
        router.replace(`/tedarikci/isletmeler/${created.id}`);
        return created;
    }, { invalidate: ["market-businesses", "market-business"], success: "İşletme kaydedildi" });

    return (
        <Page title={existing ? existing.name : "Yeni işletme"} description="İşletme bilgileri, konum ve hizmet alanı"
            actions={existing && <StatusBadge value={existing.status} map={BUSINESS_STATUS} />}>
            <ActionFeedback action={act} />
            {existing?.review_note && <Notice tone={existing.status === "REJECTED" ? "red" : "blue"} title="İnceleme notu">{existing.review_note}</Notice>}
            {existing?.status === "DRAFT" && <Notice tone="amber">İşletme taslakta; havuzda görünmesi için incelemeye gönderin.</Notice>}
            <Card title="Bilgiler">
                <div className="space-y-4">
                    <Grid>
                        <Field label="İşletme adı" required><Input value={f.name} disabled={closed} onChange={(e) => setF({ ...f, name: e.target.value })} /></Field>
                        <Field label="İşletme telefonu" hint="Vitrinde yalnız ücretli pakette görünür" required>
                            <Input value={f.phone} disabled={closed} onChange={(e) => setF({ ...f, phone: e.target.value })} placeholder="0216 123 45 67" />
                        </Field>
                    </Grid>
                    <Field label="Tanıtım" hint="Telefon ve e-posta yazmayın; gizlenir. Müşteri size talep üzerinden ulaşır.">
                        <Textarea value={f.description} disabled={closed} onChange={(e) => setF({ ...f, description: e.target.value })} />
                    </Field>
                    <Field label="Adres" required><Textarea value={f.address} disabled={closed} onChange={(e) => setF({ ...f, address: e.target.value })} /></Field>
                    <Grid>
                        <Field label="İl" required><Input value={f.city} disabled={closed} onChange={(e) => setF({ ...f, city: e.target.value })} /></Field>
                        <Field label="İlçe" required><Input value={f.district} disabled={closed} onChange={(e) => setF({ ...f, district: e.target.value })} /></Field>
                    </Grid>
                    <FieldGroup label="Konum" hint="Haritada işletmenin yerine tıklayın" required>
                        <LocationPicker lat={f.latitude} lng={f.longitude} readOnly={closed}
                            onPick={(lat, lng) => setF({ ...f, latitude: lat, longitude: lng })} />
                    </FieldGroup>
                    <Grid>
                        <Field label="Hizmet alanı" required>
                            <Select value={f.service_area} disabled={closed} onChange={(e) => setF({ ...f, service_area: e.target.value as MpBusinessInput["service_area"] })}
                                options={Object.entries(SERVICE_AREA).map(([value, label]) => ({ value, label }))} />
                        </Field>
                        {f.service_area === "KM" && (
                            <Field label="Yarıçap (km)" hint="1–500" required>
                                <Input type="number" min={1} max={500} value={f.radius_km ?? ""} disabled={closed}
                                    onChange={(e) => setF({ ...f, radius_km: e.target.value === "" ? null : Number(e.target.value) })} />
                            </Field>
                        )}
                    </Grid>
                    <FieldGroup label="Kategoriler" required>
                        <QueryView q={meta}>
                            {(m) => (
                                <div className="flex flex-wrap gap-2">
                                    {m.categories.length === 0 && <p className="text-sm text-gray-500">Henüz kategori tanımlanmamış.</p>}
                                    {m.categories.map((c) => (
                                        <label key={c.id} className={`flex cursor-pointer items-center gap-1.5 rounded-lg border px-3 py-1.5 text-sm ${f.category_ids.includes(c.id) ? "border-primary bg-primary/10" : ""}`}>
                                            <input type="checkbox" checked={f.category_ids.includes(c.id)} disabled={closed} onChange={() => toggleCat(c.id)} />
                                            {c.name}
                                        </label>
                                    ))}
                                </div>
                            )}
                        </QueryView>
                    </FieldGroup>
                    {!closed && (
                        <div className="flex flex-wrap gap-2">
                            <Button disabled={act.pending} onClick={() => void save()}>Kaydet</Button>
                            {existing && (existing.status === "DRAFT" || existing.status === "REJECTED") && (
                                <Button variant="secondary" disabled={act.pending} onClick={() => act.run(() => api.market.submitBusiness(existing.id),
                                    { invalidate: ["market-businesses", "market-business"], success: "İşletme incelemeye gönderildi" })}>İncelemeye gönder</Button>
                            )}
                            {existing && (
                                <Button variant="danger" disabled={act.pending} onClick={() => {
                                    if (confirm("İşletme kapatılsın mı? Kapatılan işletme havuzdan çıkar ve yeniden açılamaz.")) {
                                        void act.run(() => api.market.closeBusiness(existing.id), { invalidate: ["market-businesses", "market-business"], success: "İşletme kapatıldı" });
                                    }
                                }}>İşletmeyi kapat</Button>
                            )}
                        </div>
                    )}
                </div>
            </Card>
            {existing && <Services businessId={existing.id} readOnly={closed} />}
        </Page>
    );
}

const TL = (k: number | null) => (k == null ? "" : String(k / 100));
const KURUS = (s: string) => (s.trim() === "" ? null : Math.round(Number(s.replace(",", ".")) * 100));

function Services({ businessId, readOnly }: { businessId: string; readOnly: boolean }) {
    const list = useApi(["market-services", businessId], () => api.market.services(businessId));
    const act = useAction();
    const [edit, setEdit] = useState<(MpServiceInput & { id?: string; min: string; max: string }) | null>(null);
    const fileRef = useRef<HTMLInputElement>(null);
    const [photoFor, setPhotoFor] = useState<string | null>(null);
    const open = (s?: MpService) => setEdit(s
        ? { ...s, min: TL(s.price_min_kurus), max: TL(s.price_max_kurus) }
        : { name: "", description: "", price_min_kurus: null, price_max_kurus: null, unit: "", is_active: true, sort_order: 0, min: "", max: "" });
    return (
        <Card title="Hizmet ve ürünler" padded={false}
            actions={!readOnly && <Button size="sm" onClick={() => open()}>Hizmet ekle</Button>}>
            <ActionFeedback action={act} />
            <input ref={fileRef} type="file" accept="image/jpeg,image/png,image/webp" className="hidden" onChange={(e) => {
                const file = e.target.files?.[0];
                if (!file || !photoFor) return;
                const form = new FormData();
                form.append("file", file);
                void act.run(() => api.market.uploadServicePhoto(photoFor, form), { invalidate: ["market-services"], success: (r) => r.message ?? "Fotoğraf yüklendi" })
                    .then(() => { e.target.value = ""; setPhotoFor(null); });
            }} />
            <QueryView q={list} empty="Henüz hizmet eklenmedi">
                {(d) => (
                    <Table rows={d.data} rowKey={(s) => s.id} columns={[
                        { header: "", cell: (s) => (s.has_photo ? (
                            <div className="space-y-1">
                                <ServicePhoto id={s.id} className="h-12 w-12 rounded object-cover" />
                                {s.photo_status && <StatusBadge value={s.photo_status} map={PHOTO_STATUS} />}
                                {s.photo_status === "REJECTED" && s.photo_reason && <p className="max-w-48 text-xs text-red-600">{s.photo_reason}</p>}
                            </div>
                        ) : <span className="text-xs text-gray-400">—</span>) },
                        { header: "Hizmet", cell: (s) => <div><p className="font-medium">{s.name}</p><p className="text-xs text-gray-500">{s.description}</p></div> },
                        { header: "Fiyat", cell: (s) => (s.price_min_kurus == null ? <Badge>Teklifle</Badge>
                            : `${kurus(s.price_min_kurus)} – ${kurus(s.price_max_kurus)}${s.unit ? ` / ${s.unit}` : ""}`) },
                        { header: "Durum", cell: (s) => (s.is_active ? <Badge tone="green">Etkin</Badge> : <Badge>Pasif</Badge>) },
                        { header: "", cell: (s) => !readOnly && (
                            <div className="flex gap-1">
                                <Button size="sm" variant="ghost" onClick={() => open(s)}>Düzenle</Button>
                                <Button size="sm" variant="ghost" onClick={() => { setPhotoFor(s.id); fileRef.current?.click(); }}>Fotoğraf</Button>
                                <Button size="sm" variant="ghost" disabled={act.pending} onClick={() => act.run(() => api.market.deleteService(s.id), { invalidate: ["market-services"], success: "Hizmet silindi" })}>Sil</Button>
                            </div>
                        ) },
                    ]} />
                )}
            </QueryView>
            {edit && (
                <FormModal open title={edit.id ? "Hizmeti düzenle" : "Hizmet ekle"} onClose={() => setEdit(null)} pending={act.pending} error={act.error}
                    onSubmit={async () => {
                        const body: MpServiceInput = { name: edit.name, description: edit.description, unit: edit.unit, is_active: edit.is_active,
                            sort_order: edit.sort_order, price_min_kurus: KURUS(edit.min), price_max_kurus: KURUS(edit.max) };
                        const r = await act.run(() => (edit.id ? api.market.updateService(edit.id, body) : api.market.createService(businessId, body)),
                            { invalidate: ["market-services"], success: "Hizmet kaydedildi" });
                        if (r) setEdit(null);
                    }}>
                    <Field label="Hizmet / ürün adı" required><Input value={edit.name} onChange={(e) => setEdit({ ...edit, name: e.target.value })} /></Field>
                    <Field label="Açıklama"><Textarea value={edit.description} onChange={(e) => setEdit({ ...edit, description: e.target.value })} /></Field>
                    <Grid cols={3}>
                        <Field label="En düşük (TL)" hint="Teklifle verilecekse boş"><Input inputMode="decimal" value={edit.min} onChange={(e) => setEdit({ ...edit, min: e.target.value })} /></Field>
                        <Field label="En yüksek (TL)"><Input inputMode="decimal" value={edit.max} onChange={(e) => setEdit({ ...edit, max: e.target.value })} /></Field>
                        <Field label="Birim" hint="ör. saat, m², adet"><Input value={edit.unit} onChange={(e) => setEdit({ ...edit, unit: e.target.value })} /></Field>
                    </Grid>
                    <label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={edit.is_active} onChange={(e) => setEdit({ ...edit, is_active: e.target.checked })} /> Etkin (vitrinde görünür)</label>
                </FormModal>
            )}
        </Card>
    );
}
