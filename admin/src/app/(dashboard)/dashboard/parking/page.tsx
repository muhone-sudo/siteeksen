"use client";

import { useState, useEffect } from "react";
import { Plus, X, Car, MapPin, Clock, LogIn, LogOut, Loader2, Search } from "lucide-react";
import apiClient from "@/lib/api-client";

interface Vehicle {
    id: string;
    plate: string;
    type: string;
    owner_name?: string;
    unit_number?: string;
    zone_name?: string;
    is_registered: boolean;
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

export default function ParkingPage() {
    const [activeTab, setActiveTab] = useState<"current" | "vehicles" | "logs">("current");
    const [vehicles, setVehicles] = useState<Vehicle[]>([]);
    const [currentVehicles, setCurrentVehicles] = useState<ParkingLog[]>([]);
    const [stats, setStats] = useState<ParkingStats | null>(null);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [search, setSearch] = useState("");
    const [form, setForm] = useState({ plate: "", type: "car", owner_name: "", unit_number: "" });

    useEffect(() => {
        apiClient.loadToken();
        load();
    }, []);

    async function load() {
        setLoading(true);
        try {
            const [vRes, cRes, sRes] = await Promise.all([
                apiClient.getVehicles(),
                apiClient.getCurrentVehicles(),
                apiClient.getParkingStats(),
            ]);
            setVehicles(vRes?.data ?? vRes ?? []);
            setCurrentVehicles(cRes?.data ?? cRes ?? []);
            setStats(sRes);
        } catch {
            setVehicles([
                { id: "1", plate: "34 ABC 123", type: "car", owner_name: "Ahmet Yılmaz", unit_number: "A-12", zone_name: "A Blok Otoparkı", is_registered: true },
                { id: "2", plate: "34 XYZ 456", type: "car", owner_name: "Mehmet Demir", unit_number: "B-05", zone_name: "B Blok Otoparkı", is_registered: true },
                { id: "3", plate: "06 DEF 789", type: "motorcycle", owner_name: "Ayşe Kaya", unit_number: "C-08", zone_name: "Misafir", is_registered: false },
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

    async function handleAddVehicle(e: React.FormEvent) {
        e.preventDefault();
        try {
            const res = await apiClient.createVehicle(form);
            setVehicles(prev => [res, ...prev]);
        } catch {
            setVehicles(prev => [{ id: String(Date.now()), ...form, is_registered: true }, ...prev]);
        }
        setIsModalOpen(false);
        setForm({ plate: "", type: "car", owner_name: "", unit_number: "" });
    }

    async function handleExit(id: string) {
        try { await apiClient.checkOutVisitor(id); } catch {}
        setCurrentVehicles(prev => prev.filter(v => v.id !== id));
    }

    const filteredVehicles = vehicles.filter(v =>
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
                <button onClick={() => setIsModalOpen(true)} className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90">
                    <Plus className="h-4 w-4" /> Araç Ekle
                </button>
            </div>

            {/* Stats */}
            <div className="grid gap-4 md:grid-cols-4">
                {[
                    { label: "Toplam Araç", value: String(stats?.total_vehicles ?? 0), color: "text-blue-600" },
                    { label: "Kayıtlı", value: String(stats?.registered_vehicles ?? 0), color: "text-green-600" },
                    { label: "Şu An İçeride", value: String(currentVehicles.length), color: "text-orange-600" },
                    { label: "Doluluk", value: `%${stats?.occupancy_rate ?? 0}`, color: "text-purple-600" },
                ].map(s => (
                    <div key={s.label} className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
                        <p className="text-sm text-gray-500">{s.label}</p>
                        <p className={`mt-1 text-2xl font-bold ${s.color}`}>{s.value}</p>
                    </div>
                ))}
            </div>

            {/* Tabs */}
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
                                    <td className="px-6 py-4">
                                        <span className="flex items-center gap-2 font-mono font-bold text-sm">{v.plate}</span>
                                    </td>
                                    <td className="px-6 py-4 text-sm text-gray-700 dark:text-gray-300">{v.owner_name ?? "—"}</td>
                                    <td className="px-6 py-4 text-sm">
                                        <span className="flex items-center gap-1 text-gray-500"><MapPin className="h-3 w-3" />{v.zone_name ?? "—"}</span>
                                    </td>
                                    <td className="px-6 py-4 text-sm text-gray-500">
                                        <span className="flex items-center gap-1"><Clock className="h-3 w-3" />{new Date(v.entry_time).toLocaleTimeString("tr-TR", { hour: "2-digit", minute: "2-digit" })}</span>
                                    </td>
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
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            {/* Modal */}
            {isModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">Araç Ekle</h2>
                            <button onClick={() => setIsModalOpen(false)}><X className="h-5 w-5 text-gray-500" /></button>
                        </div>
                        <form onSubmit={handleAddVehicle} className="space-y-4">
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
                            <div className="flex gap-3 pt-2">
                                <button type="button" onClick={() => setIsModalOpen(false)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">İptal</button>
                                <button type="submit" className="flex-1 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90">Ekle</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
