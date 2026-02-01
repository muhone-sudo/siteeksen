"use client";

import { useState } from "react";
import { Plus, Calendar, Download, Filter } from "lucide-react";

const mockAssessments = [
    {
        id: 1,
        period: "Ocak 2026",
        totalAmount: 28800,
        collectedAmount: 25056,
        rate: 87,
        dueDate: "2026-01-10",
        status: "active",
    },
    {
        id: 2,
        period: "Aralık 2025",
        totalAmount: 27600,
        collectedAmount: 27600,
        rate: 100,
        dueDate: "2025-12-10",
        status: "completed",
    },
    {
        id: 3,
        period: "Kasım 2025",
        totalAmount: 27600,
        collectedAmount: 27600,
        rate: 100,
        dueDate: "2025-11-10",
        status: "completed",
    },
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
                    <button className="flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:hover:bg-gray-700">
                        <Download className="h-4 w-4" />
                        Rapor İndir
                    </button>
                    <button className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90">
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
                            <th className="py-3 text-left text-sm font-medium text-gray-500">
                                Dönem
                            </th>
                            <th className="py-3 text-left text-sm font-medium text-gray-500">
                                Vade Tarihi
                            </th>
                            <th className="py-3 text-right text-sm font-medium text-gray-500">
                                Tahakkuk
                            </th>
                            <th className="py-3 text-right text-sm font-medium text-gray-500">
                                Tahsilat
                            </th>
                            <th className="py-3 text-right text-sm font-medium text-gray-500">
                                Oran
                            </th>
                            <th className="py-3 text-center text-sm font-medium text-gray-500">
                                Durum
                            </th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                        {mockAssessments.map((a) => (
                            <tr key={a.id}>
                                <td className="py-3 font-medium text-gray-900 dark:text-white">
                                    {a.period}
                                </td>
                                <td className="py-3 text-gray-600 dark:text-gray-400">
                                    {new Date(a.dueDate).toLocaleDateString("tr-TR")}
                                </td>
                                <td className="py-3 text-right text-gray-900 dark:text-white">
                                    ₺{a.totalAmount.toLocaleString()}
                                </td>
                                <td className="py-3 text-right text-gray-900 dark:text-white">
                                    ₺{a.collectedAmount.toLocaleString()}
                                </td>
                                <td className="py-3 text-right">
                                    <span
                                        className={
                                            a.rate === 100
                                                ? "text-green-500"
                                                : a.rate >= 80
                                                    ? "text-yellow-500"
                                                    : "text-red-500"
                                        }
                                    >
                                        %{a.rate}
                                    </span>
                                </td>
                                <td className="py-3 text-center">
                                    <span
                                        className={`rounded-full px-3 py-1 text-xs font-medium ${a.status === "completed"
                                                ? "bg-green-100 text-green-700"
                                                : "bg-yellow-100 text-yellow-700"
                                            }`}
                                    >
                                        {a.status === "completed" ? "Tamamlandı" : "Aktif"}
                                    </span>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
}
