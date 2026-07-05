"use client";

import { useState } from "react";
import { Plus, CalendarDays, X } from "lucide-react";
import { useAssessmentOverview, useCreateAssessment, useExpenseCategories, useDebtors } from "@/lib/hooks";

const MONTHS = [
    "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
    "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık",
];

const currentYear = new Date().getFullYear();

interface AssessmentPeriod {
    period: string;
    due_date: string;
    total_amount: number;
    collected_amount: number;
    rate: number;
    status: string;
}

interface ExpenseCategory {
    id: string;
    name: string;
    distribution_type: string;
}

interface Debtor {
    resident_id: string;
    name: string;
    unit: string;
    amount: number;
}

interface ExpenseItemForm {
    categoryId: string;
    amount: number;
}

function formatPeriod(period: string) {
    const [year, month] = period.split("-").map(Number);
    return `${MONTHS[(month || 1) - 1]} ${year}`;
}

function distributionLabel(type: string) {
    switch (type) {
        case "SHARE_RATIO": return "Arsa Payı";
        case "EQUAL": return "Eşit";
        case "AREA_M2": return "Metrekare";
        default: return type;
    }
}

function errorMessage(err: unknown, fallback: string): string {
    if (err && typeof err === "object" && "response" in err) {
        const response = (err as { response?: { data?: { error?: string } } }).response;
        if (response?.data?.error) return response.data.error;
    }
    return fallback;
}

const emptyForm = () => ({
    periodYear: currentYear,
    periodMonth: new Date().getMonth() + 1,
    dueDate: "",
    expenses: [{ categoryId: "", amount: 0 }] as ExpenseItemForm[],
});

