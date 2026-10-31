"use client";

// Site konumu (077, FAZ M2.4): Usta & Hizmet eşleşmesi tedarikçinin hizmet yarıçapını bu konuma göre ölçer.
// Konum girilmemişse yalnız aynı ilçedeki ve il/Türkiye geneli hizmet veren tedarikçiler eşleşir.

import { useEffect, useState } from "react";
import dynamic from "next/dynamic";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Button, Card, Field, Grid, Input, Notice, QueryView } from "@/components/ui/kit";

const LocationPicker = dynamic(() => import("@/components/market/location-picker"), {
    ssr: false, loading: () => <p className="p-4 text-sm text-gray-500">Harita yükleniyor…</p>,
});

export function LocationCard() {
    const status = useApi(["property-status"], api.identity.propertyStatus);
    const act = useAction();
    const { roles } = useRoles();
    const isManager = roles.includes("MANAGER");
    const [lat, setLat] = useState("");
    const [lng, setLng] = useState("");
    useEffect(() => {
        if (status.data) {
            setLat(status.data.latitude != null ? String(status.data.latitude) : "");
            setLng(status.data.longitude != null ? String(status.data.longitude) : "");
        }
    }, [status.data]);
    const nLat = lat === "" ? null : Number(lat);
    const nLng = lng === "" ? null : Number(lng);
    const valid = (nLat === null) === (nLng === null) && (nLat === null || (!Number.isNaN(nLat) && !Number.isNaN(nLng!)));

    return (
        <>
            <ActionFeedback action={act} />
            <Card title="Site konumu">
                <QueryView q={status}>
                    {(s) => (
                        <div className="space-y-3 text-sm">
                            <Notice tone={s.latitude != null ? "blue" : "amber"}>
                                {s.latitude != null
                                    ? "Usta & Hizmet'te sakinlerin talepleri, hizmet alanı bu konumu kapsayan tedarikçilere gider."
                                    : "Site konumu girilmemiş. Usta & Hizmet'te yalnız aynı ilçedeki ya da il/Türkiye geneli hizmet veren tedarikçiler eşleşir; haritada sitenin yerine tıklayıp kaydedin."}
                            </Notice>
                            <LocationPicker lat={nLat} lng={nLng} readOnly={!isManager}
                                onPick={(a, b) => { setLat(String(a)); setLng(String(b)); }} />
                            {isManager && (
                                <>
                                    <Grid>
                                        <Field label="Enlem"><Input value={lat} onChange={(e) => setLat(e.target.value)} placeholder="41.0082" /></Field>
                                        <Field label="Boylam"><Input value={lng} onChange={(e) => setLng(e.target.value)} placeholder="28.9784" /></Field>
                                    </Grid>
                                    <div className="flex gap-2">
                                        <Button disabled={!valid || act.pending || nLat === null}
                                            onClick={() => act.run(() => api.identity.setPropertyLocation(nLat, nLng), { invalidate: ["property-status"], success: "Site konumu kaydedildi" })}>
                                            Konumu kaydet
                                        </Button>
                                        {s.latitude != null && (
                                            <Button variant="ghost" disabled={act.pending}
                                                onClick={() => act.run(() => api.identity.setPropertyLocation(null, null), { invalidate: ["property-status"], success: "Site konumu silindi" })}>
                                                Konumu sil
                                            </Button>
                                        )}
                                    </div>
                                </>
                            )}
                        </div>
                    )}
                </QueryView>
            </Card>
        </>
    );
}
