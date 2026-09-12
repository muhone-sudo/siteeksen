"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import { Plus, X, UserCheck, UserX, Clock, LogIn, LogOut, Search, Phone, Edit, Trash2, Download, Upload } from "lucide-react";
import apiClient from "@/lib/api-client";
import { EmptyState, ErrorState, LoadingState, NotImplementedNotice, toUserMessage } from "@/components/ui/data-state";

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
    const [loadError, setLoadError] = useState<string | null>(null);
    const [formError, setFormError] = useState<string | null>(null);
    const [actionError, setActionError] = useState<string | null>(null);
    const [deleteError, setDeleteError] = useState<string | null>(null);
    const [submitting, setSubmitting] = useState(false);
    const csvRef = useRef<HTMLInputElement>(null);

    const load = useCallback(async () => {
        setLoading(true);
        setLoadError(null);
        try {
            const [vRes, sRes] = await Promise.all([apiClient.getTodayVisitors(), apiClient.getVisitorStats()]);
            setVisitors(vRes?.data ?? vRes ?? []);
            setStats(sRes ?? null);
        } catch (err) {
            setVisitors([]);
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

    const openAdd = () => { setEditingId(null); setForm(emptyForm); setFormError(null); setIsModalOpen(true); };
    const openEdit = (v: Visitor) => {
        setEditingId(v.id);
        setForm({ name: v.name, phone: v.phone ?? "", unit_number: v.unit_number, visit_purpose: v.visit_purpose ?? "Ziyaret", expected_at: v.expected_at ? v.expected_at.slice(0, 16) : "" });
        setFormError(null);
        setIsModalOpen(true);
    };
    const closeModal = () => { setIsModalOpen(false); setEditingId(null); setFormError(null); };

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        setFormError(null);
        // Ziyaretçi güncelleme için sunucuda uç nokta yok (api-client.ts'te updateVisitor bulunmuyor).
        // Sessizce yalnızca ekranda güncellemek "kaydedildi" yanılgısı yarattığı için engellendi.
        if (editingId) {
            setFormError("Ziyaretçi güncelleme henüz sunucu tarafında desteklenmiyor. Değişiklik kaydedilmedi.");
            return;
        }
        setSubmitting(true);
        try {
            await apiClient.createVisitor(form);
            closeModal();
            setForm(emptyForm);
            await load();
        } catch (err) {
            setFormError(toUserMessage(err, "Ziyaretçi kaydedilemedi."));
        } finally {
            setSubmitting(false);
        }
    }

    async function handleCheckIn(id: string) {
        setActionError(null);
        try {
            await apiClient.checkInVisitor(id);
            await load();
        } catch (err) {
            setActionError(toUserMessage(err, "Giriş kaydı sunucuya işlenemedi."));
        }
    }

    async function handleCheckOut(id: string) {
        setActionError(null);
        try {
            await apiClient.checkOutVisitor(id);
            await load();
        } catch (err) {
            setActionError(toUserMessage(err, "Çıkış kaydı sunucuya işlenemedi."));
        }
    }

    // Sunucuda ziyaretçi silme uç noktası yok; kaydı yalnızca ekrandan kaldırmak
    // yenilemede geri geldiği için sahte başarı sayılır.
    const handleDelete = () => {
        setDeleteError("Ziyaretçi silme henüz sunucu tarafında desteklenmiyor. Kayıt silinmedi.");
    };

    const closeDeleteConfirm = () => { setDeleteConfirmId(null); setDeleteError(null); };

    const downloadSampleCSV = () => {
        const blob = new Blob([SAMPLE_CSV], { type: "text/csv;charset=utf-8;" });
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a"); a.href = url; a.download = "ziyaretci_ornek.csv"; a.click();
        URL.revokeObjectURL(url);
    };

    // CSV satırları gerçekten sunucuya gönderilir; başarısız satırlar kullanıcıya bildirilir.
    const handleCSVUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0]; if (!file) return;
        const reader = new FileReader();
        reader.onload = async (ev) => {
            const text = ev.target?.result as string;
            const lines = text.trim().split("\n").slice(1).filter(l => l.trim() !== "");
            if (lines.length === 0) return;
            setActionError(null);
            setSubmitting(true);
            const failures: string[] = [];
            for (const line of lines) {
                const [name, phone, unit_number, visit_purpose, expected_at] = line.split(",");
                try {
                    await apiClient.createVisitor({
                        name: (name ?? "").trim(),
                        phone: (phone ?? "").trim() || undefined,
                        unit_number: (unit_number ?? "").trim(),
                        visit_purpose: (visit_purpose ?? "").trim() || "Ziyaret",
                        expected_at: (expected_at ?? "").trim() || undefined,
                    });
                } catch (err) {
                    failures.push(toUserMessage(err, "Kaydedilemedi."));
                }
            }
            setSubmitting(false);
            if (failures.length > 0) {
                setActionError(`${lines.length} satırdan ${failures.length} tanesi sunucuya kaydedilemedi: ${failures[0]}`);
            }
            await load();
        };
        reader.readAsText(file);
        if (csvRef.current) csvRef.current.value = "";
    };

    const showStats = !loading && !loadError;
    const statCards = [
        { label: "Bugün Gelen", value: showStats ? String(stats?.total_today ?? visitors.length) : "—", color: "text-blue-600" },
        { label: "İçeride", value: showStats ? String(stats?.currently_inside ?? visitors.filter(v => v.status === "inside").length) : "—", color: "text-green-600" },
        { label: "Bekleniyor", value: showStats ? String(stats?.expected ?? visitors.filter(v => v.status === "expected").length) : "—", color: "text-yellow-600" },
        { label: "Bu Ay", value: showStats && stats?.total_this_month != null ? String(stats.total_this_month) : "—", color: "text-purple-600" },
    ];

    const filtered = visitors.filter(v => {
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
            <NotImplementedNotice detail="Ziyaretçi servisi henüz kalıcı kayıt yapmıyor; giriş/çıkış ve yeni ziyaretçi kayıtları sunucuda saklanmayabilir. Güncelleme ve silme uç noktaları hazır değil." />

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

            {actionError && (
                <div role="alert" className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                    {actionError}
                </div>
            )}

            <div className="grid gap-4 md:grid-cols-4">
                {statCards.map(s => (
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
                    <LoadingState />
                ) : loadError ? (
                    <div className="p-6"><ErrorState message={loadError} onRetry={load} /></div>
                ) : filtered.length === 0 ? (
                    <EmptyState description="Görüntülenecek ziyaretçi kaydı yok." />
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
                                                <button onClick={() => { setDeleteError(null); setDeleteConfirmId(v.id); }} className="p-1.5 rounded hover:bg-red-100 text-red-500"><Trash2 className="h-4 w-4" /></button>
                                            </div>
                                        </td>
                                    </tr>
                                );
                            })}
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
                            <button onClick={closeModal}><X className="h-5 w-5 text-gray-500" /></button>
                        </div>
                        {formError && (
                            <div role="alert" className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                                {formError}
                            </div>
                        )}
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
                                <button type="button" onClick={closeModal} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">İptal</button>
                                <button type="submit" disabled={submitting} className="flex-1 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed">{submitting ? "Kaydediliyor..." : editingId ? "Güncelle" : "Kaydet"}</button>
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
                        {deleteError && (
                            <div role="alert" className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-left text-red-700">
                                {deleteError}
                            </div>
                        )}
                        <div className="flex gap-3">
                            <button onClick={closeDeleteConfirm} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">İptal</button>
                            <button onClick={handleDelete} className="flex-1 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700">Sil</button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
