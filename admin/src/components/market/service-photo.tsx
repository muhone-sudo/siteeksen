"use client";

import { useEffect, useState } from "react";
import apiClient from "@/lib/api-client";

/** Hizmet fotoğrafı: kimlik doğrulamalı uçtan blob olarak okunur (img etiketi jeton taşıyamaz). */
export function ServicePhoto({ id, className }: { id: string; className?: string }) {
    const [src, setSrc] = useState<string | null>(null);
    const [failed, setFailed] = useState(false);
    useEffect(() => {
        let url: string | null = null;
        let alive = true;
        apiClient.blob(`/market/services/${id}/photo`)
            .then((b) => { url = URL.createObjectURL(b); if (alive) setSrc(url); })
            .catch(() => alive && setFailed(true));
        return () => { alive = false; if (url) URL.revokeObjectURL(url); };
    }, [id]);
    if (failed) return <span className="text-xs text-gray-400">fotoğraf yok</span>;
    // eslint-disable-next-line @next/next/no-img-element
    return src ? <img src={src} alt="" className={className} /> : <span className="inline-block h-12 w-12 animate-pulse rounded bg-gray-100" />;
}
