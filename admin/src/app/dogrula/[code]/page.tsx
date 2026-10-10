"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8888/api/v1";

type Result = {
    valid: boolean; expired?: boolean; property_name?: string; unit?: string; as_of_date?: string;
    expires_at?: string; statement?: string; error?: string;
};

function trDate(s?: string) {
    if (!s) return "—";
    const [y, m, d] = s.slice(0, 10).split("-");
    return `${d}.${m}.${y}`;
}

/**
 * Borcu yoktur belgesi doğrulama (Apsiyon BUG-04). Herkese açıktır: banka ya da tapu
 * memuru karekodu okutur. Sunucu yalnızca site adı, bölüm ve tarihleri döndürür.
 */
export default function VerifyClearancePage() {
    const params = useParams<{ code: string }>();
    const code = String(params?.code ?? "");
    const [res, setRes] = useState<Result | null>(null);

    useEffect(() => {
        let alive = true;
        fetch(`${API_BASE_URL}/public/clearance/${encodeURIComponent(code)}`)
            .then(async (r) => ({ ...(await r.json().catch(() => ({}))), httpOk: r.ok }))
            .then((j) => alive && setRes(j as Result))
            .catch(() => alive && setRes({ valid: false, error: "Doğrulama sunucusuna ulaşılamadı" }));
        return () => { alive = false; };
    }, [code]);

    return (
        <main className="flex min-h-screen items-center justify-center bg-gray-50 px-4 py-10">
            <div className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-lg">
                <h1 className="text-xl font-bold text-gray-900">Borcu yoktur belgesi doğrulama</h1>
                <p className="mt-1 break-all font-mono text-xs text-gray-500">{code}</p>
                {!res && <p className="mt-6 text-sm text-gray-600">Doğrulanıyor…</p>}
                {res && res.property_name && (
                    <div className={`mt-6 rounded-lg p-4 ${res.valid ? "bg-green-50 text-green-900" : "bg-amber-50 text-amber-900"}`}>
                        <p className="text-lg font-semibold">{res.valid ? "Belge geçerli" : "Belgenin geçerlilik süresi dolmuş"}</p>
                        <dl className="mt-3 grid grid-cols-3 gap-y-1 text-sm">
                            <dt className="text-gray-600">Site</dt><dd className="col-span-2 font-medium">{res.property_name}</dd>
                            <dt className="text-gray-600">Bölüm</dt><dd className="col-span-2 font-medium">{res.unit}</dd>
                            <dt className="text-gray-600">Belge tarihi</dt><dd className="col-span-2">{trDate(res.as_of_date)}</dd>
                            <dt className="text-gray-600">Geçerlilik</dt><dd className="col-span-2">{trDate(res.expires_at)}</dd>
                        </dl>
                        <p className="mt-3 text-sm">{res.statement}</p>
                        {!res.valid && <p className="mt-2 text-sm">Güncel durum için sakinden yeni belge isteyin.</p>}
                    </div>
                )}
                {res && !res.property_name && (
                    <div className="mt-6 rounded-lg bg-red-50 p-4 text-red-900">
                        <p className="font-semibold">Belge doğrulanamadı</p>
                        <p className="mt-1 text-sm">{res.error ?? "Bu kodla üretilmiş bir belge yok."}</p>
                    </div>
                )}
                <p className="mt-6 text-xs text-gray-400">Bu sayfa kişisel veri göstermez. SiteEksen</p>
            </div>
        </main>
    );
}
