"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import { Plus, X, MapPin, Clock, LogOut, Search, Edit, Trash2, Download, Upload } from "lucide-react";
import apiClient from "@/lib/api-client";
import { ErrorState, LoadingState, EmptyState, toUserMessage, NotImplementedNotice } from "@/components/ui/data-state";

interface Vehicle {
    id: string;
    plate: string;
    type: string;
    owner_name?: string;
    unit_number?: string;
    zone_name?: string;
    is_registered: boolean;
    deleted: number;
}

interface ParkingLog {
    id: string;
    plate: string;
    vehicle_id?: string;
    zone_name?: string;
    entry_time: string;
    exit_time?: string;
    duration?: string;
    owner_name?: string;
}

interface ParkingStats {
    total_vehicles: number;
    registered_vehicles: number;
    unregistered_vehicles: number;
    current_occupancy: number;
    total_capacity: number;
    occupancy_rate: number;
}

const vehicleTypes: Record<string, string> = {
    car: "Otomobil",
    motorcycle: "Motosiklet",
    truck: "Kamyonet",
    bicycle: "Bisiklet",
};

const SAMPLE_CSV = `plate,type,owner_name,unit_number,zone_name
34 ABC 100,car,Ali Yılmaz,A-01,A Blok
34 DEF 200,motorcycle,Veli Kaya,B-03,B Blok
06 GHI 300,car,Ayşe Demir,C-07,Misafir`;

