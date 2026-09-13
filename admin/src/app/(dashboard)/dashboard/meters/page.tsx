"use client";

/**
 * Sayaç Okuma
 *
 * NEDEN YENİDEN YAZILDI (2026-09-13):
 * Sayfa tamamen yerel duruma dayanıyordu:
 *   - 4 sayaç ve sahip isimleri koda gömülüydü.
 *   - "Okumaları Kaydet" düğmesi yalnızca `useState` güncelliyor, sunucuya
 *     HİÇBİR istek göndermiyordu. Sayaç görevlisi turunu tamamlayıp kaydettiğini
 *     sanıyor, veriler sayfa yenilenince kayboluyordu. Isı payı bu okumalardan
 *     hesaplandığı için bu, doğrudan yanlış tahakkuk demektir.
 *   - Birim fiyatlar (0,85 kWh / 12 m³) koda gömülüydü; gerçek tarife
 *     `consumption_tariffs` tablosundadır.
 *
 * Artık sayaçlar API'den gelir ve okumalar `submitBulkReadings` ile sunucuya
 * gönderilir; sunucu kabul etmezse "kaydedildi" DENMEZ.
 *
 * NOT: iot-service henüz gerçek veri katmanına bağlı değildir ve 501 döner;
 * bu durumda ekran bunu açıkça bildirir.
 */

import { useCallback, useEffect, useState } from "react";
import { useSession } from "next-auth/react";
import { Thermometer, Droplets, Save } from "lucide-react";
import { apiClient } from "@/lib/api-client";
import {
    ErrorState,
    LoadingState,
    EmptyState,
    NotImplementedNotice,
    toUserMessage,
} from "@/components/ui/data-state";

interface Meter {
    id: string;
    unit_name?: string;
    unit_id?: string;
    meter_type: string;
    serial_number?: string;
    last_reading?: number;
    last_reading_date?: string;
}

const TYPE_TABS = [
    { id: "HEAT", label: "Isı", icon: Thermometer, unit: "kWh" },
    { id: "WATER_COLD", label: "Su", icon: Droplets, unit: "m³" },
];

