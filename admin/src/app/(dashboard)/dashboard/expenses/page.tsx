"use client";

import { useState, useEffect } from "react";
import { Plus, X, TrendingDown, FileText, Zap, Wrench, Building, Users, Receipt, CreditCard, Upload, CheckCircle, AlertCircle, Loader2 } from "lucide-react";
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

export default function ExpensesPage() {
    const [expenses, setExpenses] = useState<Expense[]>([]);
    const [summary, setSummary] = useState<ExpenseSummary | null>(null);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [filterStatus, setFilterStatus] = useState("all");
    const [form, setForm] = useState({
        category: "Bina Temizliği",
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
            const [expRes, sumRes] = await Promise.all([
                apiClient.getExpenses(),
                apiClient.getExpenseSummary(),
            ]);
            setExpenses(expRes?.data ?? expRes ?? []);
            setSummary(sumRes);
        } catch {
            setExpenses([
                { id: "1", category_name: "Ortak Elektrik", description: "Mayıs 2026 elektrik", amount: 2450.75, expense_date: "2026-05-28", is_invoiced: true, status: "APPROVED", vendor_name: "AYEDAŞ" },
                { id: "2", category_name: "Asansör Bakımı", description: "Yıllık bakım", amount: 3500, expense_date: "2026-05-15", is_invoiced: true, status: "APPROVED", vendor_name: "Kone" },
                { id: "3", category_name: "Acil Tamir", description: "Çatı tamir işlemi", amount: 1800, expense_date: "2026-05-20", is_invoiced: false, status: "PENDING" },
            ]);
            setSummary({ total_expenses: 45750, invoiced_expenses: 42150, non_invoiced_expenses: 3600, assessment_reflecting: 28500, pending_approval_count: 2, pending_approval_amount: 3600 });
        } finally {
            setLoading(false);
        }
    }

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        try {
            const res = await apiClient.createExpense({
                category: form.category,
                description: form.description,
                amount: form.amount,
                expense_date: form.expense_date,
                vendor_name: form.vendor_name,
            });
            setExpenses(prev => [res, ...prev]);
        } catch {
            setExpenses(prev => [{ id: String(Date.now()), category_name: form.category, description: form.description, amount: form.amount, expense_date: form.expense_date, is_invoiced: form.is_invoiced, status: "PENDING", vendor_name: form.vendor_name }, ...prev]);
        }
        setIsModalOpen(false);
        setForm({ category: "Bina Temizliği", description: "", amount: 0, expense_date: new Date().toISOString().split("T")[0], is_invoiced: true, vendor_name: "" });
    }

    const filtered = filterStatus === "all" ? expenses : expenses.filter(e => e.status === filterStatus);

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Gider Yönetimi</h1>
                    <p className="text-sm text-gray-500">Ortak alan giderleri ve fatura takibi</p>
                </div>
                <button onClick={() => setIsModalOpen(true)} className="flex items-center gap-2 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700">
                    <Plus className="h-4 w-4" /> Gider Ekle
                </button>
            </div>

            {/* Summary */}
            <div className="grid gap-4 md:grid-cols-4">
                {[
                    { label: "Toplam Gider", value: `₺${(summary?.total_expenses ?? 0).toLocaleString()}`, color: "text-red-600" },
                    { label: "Faturalı", value: `₺${(summary?.invoiced_expenses ?? 0).toLocaleString()}`, color: "text-green-600" },
                    { label: "Faturasız", value: `₺${(summary?.non_invoiced_expenses ?? 0).toLocaleString()}`, color: "text-orange-600" },
                    { label: "Onay Bekliyor", value: String(summary?.pending_approval_count ?? 0), color: "text-yellow-600" },
                ].map((s) => (
                    <div key={s.label} className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
                        <p className="text-sm text-gray-500">{s.label}</p>
                        <p className={`mt-1 text-2xl font-bold ${s.color}`}>{s.value}</p>
                    </div>
                ))}
            </div>

            {/* Filter */}
            <div className="flex gap-2">
                {["all", "APPROVED", "PENDING"].map(s => (
                    <button key={s} onClick={() => setFilterStatus(s)}
                        className={`rounded-lg px-4 py-2 text-sm font-medium transition-colors ${filterStatus === s ? "bg-primary text-white" : "bg-white text-gray-600 hover:bg-gray-50 dark:bg-gray-800 dark:text-gray-300"}`}>
                        {s === "all" ? "Tümü" : s === "APPROVED" ? "Onaylı" : "Bekleyen"}
                    </button>
                ))}
            </div>

            {/* Table */}
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
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                            {filtered.map((exp) => {
                                const cfg = categoryConfig[exp.category_name] ?? categoryConfig.default;
                                const Icon = cfg.icon;
                                return (
                                    <tr key={exp.id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50">
                                        <td className="px-6 py-4">
                                            <span className="flex items-center gap-2 text-sm">
                                                <Icon className={`h-4 w-4 ${cfg.color}`} />
                                                {exp.category_name}
                                            </span>
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
                                    </tr>
                                );
                            })}
                        </tbody>
                    </table>
                )}
            </div>

            {/* Modal */}
            {isModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-lg rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800 max-h-[90vh] overflow-y-auto">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">Gider Ekle</h2>
                            <button onClick={() => setIsModalOpen(false)}><X className="h-5 w-5 text-gray-500" /></button>
                        </div>
                        <form onSubmit={handleSubmit} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Kategori</label>
                                <select value={form.category} onChange={e => setForm({ ...form, category: e.target.value })}
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
                                <label htmlFor="invoiced" className="text-sm text-gray-700 dark:text-gray-300">
                                    Fatura mevcut
                                </label>
                            </div>
                            {form.is_invoiced && (
                                <div className="flex items-center justify-center h-20 border-2 border-dashed border-gray-300 rounded-lg cursor-pointer hover:border-primary">
                                    <div className="flex items-center gap-2 text-gray-500 text-sm">
                                        <Upload className="h-4 w-4" /> Fatura yükle (PDF)
                                    </div>
                                </div>
                            )}
                            <div className="flex gap-3 pt-2">
                                <button type="button" onClick={() => setIsModalOpen(false)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">İptal</button>
                                <button type="submit" className="flex-1 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700">Ekle</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
