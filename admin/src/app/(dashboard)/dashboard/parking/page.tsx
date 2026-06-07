"use client";

import { useState, useEffect, useRef } from "react";
import { Plus, X, Car, MapPin, Clock, LogOut, Loader2, Search, Edit, Trash2, Download, Upload } from "lucide-react";
import apiClient from "@/lib/api-client";

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
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingId, setEditingId] = useState<string | null>(null);
    const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);
    const [search, setSearch] = useState("");
    const csvRef = useRef<HTMLInputElement>(null);

    const [form, setForm] = useState({ plate: "", type: "car", owner_name: "", unit_number: "", zone_name: "" });

    useEffect(() => {
        apiClient.loadToken();
        load();
    }, []);

    async function load() {
        setLoading(true);
        try {
            const [vRes, cRes, sRes] = await Promise.all([apiClient.getVehicles(), apiClient.getCurrentVehicles(), apiClient.getParkingStats()]);
            setVehicles((vRes?.data ?? vRes ?? []).map((v: any) => ({ ...v, deleted: v.deleted ?? 0 })));
            setCurrentVehicles(cRes?.data ?? cRes ?? []);
            setStats(sRes);
        } catch {
            setVehicles([
                { id: "1", plate: "34 ABC 123", type: "car", owner_name: "Ahmet Yılmaz", unit_number: "A-12", zone_name: "A Blok Otoparkı", is_registered: true, deleted: 0 },
                { id: "2", plate: "34 XYZ 456", type: "car", owner_name: "Mehmet Demir", unit_number: "B-05", zone_name: "B Blok Otoparkı", is_registered: true, deleted: 0 },
                { id: "3", plate: "06 DEF 789", type: "motorcycle", owner_name: "Ayşe Kaya", unit_number: "C-08", zone_name: "Misafir", is_registered: false, deleted: 0 },
            ]);
            setCurrentVehicles([
                { id: "l1", plate: "34 ABC 123", owner_name: "Ahmet Yılmaz", zone_name: "A Blok", entry_time: new Date(Date.now() - 2 * 3600000).toISOString() },
                { id: "l2", plate: "34 XYZ 456", owner_name: "Mehmet Demir", zone_name: "B Blok", entry_time: new Date(Date.now() - 4 * 3600000).toISOString() },
            ]);
            setStats({ total_vehicles: 142, registered_vehicles: 128, unregistered_vehicles: 14, current_occupancy: 87, total_capacity: 150, occupancy_rate: 58 });
        } finally {
            setLoading(false);
        }
    }

    const openAdd = () => { setEditingId(null); setForm({ plate: "", type: "car", owner_name: "", unit_number: "", zone_name: "" }); setIsModalOpen(true); };
    const openEdit = (v: Vehicle) => { setEditingId(v.id); setForm({ plate: v.plate, type: v.type, owner_name: v.owner_name ?? "", unit_number: v.unit_number ?? "", zone_name: v.zone_name ?? "" }); setIsModalOpen(true); };

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        if (editingId) {
            setVehicles(prev => prev.map(v => v.id === editingId ? { ...v, ...form } : v));
        } else {
            try {
                const res = await apiClient.createVehicle(form);
                setVehicles(prev => [{ ...res, deleted: 0 }, ...prev]);
            } catch {
                setVehicles(prev => [{ id: String(Date.now()), ...form, is_registered: true, deleted: 0 }, ...prev]);
            }
        }
        setIsModalOpen(false); setEditingId(null);
    }

    const handleDelete = () => {
        if (!deleteConfirmId) return;
        setVehicles(prev => prev.map(v => v.id === deleteConfirmId ? { ...v, deleted: 1 } : v));
        setDeleteConfirmId(null);
    };

    async function handleExit(id: string) {
        try { await apiClient.checkOutVisitor(id); } catch {}
        setCurrentVehicles(prev => prev.filter(v => v.id !== id));
    }

    const downloadSampleCSV = () => {
        const blob = new Blob([SAMPLE_CSV], { type: "text/csv;charset=utf-8;" });
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a"); a.href = url; a.download = "arac_ornek.csv"; a.click();
        URL.revokeObjectURL(url);
    };

    const handleCSVUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0]; if (!file) return;
        const reader = new FileReader();
        reader.onload = (ev) => {
            const text = ev.target?.result as string;
            const lines = text.trim().split("\n").slice(1);
            const newItems: Vehicle[] = lines.map((line, i) => {
                const [plate, type, owner_name, unit_number, zone_name] = line.split(",");
                return { id: `csv_${Date.now()}_${i}`, plate: (plate ?? "").trim().toUpperCase(), type: (type ?? "car").trim(), owner_name: (owner_name ?? "").trim(), unit_number: (unit_number ?? "").trim(), zone_name: (zone_name ?? "").trim(), is_registered: true, deleted: 0 };
            });
            setVehicles(prev => [...newItems, ...prev]);
        };
        reader.readAsText(file);
        if (csvRef.current) csvRef.current.value = "";
    };

    const activeVehicles = vehicles.filter(v => v.deleted === 0);
    const filteredVehicles = activeVehicles.filter(v =>
        v.plate.toLowerCase().includes(search.toLowerCase()) ||
        (v.owner_name ?? "").toLowerCase().includes(search.toLowerCase())
    );

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
                        <input ref={csvRef} type="file" accept=".csv" className="hidden" onChange={handleCSVUpload} />
                    </label>
                    <button onClick={openAdd} className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90">
                        <Plus className="h-4 w-4" /> Araç Ekle
                    </button>
                </div>
            </div>

            <div className="grid gap-4 md:grid-cols-4">
                {[
                    { label: "Toplam Araç", value: String(stats?.total_vehicles ?? activeVehicles.length), color: "text-blue-600" },
                    { label: "Kayıtlı", value: String(stats?.registered_vehicles ?? activeVehicles.filter(v => v.is_registered).length), color: "text-green-600" },
                    { label: "Şu An İçeride", value: String(currentVehicles.length), color: "text-orange-600" },
                    { label: "Doluluk", value: `%${stats?.occupancy_rate ?? 0}`, color: "text-purple-600" },
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
                    <div className="flex items-center justify-center py-12"><Loader2 className="h-8 w-8 animate-spin text-primary" /></div>
                ) : activeTab === "current" ? (
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
                                        <button onClick={() => handleExit(v.id)} className="flex items-center gap-1 rounded-lg bg-orange-100 px-3 py-1 text-xs font-medium text-orange-700 hover:bg-orange-200 ml-auto">
                                            <LogOut className="h-3 w-3" /> Çıkış
                                        </button>
                                    </td>
                                </tr>
                            ))}
                            {currentVehicles.length === 0 && (
                                <tr><td colSpan={6} className="px-6 py-12 text-center text-gray-400">Şu an içeride araç yok</td></tr>
                            )}
                        </tbody>
                    </table>
                ) : (
                    <div>
                        <div className="p-4 border-b border-gray-200 dark:border-gray-700">
                            <div className="relative">
                                <Search className="absolute left-3 top-2.5 h-4 w-4 text-gray-400" />
                                <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Plaka veya isim ara..."
                                    className="w-full rounded-lg border border-gray-300 pl-9 pr-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                            </div>
                        </div>
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
                                {filteredVehicles.length === 0 && (
                                    <tr><td colSpan={7} className="px-6 py-12 text-center text-gray-400">Araç bulunamadı</td></tr>
                                )}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            {/* Add/Edit Modal */}
            {isModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">{editingId ? "Aracı Düzenle" : "Araç Ekle"}</h2>
                            <button onClick={() => { setIsModalOpen(false); setEditingId(null); }}><X className="h-5 w-5 text-gray-500" /></button>
                        </div>
                        <form onSubmit={handleSubmit} className="space-y-4">
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
                                <button type="button" onClick={() => { setIsModalOpen(false); setEditingId(null); }} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">İptal</button>
                                <button type="submit" className="flex-1 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90">{editingId ? "Güncelle" : "Ekle"}</button>
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
                            <button onClick={handleDelete} className="flex-1 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700">Sil</button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