export default function MetersPage() {
    const { data: session, status: authStatus } = useSession();

    const [meterType, setMeterType] = useState("HEAT");
    const [meters, setMeters] = useState<Meter[]>([]);
    const [readings, setReadings] = useState<Record<string, string>>({});
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [notImplemented, setNotImplemented] = useState(false);
    const [saving, setSaving] = useState(false);
    const [saveError, setSaveError] = useState<string | null>(null);
    const [saveOk, setSaveOk] = useState<number | null>(null);

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        setNotImplemented(false);
        setSaveOk(null);
        try {
            const res = await apiClient.getMeters({ type: meterType });
            const rows = Array.isArray(res) ? res : (res?.data ?? []);
            setMeters(rows as Meter[]);
            setReadings({});
        } catch (e) {
            const msg = toUserMessage(e, "Sayaçlar alınamadı");
            setNotImplemented(msg.includes("henüz"));
            setError(msg);
        } finally {
            setLoading(false);
        }
    }, [meterType]);

    useEffect(() => {
        if (authStatus !== "authenticated") return;
        if (session?.accessToken) {
            apiClient.setToken(session.accessToken, session.refreshToken);
        }
        void load();
    }, [authStatus, session, load]);

    const pending = Object.entries(readings).filter(([, v]) => v.trim() !== "");

    async function save() {
        if (pending.length === 0) return;
        setSaving(true);
        setSaveError(null);
        setSaveOk(null);
        try {
            const now = new Date();
            await apiClient.submitMeterReadings({
                period_year: now.getFullYear(),
                period_month: now.getMonth() + 1,
                readings: pending.map(([meterId, value]) => ({
                    meter_id: meterId,
                    value: Number(value),
                })),
            });
            setSaveOk(pending.length);
            await load();
        } catch (e) {
            // Sunucu kaydetmediyse "kaydedildi" DENMEZ; girilen değerler ekranda kalır.
            setSaveError(toUserMessage(e, "Okumalar kaydedilemedi"));
        } finally {
            setSaving(false);
        }
    }

    const activeTab = TYPE_TABS.find((t) => t.id === meterType) ?? TYPE_TABS[0];

    return (
        <div className="space-y-6">
            <div>
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Sayaç Okuma</h1>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                    Dönemlik sayaç okumalarının girilmesi
                </p>
            </div>

            <div className="flex gap-2">
                {TYPE_TABS.map((t) => (
                    <button
                        key={t.id}
                        onClick={() => setMeterType(t.id)}
                        className={`flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-medium ${
                            meterType === t.id
                                ? "bg-primary text-white"
                                : "border border-gray-300 text-gray-700 hover:bg-gray-50"
                        }`}
                    >
                        <t.icon className="h-4 w-4" />
                        {t.label}
                    </button>
                ))}
            </div>

            {saveError && (
                <div className="rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-700">
                    {saveError}
                </div>
            )}
            {saveOk !== null && (
                <div className="rounded-lg border border-green-200 bg-green-50 p-3 text-sm text-green-700">
                    {saveOk} okuma sunucuya kaydedildi.
                </div>
            )}

            {loading ? (
                <LoadingState />
            ) : notImplemented ? (
                <NotImplementedNotice detail="Sayaç modülü sunucu tarafında gerçek veri katmanına bağlanmadı. Okuma girişi şimdilik kaydedilemez." />
            ) : error ? (
                <ErrorState message={error} onRetry={load} />
            ) : meters.length === 0 ? (
                <EmptyState title={`Tanımlı ${activeTab.label.toLowerCase()} sayacı yok`} />
            ) : (
                <>
                    <div className="overflow-x-auto rounded-xl bg-white shadow-sm dark:bg-gray-800">
                        <table className="w-full text-sm">
                            <thead className="border-b border-gray-200 text-left text-xs uppercase text-gray-500">
                                <tr>
                                    <th className="px-4 py-3">Daire</th>
                                    <th className="px-4 py-3">Seri No</th>
                                    <th className="px-4 py-3">Önceki Okuma</th>
                                    <th className="px-4 py-3">Yeni Okuma ({activeTab.unit})</th>
                                </tr>
                            </thead>
                            <tbody>
                                {meters.map((m) => {
                                    const value = readings[m.id] ?? "";
                                    const invalid =
                                        value !== "" &&
                                        m.last_reading !== undefined &&
                                        Number(value) < m.last_reading;
                                    return (
                                        <tr key={m.id} className="border-b border-gray-100">
                                            <td className="px-4 py-3">{m.unit_name ?? m.unit_id ?? "—"}</td>
                                            <td className="px-4 py-3 text-gray-500">
                                                {m.serial_number ?? "—"}
                                            </td>
                                            <td className="px-4 py-3">
                                                {m.last_reading ?? "—"}
                                                {m.last_reading_date && (
                                                    <span className="ml-2 text-xs text-gray-400">
                                                        {new Date(m.last_reading_date).toLocaleDateString("tr-TR")}
                                                    </span>
                                                )}
                                            </td>
                                            <td className="px-4 py-3">
                                                <input
                                                    type="number"
                                                    value={value}
                                                    onChange={(e) =>
                                                        setReadings((p) => ({ ...p, [m.id]: e.target.value }))
                                                    }
                                                    className={`w-32 rounded-lg border px-3 py-1.5 ${
                                                        invalid ? "border-red-400" : "border-gray-300"
                                                    }`}
                                                />
                                                {invalid && (
                                                    <p className="mt-1 text-xs text-red-600">
                                                        Yeni okuma önceki okumadan küçük olamaz.
                                                    </p>
                                                )}
                                            </td>
                                        </tr>
                                    );
                                })}
                            </tbody>
                        </table>
                    </div>

                    <button
                        onClick={save}
                        disabled={saving || pending.length === 0}
                        className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white disabled:opacity-50"
                    >
                        <Save className="h-4 w-4" />
                        {saving ? "Kaydediliyor…" : `${pending.length} okumayı kaydet`}
                    </button>
                </>
            )}
        </div>
    );
}
