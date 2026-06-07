"use client";

import { useState, useRef } from "react";
import { Plus, Calendar, Download, X, CalendarDays, Edit, Trash2, Upload } from "lucide-react";

const SAMPLE_CSV = `donem,vade_tarihi,tahakkuk_tutari,durum
Şubat 2026,2026-02-10,28800,active
Mart 2026,2026-03-10,28800,active`;

interface Assessment {
    id: number;
    period: string;
    totalAmount: number;
    collectedAmount: number;
    rate: number;
    dueDate: string;
    status: string;
    deleted: number;
}

const mockAssessments: Assessment[] = [
    { id: 1, period: "Ocak 2026", totalAmount: 28800, collectedAmount: 25056, rate: 87, dueDate: "2026-01-10", status: "active", deleted: 0 },
    { id: 2, period: "Aralık 2025", totalAmount: 27600, collectedAmount: 27600, rate: 100, dueDate: "2025-12-10", status: "completed", deleted: 0 },
    { id: 3, period: "Kasım 2025", totalAmount: 27600, collectedAmount: 27600, rate: 100, dueDate: "2025-11-10", status: "completed", deleted: 0 },
];

const expenseCategories = [
    { name: "Genel Yönetim", amount: 8500, distribution: "Arsa Payı" },
    { name: "Asansör Bakım", amount: 3200, distribution: "Eşit" },
    { name: "Temizlik Personeli", amount: 6800, distribution: "Eşit" },
    { name: "Bahçe Bakım", amount: 2400, distribution: "Metrekare" },
    { name: "Ortak Elektrik", amount: 4200, distribution: "Eşit" },
    { name: "Güvenlik", amount: 3700, distribution: "Eşit" },
];

