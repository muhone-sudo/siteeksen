"use client";

import { AlertTriangle, Inbox, Loader2, RefreshCw } from "lucide-react";

/**
 * Ortak veri durumu bileşenleri.
 *
 * Neden var: 2026-09-09 denetiminde, panelin 9 ayrı noktasında sunucu hatası alındığında
 * sessizce **uydurma veri** gösterildiği tespit edildi (örn. gider sayfası API hatasında
 * ₺45.750 gibi gerçek olmayan bir mali özet gösteriyordu). Bu, kullanıcının yanlış rakama
 * güvenmesine yol açar ve hiç veri göstermemekten çok daha zararlıdır.
 *
 * Kural (bkz. tasks/dogrulama-politikasi.md §3.2): Sessiz mock fallback yasaktır.
 * Veri çekilemediğinde bu bileşenlerle **hata görünür kılınır** ve yeniden denenebilir.
 */

export function LoadingState({ label = "Yükleniyor..." }: { label?: string }) {
    return (
        <div className="flex items-center justify-center gap-3 py-12 text-gray-500">
            <Loader2 className="h-5 w-5 animate-spin" aria-hidden="true" />
            <span>{label}</span>
        </div>
    );
}

export function ErrorState({
    message,
    onRetry,
    retryLabel = "Yeniden dene",
}: {
    message: string;
    onRetry?: () => void;
    retryLabel?: string;
}) {
    return (
        <div
            role="alert"
            className="flex flex-col items-center justify-center gap-3 rounded-lg border border-red-200 bg-red-50 px-6 py-10 text-center"
        >
            <AlertTriangle className="h-6 w-6 text-red-600" aria-hidden="true" />
            <div>
                <p className="font-medium text-red-800">Veri yüklenemedi</p>
                <p className="mt-1 text-sm text-red-700">{message}</p>
            </div>
            {onRetry && (
                <button
                    type="button"
                    onClick={onRetry}
                    className="mt-1 inline-flex items-center gap-2 rounded-md bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700"
                >
                    <RefreshCw className="h-4 w-4" aria-hidden="true" />
                    {retryLabel}
                </button>
            )}
        </div>
    );
}

export function EmptyState({
    title = "Kayıt bulunamadı",
    description,
}: {
    title?: string;
    description?: string;
}) {
    return (
        <div className="flex flex-col items-center justify-center gap-2 py-12 text-center text-gray-500">
            <Inbox className="h-6 w-6" aria-hidden="true" />
            <p className="font-medium">{title}</p>
            {description && <p className="text-sm">{description}</p>}
        </div>
    );
}

/**
 * Bir hatadan kullanıcıya gösterilebilir mesaj üretir.
 * Ham sunucu/veritabanı hata metnini kullanıcıya yansıtmamak için yalnızca
 * backend'in bilinçli olarak döndürdüğü `error` alanı kullanılır.
 */
export function toUserMessage(err: unknown, fallback = "Sunucuya ulaşılamadı."): string {
    const anyErr = err as { response?: { status?: number; data?: { error?: string } }; message?: string };

    const serverError = anyErr?.response?.data?.error;
    if (typeof serverError === "string" && serverError.trim() !== "") {
        return serverError;
    }

    const status = anyErr?.response?.status;
    if (status === 401) return "Oturumunuz sona ermiş. Lütfen tekrar giriş yapın.";
    if (status === 403) return "Bu işlem için yetkiniz yok.";
    if (status === 404) return "Bu özellik henüz sunucu tarafında hazır değil (404).";
    if (status === 501) return "Bu özellik henüz sunucu tarafında hazır değil.";
    if (typeof status === "number" && status >= 500) return "Sunucu hatası oluştu. Lütfen daha sonra tekrar deneyin.";

    return fallback;
}

/**
 * Sunucu tarafında henüz hazır olmayan (veriyi kalıcı yazmayan) bölümler için uyarı.
 * Kullanıcının sahte veriyi gerçek sanmasını engeller.
 */
export function NotImplementedNotice({ detail }: { detail?: string }) {
    return (
        <div
            role="note"
            className="mb-4 flex items-start gap-3 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3"
        >
            <AlertTriangle className="mt-0.5 h-5 w-5 shrink-0 text-amber-600" aria-hidden="true" />
            <div className="text-sm">
                <p className="font-medium text-amber-900">Bu bölüm henüz hazır değil</p>
                <p className="mt-0.5 text-amber-800">
                    {detail ??
                        "Sunucu tarafı bağlantısı tamamlanmadığı için burada yapılan değişiklikler kalıcı olarak kaydedilmez."}
                </p>
            </div>
        </div>
    );
}
