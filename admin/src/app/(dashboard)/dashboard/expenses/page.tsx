"use client";

import { useState, useEffect, useRef } from "react";
import { Plus, X, TrendingDown, FileText, Zap, Wrench, Building, Users, Receipt, CreditCard, Upload, CheckCircle, AlertCircle, Loader2, Edit, Trash2, Download } from "lucide-react";
import apiClient from "@/lib/api-client";

interface Expense {
    id: string;
    category_name: string;
    description: string;
    amount: number;
    expense_date: string;
    is_invoiced: boolean;
    status: string;
    vendor_name?: string;
    invoice_number?: string;
    deleted: number;
}

interface ExpenseSummary {
    total_expenses: number;
    invoiced_expenses: number;
    non_invoiced_expenses: number;
    assessment_reflecting: number;
    pending_approval_count: number;
    pending_approval_amount: number;
}

const categoryConfig: Record<string, { label: string; icon: React.ElementType; color: string }> = {
    "Ortak Elektrik": { label: "Elektrik", icon: Zap, color: "text-yellow-500" },
    "Bina Temizliği": { label: "Temizlik", icon: Building, color: "text-blue-500" },
    "Güvenlik": { label: "Güvenlik", icon: Receipt, color: "text-red-500" },
    "Asansör Bakımı": { label: "Bakım", icon: Wrench, color: "text-orange-500" },
    "Yönetici Ücreti": { label: "Yönetim", icon: FileText, color: "text-purple-500" },
    "Acil Tamir": { label: "Tamir", icon: CreditCard, color: "text-pink-500" },
    default: { label: "Diğer", icon: FileText, color: "text-gray-500" },
};

const SAMPLE_CSV = `category_name,description,amount,expense_date,vendor_name,is_invoiced
Ortak Elektrik,Haziran 2026 elektrik faturası,2800,2026-06-30,AYEDAŞ,true
Asansör Bakımı,Periyodik bakım,3500,2026-06-15,Kone,true
Bina Temizliği,Aylık temizlik,4200,2026-06-01,Temizlik A.Ş.,false`;

