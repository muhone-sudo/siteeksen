"use client";

import { useState, useEffect, useRef } from "react";
import { Plus, X, Users, Briefcase, Calendar, DollarSign, Check, XCircle, Loader2, Phone, Edit, Trash2, Download, Upload } from "lucide-react";
import apiClient from "@/lib/api-client";

interface Employee {
    id: string;
    first_name: string;
    last_name: string;
    role: string;
    salary: number;
    phone?: string;
    start_date?: string;
    status: string;
    leave_balance?: number;
    deleted: number;
}

interface Leave {
    id: string;
    employee_id: string;
    employee_name: string;
    type: string;
    start_date: string;
    end_date: string;
    days: number;
    status: string;
    reason?: string;
    deleted: number;
}

const roleColors: Record<string, string> = {
    "Güvenlik": "bg-red-100 text-red-700",
    "Temizlik": "bg-blue-100 text-blue-700",
    "Bahçıvan": "bg-green-100 text-green-700",
    "Kapıcı": "bg-orange-100 text-orange-700",
    "Teknisyen": "bg-purple-100 text-purple-700",
    "Yönetici": "bg-gray-100 text-gray-700",
};

const SAMPLE_CSV = `first_name,last_name,role,salary,phone,start_date
Mustafa,Yıldız,Güvenlik,22000,5551112233,2024-01-15
Emine,Şahin,Temizlik,18000,5554445566,2023-06-01
Hüseyin,Çelik,Kapıcı,20000,5557778899,2022-09-01`;

