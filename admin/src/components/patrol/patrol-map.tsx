"use client";

import "leaflet/dist/leaflet.css";
import { Circle, CircleMarker, MapContainer, Polyline, TileLayer, Tooltip } from "react-leaflet";
import type { PatrolReport } from "@/lib/types";

/**
 * Devriye turu haritası (075): konum izi (mavi çizgi), nokta yarıçapları (yeşil daire) ve okutma
 * denemeleri (yeşil kabul, turuncu şüpheli, kırmızı red). OpenStreetMap karoları.
 */
export default function PatrolMap({ report }: { report: PatrolReport }) {
    const line = report.track.map((t) => [t.latitude, t.longitude] as [number, number]);
    const cps = report.checkpoints.filter((c) => c.latitude != null && c.longitude != null);
    const att = report.attempts.filter((a) => a.latitude != null && a.longitude != null);
    const center: [number, number] | null = line[0] ?? (cps[0] ? [cps[0].latitude!, cps[0].longitude!] : att[0] ? [att[0].latitude!, att[0].longitude!] : null);
    if (!center) return <p className="p-4 text-sm text-gray-500">Haritada gösterilecek konum yok.</p>;
    return (
        <MapContainer center={center} zoom={17} scrollWheelZoom={false} style={{ height: 380, width: "100%" }}>
            <TileLayer attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> katkıcıları'
                url="https://tile.openstreetmap.org/{z}/{x}/{y}.png" />
            {line.length > 1 && <Polyline positions={line} pathOptions={{ color: "#2563eb", weight: 4 }} />}
            {cps.map((c) => (
                <Circle key={c.id} center={[c.latitude!, c.longitude!]} radius={c.radius_m} pathOptions={{ color: "#16a34a", fillOpacity: 0.15 }}>
                    <Tooltip>{c.name} ({c.radius_m} m)</Tooltip>
                </Circle>
            ))}
            {att.map((a, i) => (
                <CircleMarker key={i} center={[a.latitude!, a.longitude!]} radius={6}
                    pathOptions={{ color: a.accepted ? (a.suspicious ? "#ea580c" : "#16a34a") : "#dc2626", fillOpacity: 0.9 }}>
                    <Tooltip>{a.checkpoint || "Tanınmayan QR"} · {a.accepted ? "kabul" : a.reason_text ?? a.reason}{a.distance_m != null ? ` · ${Math.round(a.distance_m)} m` : ""}</Tooltip>
                </CircleMarker>
            ))}
        </MapContainer>
    );
}
