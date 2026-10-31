"use client";

import { useState } from "react";
import dynamic from "next/dynamic";
import Link from "next/link";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Button, Card, Field, FormModal, Modal, Page, QueryView, StatusBadge, Table, Tabs, Textarea } from "@/components/ui/kit";
import { dateTime } from "@/lib/format";
import { BUSINESS_STATUS, SERVICE_AREA } from "@/components/market/labels";
import type { MpBusiness } from "@/lib/types";

const LocationPicker = dynamic(() => import("@/components/market/location-picker"), { ssr: false });
const TABS = [{ id: "REVIEW", label: "Onay bekleyen" }, { id: "PUBLISHED", label: "Yayında" }, { id: "REJECTED", label: "Reddedilen" }, { id: "", label: "Tümü" }] as const;

/** İşletme yayın onayı (FAZ M4.2): onaylı hesabın işletmesi incelemeden sonra vitrine çıkar. */
export default function PlatformBusinessesPage() {
    const [status, setStatus] = useState<(typeof TABS)[number]["id"]>("REVIEW");
    const list = useApi(["mp-businesses", status], () => api.market.platform.businesses(status));
    const meta = useApi(["market-meta"], api.market.meta);
    const act = useAction();
    const [view, setView] = useState<MpBusiness | null>(null);
    const [reject, setReject] = useState<{ b: MpBusiness; reason: string } | null>(null);
    const catName = (id: string) => meta.data?.categories.find((c) => c.id === id)?.name ?? id.slice(0, 8);
    return (
        <Page title="İşletme yayın onayı" description="Adres, konum, hizmet alanı ve kategoriler kontrol edilir">
            <ActionFeedback action={act} />
            <Tabs tabs={TABS.map((t) => ({ id: t.id, label: t.label }))} value={status} onChange={setStatus} />
            <Card padded={false}>
                <QueryView q={list} empty="Bu durumda işletme yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(b) => b.id} columns={[
                            { header: "İşletme", cell: (b) => <button className="font-medium text-primary hover:underline" onClick={() => setView(b)}>{b.name}</button> },
                            { header: "Hesap", cell: (b) => <Link className="text-xs text-primary hover:underline" href={`/platform/hesaplar/${b.account_id}`}>hesaba git</Link> },
                            { header: "Yer", cell: (b) => `${b.district} / ${b.city}` },
                            { header: "Hizmet alanı", cell: (b) => (b.service_area === "KM" ? `${b.radius_km} km` : SERVICE_AREA[b.service_area]) },
                            { header: "Kategoriler", cell: (b) => b.category_ids.map(catName).join(", ") },
                            { header: "Durum", cell: (b) => <StatusBadge value={b.status} map={BUSINESS_STATUS} /> },
                            { header: "", cell: (b) => b.status === "REVIEW" && (
                                <div className="flex gap-1">
                                    <Button size="sm" disabled={act.pending} onClick={() => act.run(() => api.market.platform.reviewBusiness(b.id, "approve"),
                                        { invalidate: ["mp-businesses"], success: (r) => `Yayına alındı. Bildirim: ${r.notification.in_app}` })}>Yayına al</Button>
                                    <Button size="sm" variant="danger" onClick={() => setReject({ b, reason: "" })}>Reddet</Button>
                                </div>
                            ) },
                        ]} />
                    )}
                </QueryView>
            </Card>
            {view && (
                <Modal open title={view.name} onClose={() => setView(null)} wide>
                    <div className="space-y-2 text-sm">
                        <p>{view.address} — {view.district} / {view.city} · {view.phone}</p>
                        <p className="text-gray-600">{view.description}</p>
                        <p>Gönderildi: {dateTime(view.created_at)}</p>
                        <LocationPicker lat={view.latitude} lng={view.longitude} readOnly height={260} />
                    </div>
                </Modal>
            )}
            {reject && (
                <FormModal open title="Yayın onayını reddet" onClose={() => setReject(null)} pending={act.pending} error={act.error} submitLabel="Reddet"
                    onSubmit={async () => {
                        const r = await act.run(() => api.market.platform.reviewBusiness(reject.b.id, "reject", reject.reason), { invalidate: ["mp-businesses"], success: "Reddedildi" });
                        if (r) setReject(null);
                    }}>
                    <Field label="Gerekçe (tedarikçiye gösterilir)" required><Textarea value={reject.reason} onChange={(e) => setReject({ ...reject, reason: e.target.value })} /></Field>
                </FormModal>
            )}
        </Page>
    );
}