export default function AssessmentsPage() {
    const [selectedYear, setSelectedYear] = useState(currentYear);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [formError, setFormError] = useState<string | null>(null);
    const [formData, setFormData] = useState(emptyForm);

    const { data: overviewData, isLoading: overviewLoading } = useAssessmentOverview({ year: selectedYear });
    const { data: categoriesData, isLoading: categoriesLoading } = useExpenseCategories();
    const { data: debtorsData } = useDebtors();
    const createAssessment = useCreateAssessment();

    const periods: AssessmentPeriod[] = overviewData?.data ?? [];
    const categories: ExpenseCategory[] = categoriesData?.data ?? [];
    const debtors: Debtor[] = debtorsData?.data ?? [];

    const totalDebt = debtors.reduce((sum, d) => sum + d.amount, 0);
    const latestPeriod = periods[0];
    const totalFormAmount = formData.expenses.reduce((sum, exp) => sum + exp.amount, 0);

    const openModal = () => {
        setFormError(null);
        setFormData(emptyForm());
        setIsModalOpen(true);
    };

    const updateExpense = (idx: number, field: "categoryId" | "amount", value: string | number) => {
        const updated = [...formData.expenses];
        updated[idx] = { ...updated[idx], [field]: field === "amount" ? Number(value) : value };
        setFormData({ ...formData, expenses: updated });
    };

    const addExpense = () => {
        setFormData({ ...formData, expenses: [...formData.expenses, { categoryId: "", amount: 0 }] });
    };

    const removeExpense = (idx: number) => {
        setFormData({ ...formData, expenses: formData.expenses.filter((_, i) => i !== idx) });
    };

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        setFormError(null);
        const items = formData.expenses
            .filter((exp) => exp.categoryId && exp.amount > 0)
            .map((exp) => ({ category_id: exp.categoryId, amount: exp.amount }));
        if (items.length === 0) {
            setFormError("En az bir gider kalemi seçip tutar girmelisiniz.");
            return;
        }
        createAssessment.mutate(
            {
                period_year: formData.periodYear,
                period_month: formData.periodMonth,
                due_date: formData.dueDate,
                expense_items: items,
            },
            {
                onSuccess: () => setIsModalOpen(false),
                onError: (err) => setFormError(errorMessage(err, "Tahakkuk oluşturulamadı")),
            }
        );
    };

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
                <button
                    onClick={openModal}
                    className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90"
                >
                    <Plus className="h-4 w-4" />
                    Yeni Tahakkuk
                </button>
            </div>

            {/* Filters */}
            <div className="flex gap-4">
                <select
                    value={selectedYear}
                    onChange={(e) => setSelectedYear(Number(e.target.value))}
                    className="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-800"
                >
                    {[currentYear, currentYear - 1, currentYear - 2].map((y) => (
                        <option key={y} value={y}>{y}</option>
                    ))}
                </select>
            </div>

            {/* Summary Cards */}
            <div className="grid gap-4 md:grid-cols-3">
                <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                    <p className="text-sm text-gray-500">Son Dönem Tahakkuku</p>
                    <p className="mt-2 text-2xl font-bold text-gray-900 dark:text-white">
                        ₺{(latestPeriod?.total_amount ?? 0).toLocaleString("tr-TR")}
                    </p>
                    <p className="mt-1 text-sm text-gray-500">
                        {latestPeriod ? formatPeriod(latestPeriod.period) : "Tahakkuk kaydı yok"}
                    </p>
                </div>
                <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                    <p className="text-sm text-gray-500">Tahsil Edilen</p>
                    <p className="mt-2 text-2xl font-bold text-green-500">
                        ₺{(latestPeriod?.collected_amount ?? 0).toLocaleString("tr-TR")}
                    </p>
                    <p className="mt-1 text-sm text-gray-500">%{latestPeriod?.rate ?? 0} tahsilat oranı</p>
                </div>
                <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                    <p className="text-sm text-gray-500">Bekleyen</p>
                    <p className="mt-2 text-2xl font-bold text-red-500">
                        ₺{totalDebt.toLocaleString("tr-TR")}
                    </p>
                    <p className="mt-1 text-sm text-gray-500">{debtors.length} sakinde borç var</p>
                </div>
            </div>

            {/* Expense Categories */}
            <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                <h3 className="mb-4 text-lg font-semibold text-gray-900 dark:text-white">
                    Tanımlı Gider Kalemleri
                </h3>
                {categoriesLoading ? (
                    <p className="text-sm text-gray-500">Yükleniyor...</p>
                ) : categories.length === 0 ? (
                    <p className="text-sm text-gray-500">Henüz tanımlı gider kalemi yok.</p>
                ) : (
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
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                                {categories.map((cat) => (
                                    <tr key={cat.id}>
                                        <td className="py-3 text-gray-900 dark:text-white">
                                            {cat.name}
                                        </td>
                                        <td className="py-3">
                                            <span className="rounded-full bg-gray-100 px-3 py-1 text-xs font-medium text-gray-600 dark:bg-gray-700 dark:text-gray-300">
                                                {distributionLabel(cat.distribution_type)}
                                            </span>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            {/* Assessment History */}
            <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                <h3 className="mb-4 text-lg font-semibold text-gray-900 dark:text-white">
                    Tahakkuk Geçmişi
                </h3>
                {overviewLoading ? (
                    <p className="text-sm text-gray-500">Yükleniyor...</p>
                ) : periods.length === 0 ? (
                    <p className="text-sm text-gray-500">{selectedYear} yılında tahakkuk kaydı yok.</p>
                ) : (
                    <table className="w-full">
                        <thead>
                            <tr className="border-b border-gray-200 dark:border-gray-700">
                                <th className="py-3 text-left text-sm font-medium text-gray-500">Dönem</th>
                                <th className="py-3 text-left text-sm font-medium text-gray-500">Vade Tarihi</th>
                                <th className="py-3 text-right text-sm font-medium text-gray-500">Tahakkuk</th>
                                <th className="py-3 text-right text-sm font-medium text-gray-500">Tahsilat</th>
                                <th className="py-3 text-right text-sm font-medium text-gray-500">Oran</th>
                                <th className="py-3 text-center text-sm font-medium text-gray-500">Durum</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                            {periods.map((p) => (
                                <tr key={p.period}>
                                    <td className="py-3 font-medium text-gray-900 dark:text-white">{formatPeriod(p.period)}</td>
                                    <td className="py-3 text-gray-600 dark:text-gray-400">{new Date(p.due_date).toLocaleDateString("tr-TR")}</td>
                                    <td className="py-3 text-right text-gray-900 dark:text-white">₺{p.total_amount.toLocaleString("tr-TR")}</td>
                                    <td className="py-3 text-right text-gray-900 dark:text-white">₺{p.collected_amount.toLocaleString("tr-TR")}</td>
                                    <td className="py-3 text-right">
                                        <span className={p.rate === 100 ? "text-green-500" : p.rate >= 80 ? "text-yellow-500" : "text-red-500"}>
                                            %{p.rate}
                                        </span>
                                    </td>
                                    <td className="py-3 text-center">
                                        <span className={`rounded-full px-3 py-1 text-xs font-medium ${p.status === "completed" ? "bg-green-100 text-green-700" : "bg-yellow-100 text-yellow-700"}`}>
                                            {p.status === "completed" ? "Tamamlandı" : "Aktif"}
                                        </span>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}
            </div>

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
                            {formError && (
                                <div className="rounded-lg bg-red-50 px-4 py-2 text-sm text-red-600 dark:bg-red-900/30 dark:text-red-400">
                                    {formError}
                                </div>
                            )}
                            <div className="grid grid-cols-3 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                        Yıl
                                    </label>
                                    <input
                                        type="number"
                                        required
                                        value={formData.periodYear}
                                        onChange={(e) => setFormData({ ...formData, periodYear: Number(e.target.value) })}
                                        className="w-full rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                        Ay
                                    </label>
                                    <select
                                        value={formData.periodMonth}
                                        onChange={(e) => setFormData({ ...formData, periodMonth: Number(e.target.value) })}
                                        className="w-full rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                                    >
                                        {MONTHS.map((m, i) => (
                                            <option key={m} value={i + 1}>{m}</option>
                                        ))}
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                        Son Ödeme Tarihi
                                    </label>
                                    <div className="relative">
                                        <CalendarDays className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                                        <input
                                            type="date"
                                            required
                                            value={formData.dueDate}
                                            onChange={(e) => setFormData({ ...formData, dueDate: e.target.value })}
                                            className="w-full rounded-lg border border-gray-300 bg-white py-2 pl-10 pr-4 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                                        />
                                    </div>
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
                                            <select
                                                required
                                                value={exp.categoryId}
                                                onChange={(e) => updateExpense(idx, "categoryId", e.target.value)}
                                                className="flex-1 rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm focus:border-primary focus:outline-none dark:border-gray-600 dark:bg-gray-700"
                                            >
                                                <option value="">Gider kalemi seçin</option>
                                                {categories.map((cat) => (
                                                    <option key={cat.id} value={cat.id}>
                                                        {cat.name} ({distributionLabel(cat.distribution_type)})
                                                    </option>
                                                ))}
                                            </select>
                                            <input
                                                type="number"
                                                required
                                                min={0}
                                                value={exp.amount || ""}
                                                onChange={(e) => updateExpense(idx, "amount", e.target.value)}
                                                className="w-32 rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm focus:border-primary focus:outline-none dark:border-gray-600 dark:bg-gray-700"
                                                placeholder="Tutar (₺)"
                                            />
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
                                        ₺{totalFormAmount.toLocaleString("tr-TR")}
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
                                    disabled={createAssessment.isPending}
                                    className="flex-1 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90 disabled:opacity-50"
                                >
                                    {createAssessment.isPending ? "Oluşturuluyor..." : "Tahakkuk Oluştur"}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
