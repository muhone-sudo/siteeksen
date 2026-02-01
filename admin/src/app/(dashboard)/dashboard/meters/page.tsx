"use client";

import { useState } from "react";
import { Plus, Upload, Download, Thermometer, Droplets } from "lucide-react";

const mockMeters = [
    {
        id: 1,
        unit: "A-1",
        resident: "Ali Veli",
        meterType: "HEAT",
        serial: "ISI-A1-001",
        lastReading: 2450,
        currentReading: 0,
        lastDate: "2025-12-01",
    },
    {
        id: 2,
        unit: "A-2",
        resident: "Fatma Yılmaz",
        meterType: "HEAT",
        serial: "ISI-A2-001",
        lastReading: 3120,
        currentReading: 0,
        lastDate: "2025-12-01",
    },
    {
        id: 3,
        unit: "A-3",
        resident: "Ahmet Yılmaz",
        meterType: "HEAT",
        serial: "ISI-A3-001",
        lastReading: 3750,
        currentReading: 0,
        lastDate: "2026-01-01",
    },
    {
        id: 4,
        unit: "A-4",
        resident: "Mehmet Demir",
        meterType: "HEAT",
        serial: "ISI-A4-001",
        lastReading: 2890,
        currentReading: 0,
        lastDate: "2025-12-01",
    },
];

export default function MetersPage() {
    const [meterType, setMeterType] = useState<"HEAT" | "WATER">("HEAT");
    const [readings, setReadings] = useState<Record<number, number>>({});

    const handleReadingChange = (id: number, value: string) => {
        setReadings((prev) => ({
            ...prev,
            [id]: Number(value),
        }));
    };

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                        Sayaç Okuma
                    </h1>
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                        Aylık tüketim sayaç okumalarını girin
                    </p>
                </div>
                <div className="flex gap-3">
                    <button className="flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800">
                        <Upload className="h-4 w-4" />
                        Excel Yükle
                    </button>
                    <button className="flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800">
                        <Download className="h-4 w-4" />
                        Şablon İndir
                    </button>
                </div>
            </div>

            {/* Meter Type Tabs */}
            <div className="flex gap-2">
                <button
                    onClick={() => setMeterType("HEAT")}
                    className={`flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-medium transition-colors ${meterType === "HEAT"
                            ? "bg-primary text-white"
                            : "bg-white text-gray-700 hover:bg-gray-100 dark:bg-gray-800 dark:text-gray-300"
                        }`}
                >
                    <Thermometer className="h-4 w-4" />
                    Isı Sayaçları
                </button>
                <button
                    onClick={() => setMeterType("WATER")}
                    className={`flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-medium transition-colors ${meterType === "WATER"
                            ? "bg-primary text-white"
                            : "bg-white text-gray-700 hover:bg-gray-100 dark:bg-gray-800 dark:text-gray-300"
                        }`}
                >
                    <Droplets className="h-4 w-4" />
                    Su Sayaçları
                </button>
            </div>

            {/* Period Selection */}
            <div className="flex items-center gap-4 rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
                <label className="text-sm font-medium text-gray-700 dark:text-gray-300">
                    Okuma Dönemi:
                </label>
                <select className="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700">
                    <option>Ocak 2026</option>
                    <option>Aralık 2025</option>
                    <option>Kasım 2025</option>
                </select>
                <div className="ml-auto flex items-center gap-2 text-sm text-gray-500">
                    <span>Birim Fiyat:</span>
                    <span className="font-medium text-gray-900 dark:text-white">
                        ₺0,85 / kWh
                    </span>
                </div>
            </div>

            {/* Reading Table */}
            <div className="overflow-hidden rounded-xl bg-white shadow-sm dark:bg-gray-800">
                <table className="w-full">
                    <thead className="border-b border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-900">
                        <tr>
                            <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">
                                Daire
                            </th>
                            <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">
                                Sakin
                            </th>
                            <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">
                                Sayaç No
                            </th>
                            <th className="px-6 py-3 text-right text-xs font-medium uppercase text-gray-500">
                                Önceki Okuma
                            </th>
                            <th className="px-6 py-3 text-right text-xs font-medium uppercase text-gray-500">
                                Yeni Okuma
                            </th>
                            <th className="px-6 py-3 text-right text-xs font-medium uppercase text-gray-500">
                                Tüketim
                            </th>
                            <th className="px-6 py-3 text-right text-xs font-medium uppercase text-gray-500">
                                Tutar
                            </th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                        {mockMeters.map((meter) => {
                            const newReading = readings[meter.id] || 0;
                            const consumption = newReading > meter.lastReading ? newReading - meter.lastReading : 0;
                            const amount = consumption * 0.85;

                            return (
                                <tr key={meter.id}>
                                    <td className="px-6 py-4 font-medium text-gray-900 dark:text-white">
                                        {meter.unit}
                                    </td>
                                    <td className="px-6 py-4 text-gray-600 dark:text-gray-400">
                                        {meter.resident}
                                    </td>
                                    <td className="px-6 py-4 text-sm text-gray-500">
                                        {meter.serial}
                                    </td>
                                    <td className="px-6 py-4 text-right text-gray-900 dark:text-white">
                                        {meter.lastReading.toLocaleString()}
                                    </td>
                                    <td className="px-6 py-4">
                                        <input
                                            type="number"
                                            value={readings[meter.id] || ""}
                                            onChange={(e) =>
                                                handleReadingChange(meter.id, e.target.value)
                                            }
                                            placeholder="Girin..."
                                            className="w-28 rounded-lg border border-gray-300 px-3 py-2 text-right text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                                        />
                                    </td>
                                    <td className="px-6 py-4 text-right font-medium text-gray-900 dark:text-white">
                                        {consumption > 0 ? consumption.toLocaleString() : "-"}
                                    </td>
                                    <td className="px-6 py-4 text-right font-medium text-gray-900 dark:text-white">
                                        {consumption > 0 ? `₺${amount.toFixed(2)}` : "-"}
                                    </td>
                                </tr>
                            );
                        })}
                    </tbody>
                </table>
            </div>

            {/* Action Buttons */}
            <div className="flex justify-end gap-3">
                <button className="rounded-lg border border-gray-300 bg-white px-6 py-2 text-sm font-medium hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800">
                    İptal
                </button>
                <button className="rounded-lg bg-primary px-6 py-2 text-sm font-medium text-white hover:bg-primary/90">
                    Okumaları Kaydet
                </button>
            </div>
        </div>
    );
}
