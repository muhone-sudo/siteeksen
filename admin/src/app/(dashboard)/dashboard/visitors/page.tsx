"use client";

import { useState, useEffect, useRef } from "react";
import { Plus, X, UserCheck, UserX, Clock, LogIn, LogOut, Loader2, Search, Phone, Edit, Trash2, Download, Upload } from "lucide-react";
import apiClient from "@/lib/api-client";

interface Visitor {
    id: string;
    name: string;
    phone?: string;
    unit_number: string;
    resident_name?: string;
    visit_purpose?: string;
    expected_at?: string;
    checked_in_at?: string;
    checked_out_at?: string;
    status: string;
    deleted: number;
}

interface VisitorStats {
    total_today: number;
    currently_inside: number;
    expected: number;
    total_this_month: number;
}

const purposeColors: Record<string, string> = {
    "Ziyaret": "bg-blue-100 text-blue-700",
    "Taşınma": "bg-orange-100 text-orange-700",
    "Tadilat": "bg-yellow-100 text-yellow-700",
    "Teslimat": "bg-green-100 text-green-700",
    "Teknik Servis": "bg-purple-100 text-purple-700",
};

const statusConfig: Record<string, { label: string; color: string; dot: string }> = {
    expected: { label: "Bekleniyor", color: "bg-yellow-100 text-yellow-700", dot: "bg-yellow-500" },
    inside: { label: "İçeride", color: "bg-green-100 text-green-700", dot: "bg-green-500" },
    completed: { label: "Çıktı", color: "bg-gray-100 text-gray-600", dot: "bg-gray-400" },
    cancelled: { label: "İptal", color: "bg-red-100 text-red-700", dot: "bg-red-500" },
};

const SAMPLE_CSV = `name,phone,unit_number,visit_purpose,expected_at
Zeynep Çelik,5551234567,A-12,Ziyaret,2026-06-08T14:00
Kargo Firması,,B-05,Teslimat,2026-06-08T10:00
Tesisatçı Ali,5559876543,C-08,Teknik Servis,`;

const emptyForm = { name: "", phone: "", unit_number: "", visit_purpose: "Ziyaret", expected_at: "" };

