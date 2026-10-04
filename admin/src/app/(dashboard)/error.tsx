"use client";

import { useEffect } from "react";
import apiClient from "@/lib/api-client";
import { Button, Notice } from "@/components/ui/kit";

/**
 * Panel sayfalarında yakalanmayan hata (todo 3.6). Hata kullanıcıya dürüstçe
 * gösterilir ve sunucuya bildirilir (POST /client-errors); bildirim başarısız
 * olursa sessizce düşer — hata ekranı ikinci bir hatayla bozulmaz.
 */
export default function DashboardError({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
    useEffect(() => {
        apiClient.post("/client-errors", {
            app: "admin_panel",
            app_version: process.env.NEXT_PUBLIC_APP_VERSION ?? "dev",
            platform: typeof navigator === "undefined" ? "web" : navigator.userAgent.slice(0, 40),
            fatal: false,
            message: `${error.name}: ${error.message}`.slice(0, 2000),
            stack: (error.stack ?? "").slice(0, 8000),
        }).catch(() => undefined);
    }, [error]);

    return (
        <div className="space-y-4 p-6">
            <Notice tone="red" title="Bu sayfa yüklenirken beklenmeyen bir hata oluştu">
                Hata ayrıntısı sunucuya iletilmeye çalışıldı{error.digest ? ` (kod: ${error.digest})` : ""}. Tekrar deneyebilirsiniz.
            </Notice>
            <Button onClick={reset}>Tekrar dene</Button>
        </div>
    );
}