export default function ParkingPage() {
    const [activeTab, setActiveTab] = useState<"current" | "vehicles">("current");
    const [vehicles, setVehicles] = useState<Vehicle[]>([]);
    const [currentVehicles, setCurrentVehicles] = useState<ParkingLog[]>([]);
    const [stats, setStats] = useState<ParkingStats | null>(null);
    const [loading, setLoading] = useState(true);
    const [loadError, setLoadError] = useState<string | null>(null);
    const [actionError, setActionError] = useState<string | null>(null);
    const [formError, setFormError] = useState<string | null>(null);
    const [submitting, setSubmitting] = useState(false);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingId, setEditingId] = useState<string | null>(null);
    const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);
    const [search, setSearch] = useState("");
    const csvRef = useRef<HTMLInputElement>(null);

    const [form, setForm] = useState({ plate: "", type: "car", owner_name: "", unit_number: "", zone_name: "" });

    const load = useCallback(async () => {
        setLoading(true);
        try {
            const [vRes, cRes, sRes] = await Promise.all([apiClient.getVehicles(), apiClient.getCurrentVehicles(), apiClient.getParkingStats()]);
            setVehicles((vRes?.data ?? vRes ?? []).map((v: any) => ({ ...v, deleted: v.deleted ?? 0 })));
            setCurrentVehicles(cRes?.data ?? cRes ?? []);
            setStats(sRes ?? null);
            setLoadError(null);
        } catch (err) {
            setVehicles([]);
            setCurrentVehicles([]);
            setStats(null);
            setLoadError(toUserMessage(err));
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        apiClient.loadToken();
        load();
    }, [load]);

    const openAdd = () => { setEditingId(null); setFormError(null); setForm({ plate: "", type: "car", owner_name: "", unit_number: "", zone_name: "" }); setIsModalOpen(true); };
    const openEdit = (v: Vehicle) => { setEditingId(v.id); setFormError(null); setForm({ plate: v.plate, type: v.type, owner_name: v.owner_name ?? "", unit_number: v.unit_number ?? "", zone_name: v.zone_name ?? "" }); setIsModalOpen(true); };
    const closeModal = () => { setIsModalOpen(false); setEditingId(null); setFormError(null); };

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        setFormError(null);

        if (editingId) {
            // apiClient içinde araç güncelleme uç noktası yok; sahte başarı göstermek yerine durumu bildiriyoruz.
            setFormError("Araç güncelleme özelliği sunucu tarafında henüz hazır değil. Değişiklik kaydedilmedi.");
            return;
        }

        setSubmitting(true);
        try {
            await apiClient.createVehicle(form);
            closeModal();
            await load();
        } catch (err) {
            setFormError(toUserMessage(err, "Araç kaydı oluşturulamadı."));
        } finally {
            setSubmitting(false);
        }
    }

    async function handleDelete() {
        if (!deleteConfirmId) return;
        const id = deleteConfirmId;
        setActionError(null);
        setSubmitting(true);
        try {
            await apiClient.deleteVehicle(id);
            setDeleteConfirmId(null);
            await load();
        } catch (err) {
            setDeleteConfirmId(null);
            setActionError(toUserMessage(err, "Araç kaydı silinemedi."));
        } finally {
            setSubmitting(false);
        }
    }

    const handleExit = () => {
        // apiClient içinde otopark çıkış uç noktası yok (yalnızca /parking-logs/entry mevcut).
        // Aracı listeden düşürmek çıkışın kaydedildiği izlenimi verir; bu yüzden durumu bildiriyoruz.
        setActionError("Otopark çıkış kaydı özelliği sunucu tarafında henüz hazır değil. Çıkış kaydedilmedi.");
    };

    const downloadSampleCSV = () => {
        const blob = new Blob([SAMPLE_CSV], { type: "text/csv;charset=utf-8;" });
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a"); a.href = url; a.download = "arac_ornek.csv"; a.click();
        URL.revokeObjectURL(url);
    };

    const handleCSVUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0]; if (!file) return;
        const reader = new FileReader();
        reader.onload = async (ev) => {
            const text = ev.target?.result as string;
            const lines = text.trim().split("\n").slice(1).filter(l => l.trim() !== "");
            if (lines.length === 0) return;

            setActionError(null);
            setSubmitting(true);
            let firstError: unknown = null;
            let failed = 0;

            for (const line of lines) {
                const [plate, type, owner_name, unit_number, zone_name] = line.split(",");
                const payload = {
                    plate: (plate ?? "").trim().toUpperCase(),
                    type: (type ?? "car").trim(),
                    owner_name: (owner_name ?? "").trim(),
                    unit_number: (unit_number ?? "").trim(),
                    zone_name: (zone_name ?? "").trim(),
                };
                try {
                    await apiClient.createVehicle(payload);
                } catch (err) {
                    failed++;
                    if (firstError === null) firstError = err;
                }
            }

            setSubmitting(false);
            if (failed > 0) {
                setActionError(`${lines.length} satırdan ${failed} tanesi kaydedilemedi: ${toUserMessage(firstError, "Araç kaydı oluşturulamadı.")}`);
            }
            await load();
        };
        reader.readAsText(file);
        if (csvRef.current) csvRef.current.value = "";
    };

    const activeVehicles = vehicles.filter(v => v.deleted === 0);
    const filteredVehicles = activeVehicles.filter(v =>
        v.plate.toLowerCase().includes(search.toLowerCase()) ||
        (v.owner_name ?? "").toLowerCase().includes(search.toLowerCase())
    );
    const hasData = !loading && !loadError;

    const elapsed = (entry: string) => {
        const mins = Math.floor((Date.now() - new Date(entry).getTime()) / 60000);
        return mins < 60 ? `${mins}dk` : `${Math.floor(mins / 60)}sa ${mins % 60}dk`;
    };

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Otopark Yönetimi</h1>
                    <p className="text-sm text-gray-500">Araç takibi ve otopark doluluk durumu</p>
                </div>
                <div className="flex items-center gap-2">
                    <button onClick={downloadSampleCSV} className="flex items-center gap-2 rounded-lg border border-gray-300 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">
                        <Download className="h-4 w-4" /> Örnek CSV
                    </button>
                    <label className="flex items-center gap-2 rounded-lg border border-gray-300 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 cursor-pointer">
                        <Upload className="h-4 w-4" /> CSV Yükle
                        <input ref={csvRef} type="file" accept=".csv" className="hidden" onChange={handleCSVUpload} disabled={submitting} />
                    </label>
                    <button onClick={openAdd} className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90">
                        <Plus className="h-4 w-4" /> Araç Ekle
                    </button>
                </div>
            </div>

            <NotImplementedNotice />

            {actionError && (
                <div role="alert" className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                    {actionError}
                </div>
            )}

            <div className="grid gap-4 md:grid-cols-4">
                {[
                    { label: "Toplam Araç", value: hasData ? String(stats?.total_vehicles ?? activeVehicles.length) : "—", color: "text-blue-600" },
                    { label: "Kayıtlı", value: hasData ? String(stats?.registered_vehicles ?? activeVehicles.filter(v => v.is_registered).length) : "—", color: "text-green-600" },
                    { label: "Şu An İçeride", value: hasData ? String(currentVehicles.length) : "—", color: "text-orange-600" },
                    { label: "Doluluk", value: hasData && stats ? `%${stats.occupancy_rate}` : "—", color: "text-purple-600" },
                ].map(s => (
                    <div key={s.label} className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
                        <p className="text-sm text-gray-500">{s.label}</p>
                        <p className={`mt-1 text-2xl font-bold ${s.color}`}>{s.value}</p>
                    </div>
                ))}
            </div>

            <div className="flex gap-2 border-b border-gray-200 dark:border-gray-700">
                {[{ id: "current", label: "Şu An İçeride" }, { id: "vehicles", label: "Kayıtlı Araçlar" }].map(t => (
                    <button key={t.id} onClick={() => setActiveTab(t.id as typeof activeTab)}
                        className={`px-4 py-3 text-sm font-medium border-b-2 transition-colors ${activeTab === t.id ? "border-primary text-primary" : "border-transparent text-gray-500 hover:text-gray-700"}`}>
                        {t.label}
                    </button>
                ))}
            </div>

            <div className="rounded-xl bg-white shadow-sm dark:bg-gray-800">
                {loading ? (
                    <LoadingState />
                ) : loadError ? (
                    <ErrorState message={loadError} onRetry={load} />
                ) : activeTab === "current" ? (
                    currentVehicles.length === 0 ? (
                        <EmptyState title="Şu an içeride araç yok" />
                    ) : (
                        <table className="w-full">
                            <thead>
                                <tr className="border-b border-gray-200 dark:border-gray-700">
                                    <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Plaka</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Sahip</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Bölge</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Giriş</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Süre</th>
                                    <th className="px-6 py-3 text-right text-xs font-medium uppercase text-gray-500">İşlem</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                                {currentVehicles.map(v => (
                                    <tr key={v.id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50">
                                        <td className="px-6 py-4"><span className="flex items-center gap-2 font-mono font-bold text-sm">{v.plate}</span></td>
                                        <td className="px-6 py-4 text-sm text-gray-700 dark:text-gray-300">{v.owner_name ?? "—"}</td>
                                        <td className="px-6 py-4 text-sm"><span className="flex items-center gap-1 text-gray-500"><MapPin className="h-3 w-3" />{v.zone_name ?? "—"}</span></td>
                                        <td className="px-6 py-4 text-sm text-gray-500"><span className="flex items-center gap-1"><Clock className="h-3 w-3" />{new Date(v.entry_time).toLocaleTimeString("tr-TR", { hour: "2-digit", minute: "2-digit" })}</span></td>
                                        <td className="px-6 py-4 text-sm font-medium text-blue-600">{elapsed(v.entry_time)}</td>
                                        <td className="px-6 py-4 text-right">
                                            <button onClick={handleExit} className="flex items-center gap-1 rounded-lg bg-orange-100 px-3 py-1 text-xs font-medium text-orange-700 hover:bg-orange-200 ml-auto">
                                                <LogOut className="h-3 w-3" /> Çıkış
                                            </button>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    )
                ) : (
                    <div>
                        <div className="p-4 border-b border-gray-200 dark:border-gray-700">
                            <div className="relative">
                                <Search className="absolute left-3 top-2.5 h-4 w-4 text-gray-400" />
                                <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Plaka veya isim ara..."
                                    className="w-full rounded-lg border border-gray-300 pl-9 pr-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                            </div>
                        </div>
                        {filteredVehicles.length === 0 ? (
                            <EmptyState title="Araç bulunamadı" />
                        ) : (
                            <table className="w-full">
                                <thead>
                                    <tr className="border-b border-gray-200 dark:border-gray-700">
                                        <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Plaka</th>
                                        <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Tür</th>
                                        <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Sakin</th>
                                        <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Daire</th>
                                        <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Bölge</th>
                                        <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Durum</th>
                                        <th className="px-6 py-3 text-right text-xs font-medium uppercase text-gray-500">İşlem</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                                    {filteredVehicles.map(v => (
                                        <tr key={v.id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50">
                                            <td className="px-6 py-4 font-mono font-bold text-sm">{v.plate}</td>
                                            <td className="px-6 py-4 text-sm text-gray-500">{vehicleTypes[v.type] ?? v.type}</td>
                                            <td className="px-6 py-4 text-sm text-gray-700 dark:text-gray-300">{v.owner_name ?? "—"}</td>
                                            <td className="px-6 py-4 text-sm text-gray-500">{v.unit_number ?? "—"}</td>
                                            <td className="px-6 py-4 text-sm text-gray-500">{v.zone_name ?? "—"}</td>
                                            <td className="px-6 py-4">
                                                <span className={`rounded-full px-2 py-1 text-xs font-medium ${v.is_registered ? "bg-green-100 text-green-700" : "bg-gray-100 text-gray-600"}`}>
                                                    {v.is_registered ? "Kayıtlı" : "Misafir"}
                                                </span>
                                            </td>
                                            <td className="px-6 py-4 text-right">
                                                <div className="flex justify-end gap-1">
                                                    <button onClick={() => openEdit(v)} className="p-1.5 rounded hover:bg-blue-100 text-blue-500"><Edit className="h-4 w-4" /></button>
                                                    <button onClick={() => setDeleteConfirmId(v.id)} className="p-1.5 rounded hover:bg-red-100 text-red-500"><Trash2 className="h-4 w-4" /></button>
                                                </div>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        )}
                    </div>
                )}
            </div>

            {/* Add/Edit Modal */}
            {isModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">{editingId ? "Aracı Düzenle" : "Araç Ekle"}</h2>
                            <button onClick={closeModal}><X className="h-5 w-5 text-gray-500" /></button>
                        </div>
                        <form onSubmit={handleSubmit} className="space-y-4">
                            {formError && (
                                <div role="alert" className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                                    {formError}
                                </div>
                            )}
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Plaka</label>
                                <input required value={form.plate} onChange={e => setForm({ ...form, plate: e.target.value.toUpperCase() })} placeholder="34 ABC 123"
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm font-mono dark:border-gray-600 dark:bg-gray-700" />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Tür</label>
                                    <select value={form.type} onChange={e => setForm({ ...form, type: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700">
                                        <option value="car">Otomobil</option>
                                        <option value="motorcycle">Motosiklet</option>
                                        <option value="truck">Kamyonet</option>
                                        <option value="bicycle">Bisiklet</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Daire No</label>
                                    <input value={form.unit_number} onChange={e => setForm({ ...form, unit_number: e.target.value })} placeholder="A-12"
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Araç Sahibi</label>
                                <input value={form.owner_name} onChange={e => setForm({ ...form, owner_name: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Park Bölgesi</label>
                                <input value={form.zone_name} onChange={e => setForm({ ...form, zone_name: e.target.value })} placeholder="A Blok Otoparkı"
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                            </div>
                            <div className="flex gap-3 pt-2">
                                <button type="button" onClick={closeModal} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">İptal</button>
                                <button type="submit" disabled={submitting} className="flex-1 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90 disabled:opacity-50">{submitting ? "Kaydediliyor..." : editingId ? "Güncelle" : "Ekle"}</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Delete Confirm */}
            {deleteConfirmId && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-sm rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800 text-center">
                        <div className="flex justify-center mb-4"><div className="rounded-full bg-red-100 p-3"><Trash2 className="h-6 w-6 text-red-600" /></div></div>
                        <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-2">Aracı Sil</h2>
                        <p className="text-gray-500 text-sm mb-6">Bu araç kaydı silinecek. Emin misiniz?</p>
                        <div className="flex gap-3">
                            <button onClick={() => setDeleteConfirmId(null)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">İptal</button>
                            <button onClick={handleDelete} disabled={submitting} className="flex-1 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-50">{submitting ? "Siliniyor..." : "Sil"}</button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
