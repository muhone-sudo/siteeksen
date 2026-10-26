import api from "./api";
import type { ClientEvent } from "./types";

/**
 * Uygulama içi etkinlik kaydı (073, FAZ H.3). Yalnız site ayarı TAM ise gönderilir;
 * düzey girişte bir kez sorulur. Olaylar sırada toplanır, 15 sn'de bir ya da 20 olayda
 * toplu gönderilir. Gönderilemeyen olay tekrar denenmez (etkinlik kaydı en iyi çaba
 * düzeyindedir; zorunlu kayıtlar sunucuda tutulur).
 */
let enabled: boolean | null = null;
let queue: ClientEvent[] = [];
let timer: ReturnType<typeof setTimeout> | null = null;

export async function initActivity(): Promise<void> {
    if (enabled !== null) return;
    try {
        enabled = (await api.audit.level()).level === "FULL";
    } catch {
        enabled = false;
    }
}

export function resetActivity(): void {
    enabled = null;
    queue = [];
}

export function track(event: string, screen?: string, details?: Record<string, unknown>): void {
    if (!enabled) return;
    queue.push({ event, screen, details, client_at: new Date().toISOString(), client: "panel" });
    if (queue.length >= 20) {
        void flush();
    } else if (!timer) {
        timer = setTimeout(() => void flush(), 15000);
    }
}

export async function flush(): Promise<void> {
    if (timer) {
        clearTimeout(timer);
        timer = null;
    }
    if (!queue.length) return;
    const batch = queue.splice(0, 50);
    try {
        await api.audit.send(batch);
    } catch {
        /* en iyi çaba: kayıt kaybolursa yeniden denenmez */
    }
}
