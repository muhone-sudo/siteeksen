"use client";

import { Suspense } from "react";
import { useSearchParams } from "next/navigation";

/**
 * Kartla ödeme sonucu (060, Apsiyon BUG-09). iyzico ödeme sayfasından dönen tarayıcı buraya
 * yönlendirilir. Herkese açıktır ve kişisel veri göstermez; sonuç sunucuda zaten kesinleşmiştir
 * (bu sayfa yalnızca bilgi verir, borç durumunu değiştirmez).
 */
function Result() {
    const q = useSearchParams();
    const status = q.get("status") ?? "PENDING";
    const message = q.get("message") ?? "";
    const tone = status === "COMPLETED" ? "border-green-200 bg-green-50 text-green-800"
        : status === "FAILED" ? "border-red-200 bg-red-50 text-red-800" : "border-amber-200 bg-amber-50 text-amber-900";
    const title = status === "COMPLETED" ? "Ödemeniz alındı" : status === "FAILED" ? "Ödeme tamamlanamadı" : "Ödemeniz işlemde";
    return (
        <div className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-lg">
            <h1 className="text-xl font-bold text-gray-900">{title}</h1>
            <div className={`mt-4 rounded-lg border p-4 text-sm ${tone}`}>
                {message || (status === "PENDING" ? "Banka sonucu bekleniyor; birkaç dakika içinde uygulamada görünecek." : "")}
            </div>
            <p className="mt-4 text-sm text-gray-600">
                {status === "FAILED"
                    ? "Kartınızdan tutar çekilmedi. Uygulamaya dönüp yeniden deneyebilirsiniz."
                    : "Uygulamaya dönebilirsiniz; ödeme durumu orada da güncellenir."}
            </p>
        </div>
    );
}

export default function PaymentResultPage() {
    return (
        <main className="flex min-h-screen items-center justify-center bg-gray-50 px-4 py-10">
            <Suspense fallback={null}>
                <Result />
            </Suspense>
        </main>
    );
}
