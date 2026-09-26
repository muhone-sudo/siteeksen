import axios, { AxiosError, AxiosInstance, AxiosRequestConfig } from "axios";
import { getSession, signOut } from "next-auth/react";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8888/api/v1";

/**
 * Gateway istemcisi.
 *
 * YENİDEN YAZILDI (2026-09-26). Önceki sürümün sorunları:
 *   - Jeton hem NextAuth oturumunda hem localStorage'da tutuluyordu ve ikisi
 *     birbirinden kopuyordu. Kenar çubuğu her yüklemede oturumdaki ESKİ jetonu
 *     geri yazıyordu: 15 dakika sonra süresi dolmuş jetonla istek atılıyor, site
 *     değiştirildikten sonra istekler hâlâ ESKİ siteye gidiyordu.
 *   - 50'ye yakın uç yöntemi, arka uçta hiç olmayan yollara istek atıyordu
 *     (ör. /visitors/inside, /employees/stats, /parking-logs/current).
 *
 * Artık:
 *   - Tek doğruluk kaynağı NextAuth oturumudur. Jeton yenilemesi sunucu
 *     tarafında (auth route `jwt` geri çağrısı) yapılır; istemci yalnızca
 *     oturumdaki jetonu kullanır. Jeton localStorage'a YAZILMAZ (XSS ile
 *     çalınabilecek kalıcı bir kopya bırakılmaz).
 *   - 401 gelirse oturum bir kez tazelenir ve istek tekrarlanır; yine 401 ise
 *     kullanıcı giriş ekranına döner.
 *   - Uçlar `lib/endpoints.ts`'te, arka uç sözleşmesiyle (tasks/api-sozlesmesi.md)
 *     birebir tanımlıdır.
 */
class ApiClient {
    private client: AxiosInstance;
    private accessToken: string | null = null;
    private refreshing: Promise<string | null> | null = null;

    constructor() {
        this.client = axios.create({
            baseURL: API_BASE_URL,
            headers: { "Content-Type": "application/json" },
        });

        this.client.interceptors.request.use((config) => {
            if (this.accessToken) {
                config.headers.Authorization = `Bearer ${this.accessToken}`;
            }
            return config;
        });

        this.client.interceptors.response.use(
            (response) => response,
            async (error: AxiosError) => {
                const original = error.config as AxiosRequestConfig & { _retry?: boolean };
                if (error.response?.status === 401 && original && !original._retry && typeof window !== "undefined") {
                    original._retry = true;
                    const fresh = await this.refreshFromSession();
                    if (fresh) {
                        original.headers = { ...(original.headers ?? {}), Authorization: `Bearer ${fresh}` };
                        return this.client(original);
                    }
                    await signOut({ callbackUrl: "/login" });
                }
                return Promise.reject(error);
            }
        );
    }

    /** Oturumu tazeler (NextAuth jwt geri çağrısı süresi dolan jetonu yeniler). */
    private refreshFromSession(): Promise<string | null> {
        if (!this.refreshing) {
            this.refreshing = getSession()
                .then((s) => {
                    const token = s?.accessToken ?? null;
                    if (!token || token === this.accessToken || s?.error) return null;
                    this.accessToken = token;
                    return token;
                })
                .catch(() => null)
                .finally(() => {
                    this.refreshing = null;
                });
        }
        return this.refreshing;
    }

    setToken(token: string | null) {
        this.accessToken = token;
    }

    hasToken(): boolean {
        return !!this.accessToken;
    }

    getActivePropertyId(): string | null {
        if (!this.accessToken) return null;
        try {
            const part = this.accessToken.split(".")[1].replace(/-/g, "+").replace(/_/g, "/");
            return JSON.parse(atob(part)).property_id ?? null;
        } catch {
            return null;
        }
    }

    // ------------------------------------------------------------ genel istek
    async get<T>(url: string, params?: Record<string, unknown>): Promise<T> {
        return (await this.client.get<T>(url, { params: clean(params) })).data;
    }

    async post<T>(url: string, body?: unknown): Promise<T> {
        return (await this.client.post<T>(url, body ?? {})).data;
    }

    async put<T>(url: string, body?: unknown): Promise<T> {
        return (await this.client.put<T>(url, body ?? {})).data;
    }

    async patch<T>(url: string, body?: unknown): Promise<T> {
        return (await this.client.patch<T>(url, body ?? {})).data;
    }

    async del<T>(url: string, body?: unknown): Promise<T> {
        return (await this.client.delete<T>(url, body === undefined ? undefined : { data: body })).data;
    }

    async upload<T>(url: string, form: FormData): Promise<T> {
        return (await this.client.post<T>(url, form, { headers: { "Content-Type": "multipart/form-data" } })).data;
    }

    /** İkili dosyayı indirir; sunucunun verdiği dosya adıyla kaydeder. */
    async download(url: string, fallbackName: string): Promise<void> {
        const res = await this.client.get<Blob>(url, { responseType: "blob" });
        const cd = String(res.headers["content-disposition"] ?? "");
        const match = /filename="?([^";]+)"?/i.exec(cd);
        const name = match ? decodeURIComponent(match[1]) : fallbackName;
        const href = URL.createObjectURL(res.data);
        const a = document.createElement("a");
        a.href = href;
        a.download = name;
        a.click();
        URL.revokeObjectURL(href);
    }

    // ------------------------------------------------------------ oturum
    /**
     * Sunucuda oturumu kapatır: erişim VE yenileme jetonu iptal edilir.
     * Yenileme jetonu gönderilmezse 7 gün boyunca yeni erişim jetonu üretebilir.
     */
    async logout(refreshToken?: string) {
        try {
            const res = await this.client.post("/auth/logout", refreshToken ? { refresh_token: refreshToken } : {});
            return res.data as { access_token_revoked?: boolean; refresh_token_revoked?: boolean };
        } finally {
            this.accessToken = null;
        }
    }

    /** Yenileme jetonuyla yeni jeton çifti alır (site değişiminden sonra). */
    async refreshTokens(refreshToken: string) {
        const res = await this.client.post("/auth/refresh", { refresh_token: refreshToken });
        return res.data as { access_token: string; refresh_token: string; expires_in: number };
    }
}

/** Boş filtreleri sorgudan çıkarır (?status= gibi anlamsız parametre gönderilmesin). */
function clean(params?: Record<string, unknown>) {
    if (!params) return undefined;
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(params)) {
        if (v !== undefined && v !== null && v !== "") out[k] = v;
    }
    return out;
}

export const apiClient = new ApiClient();
export default apiClient;
