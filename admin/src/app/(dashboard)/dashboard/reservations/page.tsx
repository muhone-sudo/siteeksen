"use client";

import { useState, useEffect } from "react";
import { Plus, X, Calendar, Clock, Users, XCircle, Loader2, Edit, Trash2 } from "lucide-react";
import apiClient from "@/lib/api-client";

interface Facility {
    id: string;
    name: string;
    type: string;
    capacity: number;
    is_available: boolean;
}

interface Reservation {
    id: string;
    facility_id: string;
    facility_name: string;
    resident_name?: string;
    unit_number?: string;
    start_time: string;
    end_time: string;
    status: string;
    notes?: string;
    deleted: number;
}

const facilityTypes: Record<string, { label: string; color: string }> = {
    meeting_room: { label: "Toplantı Salonu", color: "bg-blue-100 text-blue-700" },
    bbq: { label: "Barbekü Alanı", color: "bg-orange-100 text-orange-700" },
    gym: { label: "Spor Salonu", color: "bg-green-100 text-green-700" },
    pool: { label: "Yüzme Havuzu", color: "bg-cyan-100 text-cyan-700" },
    tennis: { label: "Tenis Kortu", color: "bg-yellow-100 text-yellow-700" },
    other: { label: "Diğer", color: "bg-gray-100 text-gray-700" },
};

const statusConfig: Record<string, { label: string; color: string }> = {
    confirmed: { label: "Onaylı", color: "bg-green-100 text-green-700" },
    pending: { label: "Bekliyor", color: "bg-yellow-100 text-yellow-700" },
    cancelled: { label: "İptal", color: "bg-red-100 text-red-700" },
    completed: { label: "Tamamlandı", color: "bg-gray-100 text-gray-600" },
};

const emptyForm = { facility_id: "", unit_number: "", resident_name: "", start_time: "", end_time: "", notes: "" };