export default function VisitorsPage() {
    const [activeTab, setActiveTab] = useState<"today" | "inside" | "all">("today");
    const [visitors, setVisitors] = useState<Visitor[]>([]);
    const [stats, setStats] = useState<VisitorStats | null>(null);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingId, setEditingId] = useState<string | null>(null);
    const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);
    const [search, setSearch] = useState("");
    const [form, setForm] = useState(emptyForm);
    const csvRef = useRef<HTMLInputElement>(null);

    useEffect(() => {
        apiClient.loadToken();
        load();
    }, []);

    async function load() {
        setLoading(true);
        try {
            const [vRes, sRes] = await Promise.all([apiClient.getTodayVisitors(), apiClient.getVisitorStats()]);
            setVisitors((vRes?.data ?? vRes ?? []).map((v: any) => ({ ...v, deleted: v.deleted ?? 0 })));
            setStats(sRes);
        } catch {
            const now = new Date();
            setVisitors([
                { id: "v1", name: "Zeynep Çelik", phone: "5551234567", unit_number: "A-12", resident_name: "Ahmet Yılmaz", visit_purpose: "Ziyaret", expected_at: new Date(now.getTime() + 3600000).toISOString(), status: "expected", deleted: 0 },
                { id: "v2", name: "Kargo Firması", unit_number: "B-05", resident_name: "Mehmet Demir", visit_purpose: "Teslimat", checked_in_at: new Date(now.getTime() - 1800000).toISOString(), status: "inside", deleted: 0 },
                { id: "v3", name: "Tesisatçı Ali", phone: "5559876543", unit_number: "C-08", resident_name: "Ayşe Kaya", visit_purpose: "Teknik Servis", checked_in_at: new Date(now.getTime() - 7200000).toISOString(), checked_out_at: new Date(now.getTime() - 3600000).toISOString(), status: "completed", deleted: 0 },
            ]);
            setStats({ total_today: 8, currently_inside: 2, expected: 3, total_this_month: 124 });
        } finally {
            setLoading(false);
        }
    }

    const openAdd = () => { setEditingId(null); setForm(emptyForm); setIsModalOpen(true); };
    const openEdit = (v: Visitor) => {
        setEditingId(v.id);
        setForm({ name: v.name, phone: v.phone ?? "", unit_number: v.unit_number, visit_purpose: v.visit_purpose ?? "Ziyaret", expected_at: v.expected_at ? v.expected_at.slice(0, 16) : "" });
        setIsModalOpen(true);
    };

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        if (editingId) {
            setVisitors(prev => prev.map(v => v.id === editingId ? { ...v, ...form } : v));
        } else {
            try {
                const res = await apiClient.createVisitor(form);
                setVisitors(prev => [{ ...res, deleted: 0 }, ...prev]);
            } catch {
                setVisitors(prev => [{ id: String(Date.now()), ...form, status: "expected", deleted: 0 }, ...prev]);
            }
        }
        setIsModalOpen(false); setEditingId(null);
    }

    async function handleCheckIn(id: string) {
        try { await apiClient.checkInVisitor(id); } catch {}
        setVisitors(prev => prev.map(v => v.id === id ? { ...v, status: "inside", checked_in_at: new Date().toISOString() } : v));
    }

    async function handleCheckOut(id: string) {
        try { await apiClient.checkOutVisitor(id); } catch {}
        setVisitors(prev => prev.map(v => v.id === id ? { ...v, status: "completed", checked_out_at: new Date().toISOString() } : v));
    }

    const handleDelete = () => {
        if (!deleteConfirmId) return;
        setVisitors(prev => prev.map(v => v.id === deleteConfirmId ? { ...v, deleted: 1 } : v));
        setDeleteConfirmId(null);
    };

    const downloadSampleCSV = () => {
        const blob = new Blob([SAMPLE_CSV], { type: "text/csv;charset=utf-8;" });
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a"); a.href = url; a.download = "ziyaretci_ornek.csv"; a.click();
        URL.revokeObjectURL(url);
    };

    const handleCSVUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0]; if (!file) return;
        const reader = new FileReader();
        reader.onload = (ev) => {
            const text = ev.target?.result as string;
            const lines = text.trim().split("\n").slice(1);
            const newItems: Visitor[] = lines.map((line, i) => {
                const [name, phone, unit_number, visit_purpose, expected_at] = line.split(",");
                return { id: `csv_${Date.now()}_${i}`, name: (name ?? "").trim(), phone: (phone ?? "").trim() || undefined, unit_number: (unit_number ?? "").trim(), visit_purpose: (visit_purpose ?? "Ziyaret").trim(), expected_at: (expected_at ?? "").trim() || undefined, status: "expected", deleted: 0 };
            });
            setVisitors(prev => [...newItems, ...prev]);
        };
        reader.readAsText(file);
        if (csvRef.current) csvRef.current.value = "";
    };

    const activeVisitors = visitors.filter(v => v.deleted === 0);
    const filtered = activeVisitors.filter(v => {
        const matchesTab = activeTab === "all" ? true : activeTab === "inside" ? v.status === "inside" : true;
        const matchesSearch = v.name.toLowerCase().includes(search.toLowerCase()) || v.unit_number.toLowerCase().includes(search.toLowerCase());
        return matchesTab && matchesSearch;
    });

    const elapsed = (time: string) => {
        const mins = Math.floor((Date.now() - new Date(time).getTime()) / 60000);
        return mins < 60 ? `${mins}dk` : `${Math.floor(mins / 60)}sa ${mins % 60}dk`;
    };

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Ziyaretçi Yönetimi</h1>
                    <p className="text-sm text-gray-500">Ziyaretçi giriş-çıkış takibi</p>
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
                        <Plus className="h-4 w-4" /> Ziyaretçi Kaydı
                    </button>
                </div>
            </div>

            <div className="grid gap-4 md:grid-cols-4">
                {[
                    { label: "Bugün Gelen", value: String(stats?.total_today ?? activeVisitors.length), color: "text-blue-600" },
                    { label: "İçeride", value: String(stats?.currently_inside ?? activeVisitors.filter(v => v.status === "inside").length), color: "text-green-600" },
                    { label: "Bekleniyor", value: String(stats?.expected ?? activeVisitors.filter(v => v.status === "expected").length), color: "text-yellow-600" },
                    { label: "Bu Ay", value: String(stats?.total_this_month ?? 0), color: "text-purple-600" },
                ].map(s => (
                    <div key={s.label} className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
                        <p className="text-sm text-gray-500">{s.label}</p>
                        <p className={`mt-1 text-2xl font-bold ${s.color}`}>{s.value}</p>
                    </div>
                ))}
            </div>

            <div className="flex items-center justify-between">
                <div className="flex gap-2 border-b border-gray-200 dark:border-gray-700">
                    {[{ id: "today", label: "Bugün" }, { id: "inside", label: "İçeride" }, { id: "all", label: "Tümü" }].map(t => (
                        <button key={t.id} onClick={() => setActiveTab(t.id as typeof activeTab)}
                            className={`px-4 py-3 text-sm font-medium border-b-2 transition-colors ${activeTab === t.id ? "border-primary text-primary" : "border-transparent text-gray-500 hover:text-gray-700"}`}>
                            {t.label}
                        </button>
                    ))}
                </div>
                <div className="relative">
                    <Search className="absolute left-3 top-2.5 h-4 w-4 text-gray-400" />
                    <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Ad veya daire ara..."
                        className="rounded-lg border border-gray-300 pl-9 pr-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                </div>
            </div>

            <div className="rounded-xl bg-white shadow-sm dark:bg-gray-800">
                {loading ? (
                    <div className="flex items-center justify-center py-12"><Loader2 className="h-8 w-8 animate-spin text-primary" /></div>
                ) : (
                    <table className="w-full">
                        <thead>
                            <tr className="border-b border-gray-200 dark:border-gray-700">
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Ziyaretçi</th>
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Daire / Sakin</th>
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Amaç</th>
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Giriş / Beklenen</th>
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Durum</th>
                                <th className="px-6 py-3 text-right text-xs font-medium uppercase text-gray-500">İşlem</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                            {filtered.map(v => {
                                const st = statusConfig[v.status] ?? statusConfig.expected;
                                return (
                                    <tr key={v.id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50">
                                        <td className="px-6 py-4">
                                            <div className="font-medium text-sm text-gray-900 dark:text-white">{v.name}</div>
                                            {v.phone && <div className="flex items-center gap-1 text-xs text-gray-500 mt-0.5"><Phone className="h-3 w-3" />{v.phone}</div>}
                                        </td>
                                        <td className="px-6 py-4 text-sm">
                                            <div className="font-medium text-gray-900 dark:text-white">{v.unit_number}</div>
                                            <div className="text-gray-500 text-xs">{v.resident_name}</div>
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className={`rounded-full px-2 py-1 text-xs font-medium ${purposeColors[v.visit_purpose ?? ""] ?? "bg-gray-100 text-gray-600"}`}>
                                                {v.visit_purpose ?? "—"}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 text-sm text-gray-500">
                                            {v.checked_in_at ? (
                                                <div>
                                                    <div className="flex items-center gap-1"><LogIn className="h-3 w-3 text-green-500" />{new Date(v.checked_in_at).toLocaleTimeString("tr-TR", { hour: "2-digit", minute: "2-digit" })}</div>
                                                    {v.status === "inside" && <div className="text-xs text-blue-600 mt-0.5">{elapsed(v.checked_in_at)} içeride</div>}
                                                    {v.checked_out_at && <div className="flex items-center gap-1 text-xs mt-0.5"><LogOut className="h-3 w-3 text-gray-400" />{new Date(v.checked_out_at).toLocaleTimeString("tr-TR", { hour: "2-digit", minute: "2-digit" })}</div>}
                                                </div>
                                            ) : v.expected_at ? (
                                                <div className="flex items-center gap-1"><Clock className="h-3 w-3" />{new Date(v.expected_at).toLocaleTimeString("tr-TR", { hour: "2-digit", minute: "2-digit" })}</div>
                                            ) : "—"}
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className="flex items-center gap-1.5">
                                                <span className={`h-2 w-2 rounded-full ${st.dot}`} />
                                                <span className={`rounded-full px-2 py-1 text-xs font-medium ${st.color}`}>{st.label}</span>
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 text-right">
                                            <div className="flex justify-end gap-1">
                                                {v.status === "expected" && (
                                                    <button onClick={() => handleCheckIn(v.id)} className="p-1.5 rounded hover:bg-green-100 text-green-600"><UserCheck className="h-4 w-4" /></button>
                                                )}
                                                {v.status === "inside" && (
                                                    <button onClick={() => handleCheckOut(v.id)} className="p-1.5 rounded hover:bg-orange-100 text-orange-600"><UserX className="h-4 w-4" /></button>
                                                )}
                                                <button onClick={() => openEdit(v)} className="p-1.5 rounded hover:bg-blue-100 text-blue-500"><Edit className="h-4 w-4" /></button>
                                                <button onClick={() => setDeleteConfirmId(v.id)} className="p-1.5 rounded hover:bg-red-100 text-red-500"><Trash2 className="h-4 w-4" /></button>
                                            </div>
                                        </td>
                                    </tr>
                                );
                            })}
                            {filtered.length === 0 && (
                                <tr><td colSpan={6} className="px-6 py-12 text-center text-gray-400">Kayıt bulunamadı</td></tr>
                            )}
                        </tbody>
                    </table>
                )}
            </div>

            {/* Add/Edit Modal */}
            {isModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">{editingId ? "Ziyaretçiyi Düzenle" : "Ziyaretçi Kaydı"}</h2>
                            <button onClick={() => { setIsModalOpen(false); setEditingId(null); }}><X className="h-5 w-5 text-gray-500" /></button>
                        </div>
                        <form onSubmit={handleSubmit} className="space-y-4">
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Ad Soyad</label>
                                    <input required value={form.name} onChange={e => setForm({ ...form, name: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Telefon</label>
                                    <input value={form.phone} onChange={e => setForm({ ...form, phone: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                                </div>
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Daire No</label>
                                    <input required value={form.unit_number} onChange={e => setForm({ ...form, unit_number: e.target.value })} placeholder="A-12"
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Ziyaret Amacı</label>
                                    <select value={form.visit_purpose} onChange={e => setForm({ ...form, visit_purpose: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700">
                                        {["Ziyaret", "Taşınma", "Tadilat", "Teslimat", "Teknik Servis"].map(p => <option key={p}>{p}</option>)}
                                    </select>
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Beklenen Giriş Saati</label>
                                <input type="datetime-local" value={form.expected_at} onChange={e => setForm({ ...form, expected_at: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                            </div>
                            <div className="flex gap-3 pt-2">
                                <button type="button" onClick={() => { setIsModalOpen(false); setEditingId(null); }} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">İptal</button>
                                <button type="submit" className="flex-1 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90">{editingId ? "Güncelle" : "Kaydet"}</button>
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
                        <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-2">Ziyaretçiyi Sil</h2>
                        <p className="text-gray-500 text-sm mb-6">Bu ziyaretçi kaydı silinecek. Emin misiniz?</p>
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