export default function AssessmentsPage() {
    const [selectedYear, setSelectedYear] = useState(2026);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [assessments, setAssessments] = useState<Assessment[]>(mockAssessments);
    const [editingAssessment, setEditingAssessment] = useState<Assessment | null>(null);
    const [deleteConfirmId, setDeleteConfirmId] = useState<number | null>(null);
    const csvRef = useRef<HTMLInputElement>(null);

    const downloadSampleCSV = () => {
        const blob = new Blob([SAMPLE_CSV], { type: "text/csv;charset=utf-8;" });
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a"); a.href = url; a.download = "tahakkuk_ornek.csv"; a.click();
        URL.revokeObjectURL(url);
    };

    const handleCSVUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;
        const reader = new FileReader();
        reader.onload = (ev) => {
            const text = ev.target?.result as string;
            const rows = text.split("\n").slice(1).filter(r => r.trim());
            const imported: Assessment[] = rows.map((row, i) => {
                const [donem, vade, tahakkuk, durum] = row.split(",").map(s => s.trim());
                const total = Number(tahakkuk) || 0;
                return { id: Date.now() + i, period: donem ?? "", dueDate: vade ?? "", totalAmount: total, collectedAmount: 0, rate: 0, status: durum || "active", deleted: 0 };
            });
            setAssessments(prev => [...imported, ...prev]);
        };
        reader.readAsText(file);
        e.target.value = "";
    };
    const [formData, setFormData] = useState({
        period: "",
        dueDate: "",
        expenses: [
            { name: "Genel Yönetim", amount: 8500, distribution: "Arsa Payı" },
            { name: "Asansör Bakım", amount: 3200, distribution: "Eşit" },
            { name: "Temizlik Personeli", amount: 6800, distribution: "Eşit" },
        ],
    });

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        const totalAmount = formData.expenses.reduce((sum, exp) => sum + exp.amount, 0);
        const newAssessment: Assessment = {
            id: Date.now(),
            period: formData.period,
            totalAmount,
            collectedAmount: 0,
            rate: 0,
            dueDate: formData.dueDate,
            status: "active",
            deleted: 0,
        };
        setAssessments([newAssessment, ...assessments]);
        setFormData({
            period: "",
            dueDate: "",
            expenses: [
                { name: "Genel Yönetim", amount: 8500, distribution: "Arsa Payı" },
                { name: "Asansör Bakım", amount: 3200, distribution: "Eşit" },
                { name: "Temizlik Personeli", amount: 6800, distribution: "Eşit" },
            ],
        });
        setIsModalOpen(false);
    };

    const updateExpense = (idx: number, field: string, value: string | number) => {
        const updated = [...formData.expenses];
        updated[idx] = { ...updated[idx], [field]: field === "amount" ? Number(value) : value };
        setFormData({ ...formData, expenses: updated });
    };

    const addExpense = () => {
        setFormData({
            ...formData,
            expenses: [...formData.expenses, { name: "", amount: 0, distribution: "Eşit" }],
        });
    };

    const removeExpense = (idx: number) => {
        setFormData({
            ...formData,
            expenses: formData.expenses.filter((_, i) => i !== idx),
        });
    };

    const handleDeleteAssessment = () => {
        if (deleteConfirmId === null) return;
        setAssessments(prev => prev.map(a => a.id === deleteConfirmId ? { ...a, deleted: 1 } : a));
        setDeleteConfirmId(null);
    };

    const handleEditSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        if (!editingAssessment) return;
        setAssessments(prev => prev.map(a => a.id === editingAssessment.id ? editingAssessment : a));
        setEditingAssessment(null);
    };

    const activeAssessments = assessments.filter(a => a.deleted === 0);

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                        Aidat Yönetimi
                    </h1>
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                        Aylık aidat tahakkuk ve tahsilat
                    </p>
                </div>
                <div className="flex gap-3">
                    <button onClick={downloadSampleCSV} className="flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm font-medium hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:hover:bg-gray-700">
                        <Download className="h-4 w-4" /> Örnek CSV
                    </button>
                    <button onClick={() => csvRef.current?.click()} className="flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm font-medium hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:hover:bg-gray-700">
                        <Upload className="h-4 w-4" /> CSV Yükle
                    </button>
                    <input ref={csvRef} type="file" accept=".csv" className="hidden" onChange={handleCSVUpload} />
                    <button
                        onClick={() => setIsModalOpen(true)}
                        className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90"
                    >
                        <Plus className="h-4 w-4" />
                        Yeni Tahakkuk
                    </button>
                </div>
            </div>

            {/* Filters */}
            <div className="flex gap-4">
                <select
                    value={selectedYear}
                    onChange={(e) => setSelectedYear(Number(e.target.value))}
                    className="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-800"
                >
                    <option value={2026}>2026</option>
                    <option value={2025}>2025</option>
                    <option value={2024}>2024</option>
                </select>
            </div>

            {/* Summary Cards */}
            <div className="grid gap-4 md:grid-cols-3">
                <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                    <p className="text-sm text-gray-500">Toplam Tahakkuk</p>
                    <p className="mt-2 text-2xl font-bold text-gray-900 dark:text-white">
                        ₺28.800
                    </p>
                    <p className="mt-1 text-sm text-gray-500">Ocak 2026</p>
                </div>
                <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                    <p className="text-sm text-gray-500">Tahsil Edilen</p>
                    <p className="mt-2 text-2xl font-bold text-green-500">₺25.056</p>
                    <p className="mt-1 text-sm text-gray-500">%87 tahsilat oranı</p>
                </div>
                <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                    <p className="text-sm text-gray-500">Bekleyen</p>
                    <p className="mt-2 text-2xl font-bold text-red-500">₺3.744</p>
                    <p className="mt-1 text-sm text-gray-500">4 dairede borç var</p>
                </div>
            </div>

            {/* Expense Categories */}
            <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                <h3 className="mb-4 text-lg font-semibold text-gray-900 dark:text-white">
                    Gider Kalemleri (Ocak 2026)
                </h3>
                <div className="overflow-x-auto">
                    <table className="w-full">
                        <thead>
                            <tr className="border-b border-gray-200 dark:border-gray-700">
                                <th className="py-3 text-left text-sm font-medium text-gray-500">
                                    Gider Kalemi
                                </th>
                                <th className="py-3 text-left text-sm font-medium text-gray-500">
                                    Dağıtım Şekli
                                </th>
                                <th className="py-3 text-right text-sm font-medium text-gray-500">
                                    Toplam Tutar
                                </th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                            {expenseCategories.map((cat, idx) => (
                                <tr key={idx}>
                                    <td className="py-3 text-gray-900 dark:text-white">
                                        {cat.name}
                                    </td>
                                    <td className="py-3">
                                        <span className="rounded-full bg-gray-100 px-3 py-1 text-xs font-medium text-gray-600 dark:bg-gray-700 dark:text-gray-300">
                                            {cat.distribution}
                                        </span>
                                    </td>
                                    <td className="py-3 text-right font-medium text-gray-900 dark:text-white">
                                        ₺{cat.amount.toLocaleString()}
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                        <tfoot>
                            <tr className="border-t-2 border-gray-300 dark:border-gray-600">
                                <td colSpan={2} className="py-3 font-bold text-gray-900 dark:text-white">
                                    Toplam
                                </td>
                                <td className="py-3 text-right font-bold text-gray-900 dark:text-white">
                                    ₺{expenseCategories.reduce((sum, c) => sum + c.amount, 0).toLocaleString()}
                                </td>
                            </tr>
                        </tfoot>
                    </table>
                </div>
            </div>

            {/* Assessment History */}
            <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                <h3 className="mb-4 text-lg font-semibold text-gray-900 dark:text-white">
                    Tahakkuk Geçmişi
                </h3>
                <table className="w-full">
                    <thead>
                        <tr className="border-b border-gray-200 dark:border-gray-700">
                            <th className="py-3 text-left text-sm font-medium text-gray-500">Dönem</th>
                            <th className="py-3 text-left text-sm font-medium text-gray-500">Vade Tarihi</th>
                            <th className="py-3 text-right text-sm font-medium text-gray-500">Tahakkuk</th>
                            <th className="py-3 text-right text-sm font-medium text-gray-500">Tahsilat</th>
                            <th className="py-3 text-right text-sm font-medium text-gray-500">Oran</th>
                            <th className="py-3 text-center text-sm font-medium text-gray-500">Durum</th>
                            <th className="py-3 text-right text-sm font-medium text-gray-500">İşlem</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                        {activeAssessments.map((a) => (
                            <tr key={a.id}>
                                <td className="py-3 font-medium text-gray-900 dark:text-white">{a.period}</td>
                                <td className="py-3 text-gray-600 dark:text-gray-400">{new Date(a.dueDate).toLocaleDateString("tr-TR")}</td>
                                <td className="py-3 text-right text-gray-900 dark:text-white">₺{a.totalAmount.toLocaleString()}</td>
                                <td className="py-3 text-right text-gray-900 dark:text-white">₺{a.collectedAmount.toLocaleString()}</td>
                                <td className="py-3 text-right">
                                    <span className={a.rate === 100 ? "text-green-500" : a.rate >= 80 ? "text-yellow-500" : "text-red-500"}>
                                        %{a.rate}
                                    </span>
                                </td>
                                <td className="py-3 text-center">
                                    <span className={`rounded-full px-3 py-1 text-xs font-medium ${a.status === "completed" ? "bg-green-100 text-green-700" : "bg-yellow-100 text-yellow-700"}`}>
                                        {a.status === "completed" ? "Tamamlandı" : "Aktif"}
                                    </span>
                                </td>
                                <td className="py-3 text-right">
                                    <div className="flex justify-end gap-1">
                                        <button onClick={() => setEditingAssessment({ ...a })} className="p-1.5 rounded hover:bg-blue-100 text-blue-500"><Edit className="h-4 w-4" /></button>
                                        <button onClick={() => setDeleteConfirmId(a.id)} className="p-1.5 rounded hover:bg-red-100 text-red-500"><Trash2 className="h-4 w-4" /></button>
                                    </div>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>

            {/* Edit Assessment Modal */}
            {editingAssessment && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">Tahakkuku Düzenle</h2>
                            <button onClick={() => setEditingAssessment(null)}><X className="h-5 w-5 text-gray-500" /></button>
                        </div>
                        <form onSubmit={handleEditSubmit} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Dönem</label>
                                <input required value={editingAssessment.period} onChange={e => setEditingAssessment({ ...editingAssessment, period: e.target.value })} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Vade Tarihi</label>
                                <input type="date" value={editingAssessment.dueDate} onChange={e => setEditingAssessment({ ...editingAssessment, dueDate: e.target.value })} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Tahakkuk (₺)</label>
                                    <input type="number" value={editingAssessment.totalAmount} onChange={e => setEditingAssessment({ ...editingAssessment, totalAmount: Number(e.target.value) })} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Tahsilat (₺)</label>
                                    <input type="number" value={editingAssessment.collectedAmount} onChange={e => {
                                        const col = Number(e.target.value);
                                        const rate = editingAssessment.totalAmount > 0 ? Math.round((col / editingAssessment.totalAmount) * 100) : 0;
                                        setEditingAssessment({ ...editingAssessment, collectedAmount: col, rate });
                                    }} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Durum</label>
                                <select value={editingAssessment.status} onChange={e => setEditingAssessment({ ...editingAssessment, status: e.target.value })} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700">
                                    <option value="active">Aktif</option>
                                    <option value="completed">Tamamlandı</option>
                                </select>
                            </div>
                            <div className="flex gap-3 pt-2">
                                <button type="button" onClick={() => setEditingAssessment(null)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">İptal</button>
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
                        <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-2">Tahakkuku Sil</h2>
                        <p className="text-gray-500 text-sm mb-6">Bu tahakkuk kaydı silinecek. Emin misiniz?</p>
                        <div className="flex gap-3">
                            <button onClick={() => setDeleteConfirmId(null)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">İptal</button>
                            <button onClick={handleDeleteAssessment} className="flex-1 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700">Sil</button>
                        </div>
                    </div>
                </div>
            )}

            {/* Modal */}
            {isModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-2xl rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800 max-h-[90vh] overflow-y-auto">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">
                                Yeni Tahakkuk Oluştur
                            </h2>
                            <button
                                onClick={() => setIsModalOpen(false)}
                                className="rounded-lg p-1 hover:bg-gray-100 dark:hover:bg-gray-700"
                            >
                                <X className="h-5 w-5 text-gray-500" />
                            </button>
                        </div>
                        <form onSubmit={handleSubmit} className="space-y-4">
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                        Dönem
                                    </label>
                                    <div className="relative">
                                        <CalendarDays className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                                        <input
                                            type="text"
                                            required
                                            value={formData.period}
                                            onChange={(e) => setFormData({ ...formData, period: e.target.value })}
                                            className="w-full rounded-lg border border-gray-300 bg-white py-2 pl-10 pr-4 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                                            placeholder="Şubat 2026"
                                        />
                                    </div>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                        Son Ödeme Tarihi
                                    </label>
                                    <input
                                        type="date"
                                        required
                                        value={formData.dueDate}
                                        onChange={(e) => setFormData({ ...formData, dueDate: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                                    />
                                </div>
                            </div>

                            <div>
                                <div className="flex items-center justify-between mb-2">
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                                        Gider Kalemleri
                                    </label>
                                    <button
                                        type="button"
                                        onClick={addExpense}
                                        className="text-sm text-primary hover:underline"
                                    >
                                        + Kalem Ekle
                                    </button>
                                </div>
                                <div className="space-y-2">
                                    {formData.expenses.map((exp, idx) => (
                                        <div key={idx} className="flex items-center gap-2">
                                            <input
                                                type="text"
                                                value={exp.name}
                                                onChange={(e) => updateExpense(idx, "name", e.target.value)}
                                                className="flex-1 rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm focus:border-primary focus:outline-none dark:border-gray-600 dark:bg-gray-700"
                                                placeholder="Kalem adı"
                                            />
                                            <input
                                                type="number"
                                                value={exp.amount}
                                                onChange={(e) => updateExpense(idx, "amount", e.target.value)}
                                                className="w-28 rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm focus:border-primary focus:outline-none dark:border-gray-600 dark:bg-gray-700"
                                                placeholder="Tutar"
                                            />
                                            <select
                                                value={exp.distribution}
                                                onChange={(e) => updateExpense(idx, "distribution", e.target.value)}
                                                className="rounded-lg border border-gray-300 bg-white px-2 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                            >
                                                <option>Eşit</option>
                                                <option>Arsa Payı</option>
                                                <option>Metrekare</option>
                                            </select>
                                            {formData.expenses.length > 1 && (
                                                <button
                                                    type="button"
                                                    onClick={() => removeExpense(idx)}
                                                    className="p-1 text-red-500 hover:bg-red-50 rounded"
                                                >
                                                    <X className="h-4 w-4" />
                                                </button>
                                            )}
                                        </div>
                                    ))}
                                </div>
                                <div className="mt-2 text-right">
                                    <span className="text-sm text-gray-500">Toplam: </span>
                                    <span className="font-bold text-gray-900 dark:text-white">
                                        ₺{formData.expenses.reduce((sum, exp) => sum + exp.amount, 0).toLocaleString()}
                                    </span>
                                </div>
                            </div>

                            <div className="flex gap-3 pt-4">
                                <button
                                    type="button"
                                    onClick={() => setIsModalOpen(false)}
                                    className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
                                >
                                    İptal
                                </button>
                                <button
                                    type="submit"
                                    className="flex-1 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90"
                                >
                                    Tahakkuk Oluştur
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