export default function ReservationsPage() {
    const [activeTab, setActiveTab] = useState<"reservations" | "facilities">("reservations");
    const [reservations, setReservations] = useState<Reservation[]>([]);
    const [facilities, setFacilities] = useState<Facility[]>([]);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingId, setEditingId] = useState<string | null>(null);
    const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);
    const [form, setForm] = useState(emptyForm);

    useEffect(() => {
        apiClient.loadToken();
        load();
    }, []);

    async function load() {
        setLoading(true);
        try {
            const [rRes, fRes] = await Promise.all([apiClient.getReservations(), apiClient.getFacilities()]);
            setReservations((rRes?.data ?? rRes ?? []).map((r: any) => ({ ...r, deleted: r.deleted ?? 0 })));
            setFacilities(fRes?.data ?? fRes ?? []);
        } catch {
            setFacilities([
                { id: "f1", name: "Toplantı Salonu A", type: "meeting_room", capacity: 20, is_available: true },
                { id: "f2", name: "Barbekü Alanı", type: "bbq", capacity: 40, is_available: true },
                { id: "f3", name: "Spor Salonu", type: "gym", capacity: 15, is_available: false },
                { id: "f4", name: "Yüzme Havuzu", type: "pool", capacity: 50, is_available: true },
            ]);
            setReservations([
                { id: "r1", facility_id: "f1", facility_name: "Toplantı Salonu A", resident_name: "Ahmet Yılmaz", unit_number: "A-12", start_time: "2026-06-08T14:00:00", end_time: "2026-06-08T16:00:00", status: "confirmed", deleted: 0 },
                { id: "r2", facility_id: "f2", facility_name: "Barbekü Alanı", resident_name: "Mehmet Demir", unit_number: "B-05", start_time: "2026-06-09T12:00:00", end_time: "2026-06-09T18:00:00", status: "pending", notes: "Doğum günü partisi", deleted: 0 },
                { id: "r3", facility_id: "f4", facility_name: "Yüzme Havuzu", resident_name: "Ayşe Kaya", unit_number: "C-08", start_time: "2026-06-07T10:00:00", end_time: "2026-06-07T12:00:00", status: "confirmed", deleted: 0 },
            ]);
        } finally {
            setLoading(false);
        }
    }

    const openAdd = () => { setEditingId(null); setForm(emptyForm); setIsModalOpen(true); };
    const openEdit = (r: Reservation) => {
        setEditingId(r.id);
        setForm({ facility_id: r.facility_id, unit_number: r.unit_number ?? "", resident_name: r.resident_name ?? "", start_time: r.start_time.slice(0, 16), end_time: r.end_time.slice(0, 16), notes: r.notes ?? "" });
        setIsModalOpen(true);
    };

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        const fac = facilities.find(f => f.id === form.facility_id);
        if (editingId) {
            setReservations(prev => prev.map(r => r.id === editingId ? { ...r, ...form, facility_name: fac?.name ?? r.facility_name } : r));
        } else {
            try {
                const res = await apiClient.createReservation(form);
                setReservations(prev => [{ ...res, deleted: 0 }, ...prev]);
            } catch {
                setReservations(prev => [{ id: String(Date.now()), facility_id: form.facility_id, facility_name: fac?.name ?? "—", resident_name: form.resident_name, unit_number: form.unit_number, start_time: form.start_time, end_time: form.end_time, status: "pending", notes: form.notes, deleted: 0 }, ...prev]);
            }
        }
        setIsModalOpen(false); setEditingId(null);
    }

    async function handleCancel(id: string) {
        try { await apiClient.cancelReservation(id); } catch {}
        setReservations(prev => prev.map(r => r.id === id ? { ...r, status: "cancelled" } : r));
    }

    const handleDelete = () => {
        if (!deleteConfirmId) return;
        setReservations(prev => prev.map(r => r.id === deleteConfirmId ? { ...r, deleted: 1 } : r));
        setDeleteConfirmId(null);
    };

    const active = reservations.filter(r => r.deleted === 0);
    const stats = {
        total: active.length,
        confirmed: active.filter(r => r.status === "confirmed").length,
        pending: active.filter(r => r.status === "pending").length,
        availableFacilities: facilities.filter(f => f.is_available).length,
    };

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Rezervasyon Yönetimi</h1>
                    <p className="text-sm text-gray-500">Ortak alan rezervasyonları</p>
                </div>
                <button onClick={openAdd} className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90">
                    <Plus className="h-4 w-4" /> Rezervasyon Ekle
                </button>
            </div>

            <div className="grid gap-4 md:grid-cols-4">
                {[
                    { label: "Toplam", value: String(stats.total), color: "text-blue-600" },
                    { label: "Onaylı", value: String(stats.confirmed), color: "text-green-600" },
                    { label: "Bekleyen", value: String(stats.pending), color: "text-yellow-600" },
                    { label: "Müsait Tesis", value: String(stats.availableFacilities), color: "text-purple-600" },
                ].map(s => (
                    <div key={s.label} className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
                        <p className="text-sm text-gray-500">{s.label}</p>
                        <p className={`mt-1 text-2xl font-bold ${s.color}`}>{s.value}</p>
                    </div>
                ))}
            </div>

            <div className="flex gap-2 border-b border-gray-200 dark:border-gray-700">
                {[{ id: "reservations", label: "Rezervasyonlar" }, { id: "facilities", label: "Tesisler" }].map(t => (
                    <button key={t.id} onClick={() => setActiveTab(t.id as typeof activeTab)}
                        className={`px-4 py-3 text-sm font-medium border-b-2 transition-colors ${activeTab === t.id ? "border-primary text-primary" : "border-transparent text-gray-500 hover:text-gray-700"}`}>
                        {t.label}
                    </button>
                ))}
            </div>

            <div className="rounded-xl bg-white shadow-sm dark:bg-gray-800">
                {loading ? (
                    <div className="flex items-center justify-center py-12"><Loader2 className="h-8 w-8 animate-spin text-primary" /></div>
                ) : activeTab === "reservations" ? (
                    <table className="w-full">
                        <thead>
                            <tr className="border-b border-gray-200 dark:border-gray-700">
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Tesis</th>
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Sakin</th>
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Tarih & Saat</th>
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Notlar</th>
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Durum</th>
                                <th className="px-6 py-3 text-right text-xs font-medium uppercase text-gray-500">İşlem</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                            {active.map(r => (
                                <tr key={r.id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50">
                                    <td className="px-6 py-4 font-medium text-sm text-gray-900 dark:text-white">{r.facility_name}</td>
                                    <td className="px-6 py-4 text-sm">
                                        <div className="text-gray-900 dark:text-white">{r.resident_name ?? "—"}</div>
                                        <div className="text-gray-500 text-xs">{r.unit_number}</div>
                                    </td>
                                    <td className="px-6 py-4 text-sm text-gray-500">
                                        <div className="flex items-center gap-1"><Calendar className="h-3 w-3" />{new Date(r.start_time).toLocaleDateString("tr-TR")}</div>
                                        <div className="flex items-center gap-1 text-xs mt-1"><Clock className="h-3 w-3" />{new Date(r.start_time).toLocaleTimeString("tr-TR", { hour: "2-digit", minute: "2-digit" })} – {new Date(r.end_time).toLocaleTimeString("tr-TR", { hour: "2-digit", minute: "2-digit" })}</div>
                                    </td>
                                    <td className="px-6 py-4 text-sm text-gray-500">{r.notes ?? "—"}</td>
                                    <td className="px-6 py-4">
                                        <span className={`rounded-full px-2 py-1 text-xs font-medium ${statusConfig[r.status]?.color ?? "bg-gray-100 text-gray-600"}`}>
                                            {statusConfig[r.status]?.label ?? r.status}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4 text-right">
                                        <div className="flex justify-end gap-1">
                                            <button onClick={() => openEdit(r)} className="p-1.5 rounded hover:bg-blue-100 text-blue-500"><Edit className="h-4 w-4" /></button>
                                            {r.status !== "cancelled" && r.status !== "completed" && (
                                                <button onClick={() => handleCancel(r.id)} className="p-1.5 rounded hover:bg-orange-100 text-orange-500"><XCircle className="h-4 w-4" /></button>
                                            )}
                                            <button onClick={() => setDeleteConfirmId(r.id)} className="p-1.5 rounded hover:bg-red-100 text-red-500"><Trash2 className="h-4 w-4" /></button>
                                        </div>
                                    </td>
                                </tr>
                            ))}
                            {active.length === 0 && (
                                <tr><td colSpan={6} className="px-6 py-12 text-center text-gray-400">Rezervasyon bulunamadı</td></tr>
                            )}
                        </tbody>
                    </table>
                ) : (
                    <div className="grid gap-4 p-6 md:grid-cols-2 lg:grid-cols-3">
                        {facilities.map(f => {
                            const cfg = facilityTypes[f.type] ?? facilityTypes.other;
                            return (
                                <div key={f.id} className="rounded-lg border border-gray-200 p-4 dark:border-gray-700">
                                    <div className="flex items-start justify-between mb-3">
                                        <div>
                                            <h3 className="font-medium text-gray-900 dark:text-white">{f.name}</h3>
                                            <span className={`mt-1 inline-block rounded-full px-2 py-0.5 text-xs font-medium ${cfg.color}`}>{cfg.label}</span>
                                        </div>
                                        <span className={`rounded-full px-2 py-1 text-xs font-medium ${f.is_available ? "bg-green-100 text-green-700" : "bg-red-100 text-red-700"}`}>
                                            {f.is_available ? "Müsait" : "Dolu"}
                                        </span>
                                    </div>
                                    <div className="flex items-center gap-1 text-sm text-gray-500">
                                        <Users className="h-3 w-3" /> Kapasite: {f.capacity} kişi
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                )}
            </div>

            {/* Add/Edit Modal */}
            {isModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">{editingId ? "Rezervasyonu Düzenle" : "Rezervasyon Ekle"}</h2>
                            <button onClick={() => { setIsModalOpen(false); setEditingId(null); }}><X className="h-5 w-5 text-gray-500" /></button>
                        </div>
                        <form onSubmit={handleSubmit} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Tesis</label>
                                <select required value={form.facility_id} onChange={e => setForm({ ...form, facility_id: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700">
                                    <option value="">Seçin</option>
                                    {facilities.map(f => <option key={f.id} value={f.id}>{f.name}</option>)}
                                </select>
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Daire No</label>
                                    <input value={form.unit_number} onChange={e => setForm({ ...form, unit_number: e.target.value })} placeholder="A-12"
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Sakin Adı</label>
                                    <input value={form.resident_name} onChange={e => setForm({ ...form, resident_name: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                                </div>
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Başlangıç</label>
                                    <input type="datetime-local" required value={form.start_time} onChange={e => setForm({ ...form, start_time: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Bitiş</label>
                                    <input type="datetime-local" required value={form.end_time} onChange={e => setForm({ ...form, end_time: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Notlar</label>
                                <textarea rows={2} value={form.notes} onChange={e => setForm({ ...form, notes: e.target.value })}
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
                        <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-2">Rezervasyonu Sil</h2>
                        <p className="text-gray-500 text-sm mb-6">Bu rezervasyon silinecek. Emin misiniz?</p>
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