export default function ExpensesPage() {
    const [expenses, setExpenses] = useState<Expense[]>([]);
    const [summary, setSummary] = useState<ExpenseSummary | null>(null);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [filterStatus, setFilterStatus] = useState("all");
    const [editingId, setEditingId] = useState<string | null>(null);
    const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);
    const csvRef = useRef<HTMLInputElement>(null);

    const [form, setForm] = useState({
        category_name: "Bina Temizliği",
        description: "",
        amount: 0,
        expense_date: new Date().toISOString().split("T")[0],
        is_invoiced: true,
        vendor_name: "",
    });

    useEffect(() => {
        apiClient.loadToken();
        load();
    }, []);

    async function load() {
        setLoading(true);
        try {
            const [expRes, sumRes] = await Promise.all([apiClient.getExpenses(), apiClient.getExpenseSummary()]);
            const raw = expRes?.data ?? expRes ?? [];
            setExpenses(raw.map((e: any) => ({ ...e, deleted: e.deleted ?? 0 })));
            setSummary(sumRes);
        } catch {
            setExpenses([
                { id: "1", category_name: "Ortak Elektrik", description: "Mayıs 2026 elektrik", amount: 2450.75, expense_date: "2026-05-28", is_invoiced: true, status: "APPROVED", vendor_name: "AYEDAŞ", deleted: 0 },
                { id: "2", category_name: "Asansör Bakımı", description: "Yıllık bakım", amount: 3500, expense_date: "2026-05-15", is_invoiced: true, status: "APPROVED", vendor_name: "Kone", deleted: 0 },
                { id: "3", category_name: "Acil Tamir", description: "Çatı tamir işlemi", amount: 1800, expense_date: "2026-05-20", is_invoiced: false, status: "PENDING", deleted: 0 },
            ]);
            setSummary({ total_expenses: 45750, invoiced_expenses: 42150, non_invoiced_expenses: 3600, assessment_reflecting: 28500, pending_approval_count: 2, pending_approval_amount: 3600 });
        } finally {
            setLoading(false);
        }
    }

    const openAdd = () => { setEditingId(null); setForm({ category_name: "Bina Temizliği", description: "", amount: 0, expense_date: new Date().toISOString().split("T")[0], is_invoiced: true, vendor_name: "" }); setIsModalOpen(true); };
    const openEdit = (exp: Expense) => { setEditingId(exp.id); setForm({ category_name: exp.category_name, description: exp.description, amount: exp.amount, expense_date: exp.expense_date, is_invoiced: exp.is_invoiced, vendor_name: exp.vendor_name ?? "" }); setIsModalOpen(true); };

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        if (editingId) {
            setExpenses(prev => prev.map(ex => ex.id === editingId ? { ...ex, ...form } : ex));
        } else {
            try {
                const res = await apiClient.createExpense({ category: form.category_name, description: form.description, amount: form.amount, expense_date: form.expense_date, vendor_name: form.vendor_name });
                setExpenses(prev => [{ ...res, deleted: 0 }, ...prev]);
            } catch {
                setExpenses(prev => [{ id: String(Date.now()), ...form, status: "PENDING", deleted: 0 }, ...prev]);
            }
        }
        setIsModalOpen(false); setEditingId(null);
    }

    const handleDelete = () => {
        if (!deleteConfirmId) return;
        setExpenses(prev => prev.map(e => e.id === deleteConfirmId ? { ...e, deleted: 1 } : e));
        setDeleteConfirmId(null);
    };

    const downloadSampleCSV = () => {
        const blob = new Blob([SAMPLE_CSV], { type: "text/csv;charset=utf-8;" });
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a"); a.href = url; a.download = "gider_ornek.csv"; a.click();
        URL.revokeObjectURL(url);
    };

    const handleCSVUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0]; if (!file) return;
        const reader = new FileReader();
        reader.onload = (ev) => {
            const text = ev.target?.result as string;
            const lines = text.trim().split("\n").slice(1);
            const newItems: Expense[] = lines.map((line, i) => {
                const [category_name, description, amount, expense_date, vendor_name, is_invoiced] = line.split(",");
                return { id: `csv_${Date.now()}_${i}`, category_name: (category_name ?? "").trim(), description: (description ?? "").trim(), amount: parseFloat((amount ?? "0").trim()) || 0, expense_date: (expense_date ?? "").trim(), vendor_name: (vendor_name ?? "").trim(), is_invoiced: (is_invoiced ?? "").trim().toLowerCase() === "true", status: "PENDING", deleted: 0 };
            });
            setExpenses(prev => [...newItems, ...prev]);
        };
        reader.readAsText(file);
        if (csvRef.current) csvRef.current.value = "";
    };

    const active = expenses.filter(e => e.deleted === 0);
    const filtered = filterStatus === "all" ? active : active.filter(e => e.status === filterStatus);

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Gider Yönetimi</h1>
                    <p className="text-sm text-gray-500">Ortak alan giderleri ve fatura takibi</p>
                </div>
                <div className="flex items-center gap-2">
                    <button onClick={downloadSampleCSV} className="flex items-center gap-2 rounded-lg border border-gray-300 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">
                        <Download className="h-4 w-4" /> Örnek CSV
                    </button>
                    <label className="flex items-center gap-2 rounded-lg border border-gray-300 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 cursor-pointer">
                        <Upload className="h-4 w-4" /> CSV Yükle
                        <input ref={csvRef} type="file" accept=".csv" className="hidden" onChange={handleCSVUpload} />
                    </label>
                    <button onClick={openAdd} className="flex items-center gap-2 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700">
                        <Plus className="h-4 w-4" /> Gider Ekle
                    </button>
                </div>
            </div>

            <div className="grid gap-4 md:grid-cols-4">
                {[
                    { label: "Toplam Gider", value: `₺${(summary?.total_expenses ?? active.reduce((s, e) => s + e.amount, 0)).toLocaleString()}`, color: "text-red-600" },
                    { label: "Faturalı", value: `₺${(summary?.invoiced_expenses ?? active.filter(e => e.is_invoiced).reduce((s, e) => s + e.amount, 0)).toLocaleString()}`, color: "text-green-600" },
                    { label: "Faturasız", value: `₺${(summary?.non_invoiced_expenses ?? active.filter(e => !e.is_invoiced).reduce((s, e) => s + e.amount, 0)).toLocaleString()}`, color: "text-orange-600" },
                    { label: "Onay Bekliyor", value: String(summary?.pending_approval_count ?? active.filter(e => e.status === "PENDING").length), color: "text-yellow-600" },
                ].map((s) => (
                    <div key={s.label} className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
                        <p className="text-sm text-gray-500">{s.label}</p>
                        <p className={`mt-1 text-2xl font-bold ${s.color}`}>{s.value}</p>
                    </div>
                ))}
            </div>

            <div className="flex gap-2">
                {["all", "APPROVED", "PENDING"].map(s => (
                    <button key={s} onClick={() => setFilterStatus(s)}
                        className={`rounded-lg px-4 py-2 text-sm font-medium transition-colors ${filterStatus === s ? "bg-primary text-white" : "bg-white text-gray-600 hover:bg-gray-50 dark:bg-gray-800 dark:text-gray-300"}`}>
                        {s === "all" ? "Tümü" : s === "APPROVED" ? "Onaylı" : "Bekleyen"}
                    </button>
                ))}
            </div>

            <div className="rounded-xl bg-white shadow-sm dark:bg-gray-800">
                {loading ? (
                    <div className="flex items-center justify-center py-12"><Loader2 className="h-8 w-8 animate-spin text-primary" /></div>
                ) : (
                    <table className="w-full">
                        <thead>
                            <tr className="border-b border-gray-200 dark:border-gray-700">
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Kategori</th>
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Açıklama</th>
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Tedarikçi</th>
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Tarih</th>
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Fatura</th>
                                <th className="px-6 py-3 text-right text-xs font-medium uppercase text-gray-500">Tutar</th>
                                <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Durum</th>
                                <th className="px-6 py-3 text-right text-xs font-medium uppercase text-gray-500">İşlem</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                            {filtered.map((exp) => {
                                const cfg = categoryConfig[exp.category_name] ?? categoryConfig.default;
                                const Icon = cfg.icon;
                                return (
                                    <tr key={exp.id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50">
                                        <td className="px-6 py-4">
                                            <span className="flex items-center gap-2 text-sm"><Icon className={`h-4 w-4 ${cfg.color}`} />{exp.category_name}</span>
                                        </td>
                                        <td className="px-6 py-4 text-sm text-gray-900 dark:text-white">{exp.description}</td>
                                        <td className="px-6 py-4 text-sm text-gray-500">{exp.vendor_name ?? "—"}</td>
                                        <td className="px-6 py-4 text-sm text-gray-500">{new Date(exp.expense_date).toLocaleDateString("tr-TR")}</td>
                                        <td className="px-6 py-4">
                                            {exp.is_invoiced
                                                ? <span className="flex items-center gap-1 text-xs text-green-600"><CheckCircle className="h-3 w-3" />Faturalı</span>
                                                : <span className="flex items-center gap-1 text-xs text-orange-500"><AlertCircle className="h-3 w-3" />Faturasız</span>}
                                        </td>
                                        <td className="px-6 py-4 text-right text-sm font-medium text-red-600">-₺{exp.amount.toLocaleString()}</td>
                                        <td className="px-6 py-4">
                                            <span className={`rounded-full px-2 py-1 text-xs font-medium ${exp.status === "APPROVED" ? "bg-green-100 text-green-700" : "bg-yellow-100 text-yellow-700"}`}>
                                                {exp.status === "APPROVED" ? "Onaylı" : "Bekliyor"}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 text-right">
                                            <div className="flex justify-end gap-1">
                                                <button onClick={() => openEdit(exp)} className="p-1.5 rounded hover:bg-blue-100 text-blue-500"><Edit className="h-4 w-4" /></button>
                                                <button onClick={() => setDeleteConfirmId(exp.id)} className="p-1.5 rounded hover:bg-red-100 text-red-500"><Trash2 className="h-4 w-4" /></button>
                                            </div>
                                        </td>
                                    </tr>
                                );
                            })}
                            {filtered.length === 0 && (
                                <tr><td colSpan={8} className="px-6 py-12 text-center text-gray-400">Kayıt bulunamadı</td></tr>
                            )}
                        </tbody>
                    </table>
                )}
            </div>

            {/* Add/Edit Modal */}
            {isModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-lg rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800 max-h-[90vh] overflow-y-auto">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">{editingId ? "Gideri Düzenle" : "Gider Ekle"}</h2>
                            <button onClick={() => { setIsModalOpen(false); setEditingId(null); }}><X className="h-5 w-5 text-gray-500" /></button>
                        </div>
                        <form onSubmit={handleSubmit} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Kategori</label>
                                <select value={form.category_name} onChange={e => setForm({ ...form, category_name: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700">
                                    {["Ortak Elektrik", "Ortak Su", "Bina Temizliği", "Güvenlik", "Asansör Bakımı", "Yönetici Ücreti", "Bahçe Bakımı", "Acil Tamir", "Diğer"].map(c => (
                                        <option key={c}>{c}</option>
                                    ))}
                                </select>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Açıklama</label>
                                <input required value={form.description} onChange={e => setForm({ ...form, description: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Tutar (₺)</label>
                                    <input type="number" required value={form.amount || ""} onChange={e => setForm({ ...form, amount: Number(e.target.value) })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Tarih</label>
                                    <input type="date" required value={form.expense_date} onChange={e => setForm({ ...form, expense_date: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Tedarikçi / Firma</label>
                                <input value={form.vendor_name} onChange={e => setForm({ ...form, vendor_name: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                            </div>
                            <div className="flex items-center gap-2">
                                <input type="checkbox" id="invoiced" checked={form.is_invoiced} onChange={e => setForm({ ...form, is_invoiced: e.target.checked })}
                                    className="h-4 w-4 rounded border-gray-300 text-primary" />
                                <label htmlFor="invoiced" className="text-sm text-gray-700 dark:text-gray-300">Fatura mevcut</label>
                            </div>
                            {form.is_invoiced && (
                                <div className="flex items-center justify-center h-20 border-2 border-dashed border-gray-300 rounded-lg cursor-pointer hover:border-primary">
                                    <div className="flex items-center gap-2 text-gray-500 text-sm"><Upload className="h-4 w-4" /> Fatura yükle (PDF)</div>
                                </div>
                            )}
                            <div className="flex gap-3 pt-2">
                                <button type="button" onClick={() => { setIsModalOpen(false); setEditingId(null); }} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">İptal</button>
                                <button type="submit" className="flex-1 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700">{editingId ? "Güncelle" : "Ekle"}</button>
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
                        <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-2">Gideri Sil</h2>
                        <p className="text-gray-500 text-sm mb-6">Bu gider kaydı silinecek. Emin misiniz?</p>
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
