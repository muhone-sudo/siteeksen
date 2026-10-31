"use client";

import "leaflet/dist/leaflet.css";
import { useEffect, useRef } from "react";
import { CircleMarker, MapContainer, TileLayer, useMap, useMapEvents } from "react-leaflet";

/** Türkiye'nin ortası: konum henüz seçilmemişse harita buradan açılır. */
const TR_CENTER: [number, number] = [39.0, 35.2];

function ClickToPick({ onPick }: { onPick: (lat: number, lng: number) => void }) {
    useMapEvents({ click: (e) => onPick(Number(e.latlng.lat.toFixed(6)), Number(e.latlng.lng.toFixed(6))) });
    return null;
}

/** Konum sonradan (veri yüklenince) gelirse harita bir kez oraya odaklanır; kullanıcı tıklamalarında kaydırılmaz. */
function FocusOnce({ lat, lng }: { lat?: number | null; lng?: number | null }) {
    const map = useMap();
    const done = useRef(false);
    useEffect(() => {
        if (!done.current && lat != null && lng != null) {
            done.current = true;
            map.setView([lat, lng], Math.max(map.getZoom(), 15));
        }
    }, [lat, lng, map]);
    return null;
}

/**
 * Haritada iğneyle konum seçme (site konumu, işletme konumu — FAZ M). Adres çözümleme (geocoding) yoktur:
 * adres metni ayrıca yazılır, konum haritaya tıklanarak seçilir. OpenStreetMap karoları (yayında karo sağlayıcısı: M0.6).
 */
export default function LocationPicker({ lat, lng, onPick, readOnly, height = 320 }: {
    lat?: number | null; lng?: number | null; onPick?: (lat: number, lng: number) => void; readOnly?: boolean; height?: number;
}) {
    const has = lat != null && lng != null;
    return (
        <MapContainer center={has ? [lat!, lng!] : TR_CENTER} zoom={has ? 15 : 6} scrollWheelZoom style={{ height, width: "100%" }}>
            <TileLayer attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> katkıcıları'
                url="https://tile.openstreetmap.org/{z}/{x}/{y}.png" />
            <FocusOnce lat={lat} lng={lng} />
            {has && <CircleMarker center={[lat!, lng!]} radius={9} pathOptions={{ color: "#dc2626", fillOpacity: 0.9 }} />}
            {!readOnly && onPick && <ClickToPick onPick={onPick} />}
        </MapContainer>
    );
}
