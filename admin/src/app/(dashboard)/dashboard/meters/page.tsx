"use client";

import { useState, useRef } from "react";
import { Plus, Upload, Download, Thermometer, Droplets, Edit, Trash2, X, Check } from "lucide-react";

interface Meter {
    id: number;
    unit: string;
    resident: string;
    meterType: "HEAT" | "WATER";
    serial: string;
    lastReading: number;
    currentReading: number;
    lastDate: string;
    deleted: number;
}

const initialMeters: Meter[] = [
    { id: 1, unit: "A-1", resident: "Ali Veli", meterType: "HEAT", serial: "ISI-A1-001", lastReading: 2450, currentReading: 0, lastDate: "2025-12-01", deleted: 0 },
    { id: 2, unit: "A-2", resident: "Fatma Yılmaz", meterType: "HEAT", serial: "ISI-A2-001", lastReading: 3120, currentReading: 0, lastDate: "2025-12-01", deleted: 0 },
    { id: 3, unit: "A-3", resident: "Ahmet Yılmaz", meterType: "HEAT", serial: "ISI-A3-001", lastReading: 3750, currentReading: 0, lastDate: "2026-01-01", deleted: 0 },
    { id: 4, unit: "A-4", resident: "Mehmet Demir", meterType: "HEAT", serial: "ISI-A4-001", lastReading: 2890, currentReading: 0, lastDate: "2025-12-01", deleted: 0 },
];

const SAMPLE_CSV = `unit,resident,meterType,serial,lastReading,lastDate
A-5,Ayşe Kaya,HEAT,ISI-A5-001,3100,2026-01-01
B-1,Hasan Demir,WATER,SU-B1-001,1500,2026-01-01
B-2,Zeynep Şahin,HEAT,ISI-B2-001,2750,2025-12-01`;

const unitPrice = { HEAT: 0.85, WATER: 12 };
const unitLabel = { HEAT: "kWh", WATER: "m³" };