export default function PersonnelPage() {
    const [activeTab, setActiveTab] = useState<"employees" | "leaves">("employees");
    const [employees, setEmployees] = useState<Employee[]>([]);
    const [leaves, setLeaves] = useState<Leave[]>([]);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingId, setEditingId] = useState<string | null>(null);
    const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);
    const [showSalary, setShowSalary] = useState<Set<string>>(new Set());
    const csvRef = useRef<HTMLInputElement>(null);

    const [form, setForm] = useState({ first_name: "", last_name: "", role: "Güvenlik", salary: 0, phone: "", start_date: "" });

    useEffect(() => {
        apiClient.loadToken();
        load();
    }, []);

    async function load() {
        setLoading(true);
        try {
            const [eRes, lRes] = await Promise.all([apiClient.getEmployees(), apiClient.getLeaves()]);
            setEmployees((eRes?.data ?? eRes ?? []).map((e: any) => ({ ...e, deleted: e.deleted ?? 0 })));
            setLeaves((lRes?.data ?? lRes ?? []).map((l: any) => ({ ...l, deleted: l.deleted ?? 0 })));
        } catch {
            setEmployees([
                { id: "1", first_name: "Ahmet", last_name: "Güvenlik", role: "Güvenlik", salary: 22000, phone: "5551112233", start_date: "2023-01-15", status: "active", leave_balance: 14, deleted: 0 },
                { id: "2", first_name: "Fatma", last_name: "Temizlik", role: "Temizlik", salary: 18000, phone: "5554445566", start_date: "2022-06-01", status: "active", leave_balance: 7, deleted: 0 },
                { id: "3", first_name: "Mehmet", last_name: "Bahçıvan", role: "Bahçıvan", salary: 16000, phone: "5557778899", start_date: "2024-03-10", status: "active", leave_balance: 21, deleted: 0 },
                { id: "4", first_name: "Ali", last_name: "Kapıcı", role: "Kapıcı", salary: 20000, phone: "5550001122", start_date: "2021-09-01", status: "active", leave_balance: 0, deleted: 0 },
            ]);
            setLeaves([
                { id: "l1", employee_id: "1", employee_name: "Ahmet Güvenlik", type: "Yıllık İzin", start_date: "2026-06-10", end_date: "2026-06-17", days: 7, status: "pending", reason: "Aile ziyareti", deleted: 0 },
                { id: "l2", employee_id: "2", employee_name: "Fatma Temizlik", type: "Mazeret İzni", start_date: "2026-06-05", end_date: "2026-06-05", days: 1, status: "approved", deleted: 0 },
            ]);
        } finally {
            setLoading(false);
        }
    }

    const openAdd = () => { setEditingId(null); setForm({ first_name: "", last_name: "", role: "Güvenlik", salary: 0, phone: "", start_date: "" }); setIsModalOpen(true); };
    const openEdit = (emp: Employee) => { setEditingId(emp.id); setForm({ first_name: emp.first_name, last_name: emp.last_name, role: emp.role, salary: emp.salary, phone: emp.phone ?? "", start_date: emp.start_date ?? "" }); setIsModalOpen(true); };

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        if (editingId) {
            setEmployees(prev => prev.map(emp => emp.id === editingId ? { ...emp, ...form } : emp));
        } else {
            try {
                const res = await apiClient.createEmployee(form);
                setEmployees(prev => [{ ...res, deleted: 0 }, ...prev]);
            } catch {
                setEmployees(prev => [{ id: String(Date.now()), ...form, status: "active", leave_balance: 14, deleted: 0 }, ...prev]);
            }
        }
        setIsModalOpen(false); setEditingId(null);
    }

    const handleDelete = () => {
        if (!deleteConfirmId) return;
        setEmployees(prev => prev.map(e => e.id === deleteConfirmId ? { ...e, deleted: 1 } : e));
        setDeleteConfirmId(null);
    };

    async function handleApproveLeave(id: string) {
        try { await apiClient.approveLeave(id); } catch {}
        setLeaves(prev => prev.map(l => l.id === id ? { ...l, status: "approved" } : l));
    }

    const handleRejectLeave = (id: string) => {
        setLeaves(prev => prev.map(l => l.id === id ? { ...l, status: "rejected" } : l));
    };

    const downloadSampleCSV = () => {
        const blob = new Blob([SAMPLE_CSV], { type: "text/csv;charset=utf-8;" });
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a"); a.href = url; a.download = "personel_ornek.csv"; a.click();
        URL.revokeObjectURL(url);
    };

    const handleCSVUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0]; if (!file) return;
        const reader = new FileReader();
        reader.onload = (ev) => {
            const text = ev.target?.result as string;
            const lines = text.trim().split("\n").slice(1);
            const newItems: Employee[] = lines.map((line, i) => {
                const [first_name, last_name, role, salary, phone, start_date] = line.split(",");
                return { id: `csv_${Date.now()}_${i}`, first_name: (first_name ?? "").trim(), last_name: (last_name ?? "").trim(), role: (role ?? "Güvenlik").trim(), salary: parseFloat((salary ?? "0").trim()) || 0, phone: (phone ?? "").trim(), start_date: (start_date ?? "").trim(), status: "active", leave_balance: 14, deleted: 0 };
            });
            setEmployees(prev => [...newItems, ...prev]);
        };
        reader.readAsText(file);
        if (csvRef.current) csvRef.current.value = "";
    };

    const activeEmployees = employees.filter(e => e.deleted === 0);
    const activeLeaves = leaves.filter(l => l.deleted === 0);
    const totalSalary = activeEmployees.reduce((s, e) => s + e.salary, 0);

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Personel Yönetimi</h1>
                    <p className="text-sm text-gray-500">Çalışan bilgileri ve izin talepleri</p>
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
                        <Plus className="h-4 w-4" /> Personel Ekle
                    </button>
                </div>
            </div>

            <div className="grid gap-4 md:grid-cols-4">
                {[
                    { label: "Toplam Personel", value: String(activeEmployees.length), icon: Users, color: "text-blue-600" },
                    { label: "Aktif", value: String(activeEmployees.filter(e => e.status === "active").length), icon: Briefcase, color: "text-green-600" },
                    { label: "İzinde", value: String(activeLeaves.filter(l => l.status === "approved" && new Date(l.start_date) <= new Date()).length), icon: Calendar, color: "text-orange-600" },
                    { label: "Aylık Maaş", value: `₺${totalSalary.toLocaleString()}`, icon: DollarSign, color: "text-purple-600" },
                ].map(s => (
                    <div key={s.label} className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
                        <p className="text-sm text-gray-500">{s.label}</p>
                        <p className={`mt-1 text-2xl font-bold ${s.color}`}>{s.value}</p>
                    </div>
                ))}
            </div>

            <div className="flex gap-2 border-b border-gray-200 dark:border-gray-700">
                {[
                    { id: "employees", label: "Personel Listesi" },
                    { id: "leaves", label: `İzin Talepleri${activeLeaves.filter(l => l.status === "pending").length > 0 ? ` (${activeLeaves.filter(l => l.status === "pending").length})` : ""}` }
                ].map(t => (
                    <button key={t.id} onClick={() => setActiveTab(t.id as typeof activeTab)}
                        className={`px-4 py-3 text-sm font-medium border-b-2 transition-colors ${activeTab === t.id ? "border-primary text-primary" : "border-transparent text-gray-500 hover:text-gray-700"}`}>
                        {t.label}
                    </button>
                ))}
            </div>

            <div className="rounded-xl bg-white shadow-sm dark:bg-gray-800">
                {loading ? (
                    <div className="flex items-center justify-center py-12"><Loader2 className="h-8 w-8 animate-spin text-primary" /></div>
                ) : activeTab === "employees" ? (
                    <table className="w-full">
                        <thead>
                            <tr className="border-b border-gray-200 dark:border-gray-700">
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Ad Soyad</th>
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Görev</th>
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Telefon</th>
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">İşe Başlama</th>
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">İzin Bakiyesi</th>
                                <th className="px-6 py-3 text-right text-xs font-medium uppercase text-gray-500">Maaş</th>
                                <th className="px-6 py-3 text-right text-xs font-medium uppercase text-gray-500">İşlem</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                            {activeEmployees.map(emp => (
                                <tr key={emp.id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50">
                                    <td className="px-6 py-4">
                                        <div className="flex items-center gap-3">
                                            <div className="h-8 w-8 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold text-sm">
                                                {emp.first_name[0]}{emp.last_name[0]}
                                            </div>
                                            <span className="font-medium text-gray-900 dark:text-white">{emp.first_name} {emp.last_name}</span>
                                        </div>
                                    </td>
                                    <td className="px-6 py-4">
                                        <span className={`rounded-full px-2 py-1 text-xs font-medium ${roleColors[emp.role] ?? "bg-gray-100 text-gray-600"}`}>{emp.role}</span>
                                    </td>
                                    <td className="px-6 py-4 text-sm text-gray-500">
                                        <span className="flex items-center gap-1"><Phone className="h-3 w-3" />{emp.phone ?? "—"}</span>
                                    </td>
                                    <td className="px-6 py-4 text-sm text-gray-500">{emp.start_date ? new Date(emp.start_date).toLocaleDateString("tr-TR") : "—"}</td>
                                    <td className="px-6 py-4 text-sm">
                                        <span className={`font-medium ${(emp.leave_balance ?? 0) > 0 ? "text-green-600" : "text-red-600"}`}>{emp.leave_balance ?? 0} gün</span>
                                    </td>
                                    <td className="px-6 py-4 text-right text-sm">
                                        <button onClick={() => setShowSalary(prev => { const n = new Set(prev); n.has(emp.id) ? n.delete(emp.id) : n.add(emp.id); return n; })}
                                            className="font-medium text-gray-900 dark:text-white">
                                            {showSalary.has(emp.id) ? `₺${emp.salary.toLocaleString()}` : "••••••"}
                                        </button>
                                    </td>
                                    <td className="px-6 py-4 text-right">
                                        <div className="flex justify-end gap-1">
                                            <button onClick={() => openEdit(emp)} className="p-1.5 rounded hover:bg-blue-100 text-blue-500"><Edit className="h-4 w-4" /></button>
                                            <button onClick={() => setDeleteConfirmId(emp.id)} className="p-1.5 rounded hover:bg-red-100 text-red-500"><Trash2 className="h-4 w-4" /></button>
                                        </div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                ) : (
                    <table className="w-full">
                        <thead>
                            <tr className="border-b border-gray-200 dark:border-gray-700">
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Personel</th>
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Tür</th>
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Tarih</th>
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Gün</th>
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Neden</th>
                                <th className="px-6 py-3 text-right text-xs font-medium uppercase text-gray-500">İşlem</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                            {activeLeaves.map(l => (
                                <tr key={l.id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50">
                                    <td className="px-6 py-4 font-medium text-sm text-gray-900 dark:text-white">{l.employee_name}</td>
                                    <td className="px-6 py-4 text-sm text-gray-500">{l.type}</td>
                                    <td className="px-6 py-4 text-sm text-gray-500">{new Date(l.start_date).toLocaleDateString("tr-TR")} – {new Date(l.end_date).toLocaleDateString("tr-TR")}</td>
                                    <td className="px-6 py-4 text-sm font-medium text-blue-600">{l.days} gün</td>
                                    <td className="px-6 py-4 text-sm text-gray-500">{l.reason ?? "—"}</td>
                                    <td className="px-6 py-4 text-right">
                                        {l.status === "pending" ? (
                                            <div className="flex justify-end gap-2">
                                                <button onClick={() => handleApproveLeave(l.id)} className="flex items-center gap-1 rounded-lg bg-green-100 px-3 py-1 text-xs font-medium text-green-700 hover:bg-green-200">
                                                    <Check className="h-3 w-3" /> Onayla
                                                </button>
                                                <button onClick={() => handleRejectLeave(l.id)} className="flex items-center gap-1 rounded-lg bg-red-100 px-3 py-1 text-xs font-medium text-red-700 hover:bg-red-200">
                                                    <XCircle className="h-3 w-3" /> Reddet
                                                </button>
                                            </div>
                                        ) : (
                                            <span className={`rounded-full px-2 py-1 text-xs font-medium ${l.status === "approved" ? "bg-green-100 text-green-700" : "bg-red-100 text-red-700"}`}>
                                                {l.status === "approved" ? "Onaylı" : "Reddedildi"}
                                            </span>
                                        )}
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}
            </div>

            {/* Add/Edit Modal */}
            {isModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">{editingId ? "Personeli Düzenle" : "Personel Ekle"}</h2>
                            <button onClick={() => { setIsModalOpen(false); setEditingId(null); }}><X className="h-5 w-5 text-gray-500" /></button>
                        </div>
                        <form onSubmit={handleSubmit} className="space-y-4">
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Ad</label>
                                    <input required value={form.first_name} onChange={e => setForm({ ...form, first_name: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Soyad</label>
                                    <input required value={form.last_name} onChange={e => setForm({ ...form, last_name: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                                </div>
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Görev</label>
                                    <select value={form.role} onChange={e => setForm({ ...form, role: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700">
                                        {["Güvenlik", "Temizlik", "Bahçıvan", "Kapıcı", "Teknisyen", "Yönetici"].map(r => <option key={r}>{r}</option>)}
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Maaş (₺)</label>
                                    <input type="number" required value={form.salary || ""} onChange={e => setForm({ ...form, salary: Number(e.target.value) })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                                </div>
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Telefon</label>
                                    <input value={form.phone} onChange={e => setForm({ ...form, phone: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">İşe Başlama</label>
                                    <input type="date" value={form.start_date} onChange={e => setForm({ ...form, start_date: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                                </div>
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
                        <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-2">Personeli Sil</h2>
                        <p className="text-gray-500 text-sm mb-6">Bu personel kaydı silinecek. Emin misiniz?</p>
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