export default function MetersPage() {
    const [meterType, setMeterType] = useState<"HEAT" | "WATER">("HEAT");
    const [selectedPeriod, setSelectedPeriod] = useState("Ocak 2026");
    const [meters, setMeters] = useState<Meter[]>(initialMeters);
    const [readings, setReadings] = useState<Record<number, number>>({});
    const [editingMeter, setEditingMeter] = useState<Meter | null>(null);
    const [deleteConfirmId, setDeleteConfirmId] = useState<number | null>(null);
    const [isAddModalOpen, setIsAddModalOpen] = useState(false);
    const [savedReadings, setSavedReadings] = useState<Record<number, boolean>>({});
    const csvRef = useRef<HTMLInputElement>(null);

    const [form, setForm] = useState({ unit: "", resident: "", serial: "", lastReading: 0, lastDate: new Date().toISOString().split("T")[0] });

    const handleReadingChange = (id: number, value: string) => {
        setReadings(prev => ({ ...prev, [id]: Number(value) }));
        setSavedReadings(prev => { const n = { ...prev }; delete n[id]; return n; });
    };

    const saveReadings = () => {
        const saved: Record<number, boolean> = {};
        const updated = meters.map(m => {
            const newReading = readings[m.id];
            if (newReading && newReading > m.lastReading) {
                saved[m.id] = true;
                return { ...m, lastReading: newReading, currentReading: newReading, lastDate: new Date().toISOString().split("T")[0] };
            }
            return m;
        });
        setMeters(updated);
        setSavedReadings(saved);
        setReadings({});
    };

    const openEdit = (m: Meter) => setEditingMeter({ ...m });

    const handleEditSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        if (!editingMeter) return;
        setMeters(prev => prev.map(m => m.id === editingMeter.id ? editingMeter : m));
        setEditingMeter(null);
    };

    const handleDelete = () => {
        if (deleteConfirmId === null) return;
        setMeters(prev => prev.map(m => m.id === deleteConfirmId ? { ...m, deleted: 1 } : m));
        setDeleteConfirmId(null);
    };

    const handleAddMeter = (e: React.FormEvent) => {
        e.preventDefault();
        setMeters(prev => [...prev, { id: Date.now(), ...form, meterType, currentReading: 0, deleted: 0 }]);
        setForm({ unit: "", resident: "", serial: "", lastReading: 0, lastDate: new Date().toISOString().split("T")[0] });
        setIsAddModalOpen(false);
    };

    const downloadTemplate = () => {
        const blob = new Blob([SAMPLE_CSV], { type: "text/csv;charset=utf-8;" });
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a"); a.href = url; a.download = "sayac_sablon.csv"; a.click();
        URL.revokeObjectURL(url);
    };

    const handleCSVUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0]; if (!file) return;
        const reader = new FileReader();
        reader.onload = (ev) => {
            const text = ev.target?.result as string;
            const lines = text.trim().split("\n").slice(1);
            const newMeters: Meter[] = lines.map((line, i) => {
                const [unit, resident, type, serial, lastReading, lastDate] = line.split(",");
                return {
                    id: Date.now() + i,
                    unit: (unit ?? "").trim(),
                    resident: (resident ?? "").trim(),
                    meterType: ((type ?? "HEAT").trim().toUpperCase() === "WATER" ? "WATER" : "HEAT") as "HEAT" | "WATER",
                    serial: (serial ?? "").trim(),
                    lastReading: parseFloat((lastReading ?? "0").trim()) || 0,
                    currentReading: 0,
                    lastDate: (lastDate ?? "").trim(),
                    deleted: 0,
                };
            });
            setMeters(prev => [...newMeters, ...prev]);
        };
        reader.readAsText(file);
        if (csvRef.current) csvRef.current.value = "";
    };

    const price = unitPrice[meterType];
    const label = unitLabel[meterType];
    const activeMeters = meters.filter(m => m.deleted === 0 && m.meterType === meterType);

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Sayaç Okuma</h1>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Aylık tüketim sayaç okumalarını girin</p>
                </div>
                <div className="flex gap-2">
                    <button onClick={downloadTemplate} className="flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800">
                        <Download className="h-4 w-4" /> Şablon İndir
                    </button>
                    <label className="flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 cursor-pointer">
                        <Upload className="h-4 w-4" /> CSV Yükle
                        <input ref={csvRef} type="file" accept=".csv" className="hidden" onChange={handleCSVUpload} />
                    </label>
                    <button onClick={() => setIsAddModalOpen(true)} className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90">
                        <Plus className="h-4 w-4" /> Sayaç Ekle
                    </button>
                </div>
            </div>

            <div className="flex gap-2">
                <button onClick={() => setMeterType("HEAT")}
                    className={`flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-medium transition-colors ${meterType === "HEAT" ? "bg-primary text-white" : "bg-white text-gray-700 hover:bg-gray-100 dark:bg-gray-800 dark:text-gray-300"}`}>
                    <Thermometer className="h-4 w-4" /> Isı Sayaçları
                </button>
                <button onClick={() => setMeterType("WATER")}
                    className={`flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-medium transition-colors ${meterType === "WATER" ? "bg-primary text-white" : "bg-white text-gray-700 hover:bg-gray-100 dark:bg-gray-800 dark:text-gray-300"}`}>
                    <Droplets className="h-4 w-4" /> Su Sayaçları
                </button>
            </div>

            <div className="flex items-center gap-4 rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
                <label className="text-sm font-medium text-gray-700 dark:text-gray-300">Okuma Dönemi:</label>
                <select value={selectedPeriod} onChange={(e) => setSelectedPeriod(e.target.value)} className="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700">
                    <option>Ocak 2026</option>
                    <option>Aralık 2025</option>
                    <option>Kasım 2025</option>
                </select>
                <div className="ml-auto flex items-center gap-2 text-sm text-gray-500">
                    <span>Birim Fiyat:</span>
                    <span className="font-medium text-gray-900 dark:text-white">₺{price.toFixed(2)} / {label}</span>
                </div>
            </div>

            <div className="overflow-hidden rounded-xl bg-white shadow-sm dark:bg-gray-800">
                <table className="w-full">
                    <thead className="border-b border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-900">
                        <tr>
                            <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Daire</th>
                            <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Sakin</th>
                            <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Sayaç No</th>
                            <th className="px-6 py-3 text-right text-xs font-medium uppercase text-gray-500">Önceki Okuma</th>
                            <th className="px-6 py-3 text-right text-xs font-medium uppercase text-gray-500">Yeni Okuma</th>
                            <th className="px-6 py-3 text-right text-xs font-medium uppercase text-gray-500">Tüketim</th>
                            <th className="px-6 py-3 text-right text-xs font-medium uppercase text-gray-500">Tutar</th>
                            <th className="px-6 py-3 text-right text-xs font-medium uppercase text-gray-500">İşlem</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                        {activeMeters.map((meter) => {
                            const newReading = readings[meter.id] || 0;
                            const consumption = newReading > meter.lastReading ? newReading - meter.lastReading : 0;
                            const amount = consumption * price;
                            const isSaved = savedReadings[meter.id];
                            return (
                                <tr key={meter.id} className={isSaved ? "bg-green-50 dark:bg-green-900/10" : ""}>
                                    <td className="px-6 py-4 font-medium text-gray-900 dark:text-white">{meter.unit}</td>
                                    <td className="px-6 py-4 text-gray-600 dark:text-gray-400">{meter.resident}</td>
                                    <td className="px-6 py-4 text-sm text-gray-500">{meter.serial}</td>
                                    <td className="px-6 py-4 text-right text-gray-900 dark:text-white">{meter.lastReading.toLocaleString()}</td>
                                    <td className="px-6 py-4">
                                        <input type="number" value={readings[meter.id] || ""} onChange={(e) => handleReadingChange(meter.id, e.target.value)}
                                            placeholder="Girin..." className="w-28 rounded-lg border border-gray-300 px-3 py-2 text-right text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700 ml-auto block" />
                                    </td>
                                    <td className="px-6 py-4 text-right font-medium text-gray-900 dark:text-white">
                                        {consumption > 0 ? `${consumption.toLocaleString()} ${label}` : isSaved ? <Check className="h-4 w-4 text-green-500 ml-auto" /> : "—"}
                                    </td>
                                    <td className="px-6 py-4 text-right font-medium text-gray-900 dark:text-white">
                                        {consumption > 0 ? `₺${amount.toFixed(2)}` : "—"}
                                    </td>
                                    <td className="px-6 py-4 text-right">
                                        <div className="flex justify-end gap-1">
                                            <button onClick={() => openEdit(meter)} className="p-1.5 rounded hover:bg-blue-100 text-blue-500"><Edit className="h-4 w-4" /></button>
                                            <button onClick={() => setDeleteConfirmId(meter.id)} className="p-1.5 rounded hover:bg-red-100 text-red-500"><Trash2 className="h-4 w-4" /></button>
                                        </div>
                                    </td>
                                </tr>
                            );
                        })}
                        {activeMeters.length === 0 && (
                            <tr><td colSpan={8} className="px-6 py-12 text-center text-gray-400">Bu türde sayaç bulunamadı</td></tr>
                        )}
                    </tbody>
                </table>
            </div>

            <div className="flex justify-end gap-3">
                <button onClick={() => { setReadings({}); setSavedReadings({}); }} className="rounded-lg border border-gray-300 bg-white px-6 py-2 text-sm font-medium hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800">İptal</button>
                <button onClick={saveReadings} className="rounded-lg bg-primary px-6 py-2 text-sm font-medium text-white hover:bg-primary/90">Okumaları Kaydet</button>
            </div>

            {/* Add Meter Modal */}
            {isAddModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">Sayaç Ekle</h2>
                            <button onClick={() => setIsAddModalOpen(false)}><X className="h-5 w-5 text-gray-500" /></button>
                        </div>
                        <form onSubmit={handleAddMeter} className="space-y-4">
                            <div className="grid grid-cols-2 gap-4">
                                <div><label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Daire</label><input required value={form.unit} onChange={e => setForm({ ...form, unit: e.target.value })} placeholder="A-5" className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" /></div>
                                <div><label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Sakin</label><input required value={form.resident} onChange={e => setForm({ ...form, resident: e.target.value })} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" /></div>
                            </div>
                            <div><label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Sayaç Seri No</label><input required value={form.serial} onChange={e => setForm({ ...form, serial: e.target.value })} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" /></div>
                            <div className="grid grid-cols-2 gap-4">
                                <div><label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">İlk Okuma</label><input type="number" value={form.lastReading || ""} onChange={e => setForm({ ...form, lastReading: Number(e.target.value) })} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" /></div>
                                <div><label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Okuma Tarihi</label><input type="date" value={form.lastDate} onChange={e => setForm({ ...form, lastDate: e.target.value })} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" /></div>
                            </div>
                            <div className="flex gap-3 pt-2">
                                <button type="button" onClick={() => setIsAddModalOpen(false)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">İptal</button>
                                <button type="submit" className="flex-1 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90">Ekle</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Edit Meter Modal */}
            {editingMeter && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">Sayacı Düzenle</h2>
                            <button onClick={() => setEditingMeter(null)}><X className="h-5 w-5 text-gray-500" /></button>
                        </div>
                        <form onSubmit={handleEditSubmit} className="space-y-4">
                            <div className="grid grid-cols-2 gap-4">
                                <div><label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Daire</label><input required value={editingMeter.unit} onChange={e => setEditingMeter({ ...editingMeter, unit: e.target.value })} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" /></div>
                                <div><label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Sakin</label><input required value={editingMeter.resident} onChange={e => setEditingMeter({ ...editingMeter, resident: e.target.value })} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" /></div>
                            </div>
                            <div><label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Sayaç Seri No</label><input required value={editingMeter.serial} onChange={e => setEditingMeter({ ...editingMeter, serial: e.target.value })} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" /></div>
                            <div><label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Son Okuma</label><input type="number" value={editingMeter.lastReading} onChange={e => setEditingMeter({ ...editingMeter, lastReading: Number(e.target.value) })} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" /></div>
                            <div className="flex gap-3 pt-2">
                                <button type="button" onClick={() => setEditingMeter(null)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">İptal</button>
                                <button type="submit" className="flex-1 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90">Güncelle</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Delete Confirm */}
            {deleteConfirmId !== null && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-sm rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800 text-center">
                        <div className="flex justify-center mb-4"><div className="rounded-full bg-red-100 p-3"><Trash2 className="h-6 w-6 text-red-600" /></div></div>
                        <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-2">Sayacı Sil</h2>
                        <p className="text-gray-500 text-sm mb-6">Bu sayaç kaydı silinecek. Emin misiniz?</p>
                        <div className="flex gap-3">
                            <button onClick={() => setDeleteConfirmId(null)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">İptal</button>
                            <button onClick={handleDelete} className="flex-1 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700">Sil</button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
