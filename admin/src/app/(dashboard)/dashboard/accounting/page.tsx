"use client";

import { useState, useEffect } from "react";
import apiClient from "@/lib/api-client";
import {
    Plus,
    X,
    Upload,
    FileText,
    DollarSign,
    TrendingUp,
    TrendingDown,
    Users,
    Zap,
    Wrench,
    Building,
    Receipt,
    CreditCard,
    Calendar,
    Check,
} from "lucide-react";

// Types
interface DuesDecision {
    id: number;
    amount: number;
    distributionMethod: "equal" | "landShare" | "sqm";
    effectiveDate: string;
    decisionNo: string;
    pageNo: string;
    decisionDate: string;
    summary: string;
    documentUrl?: string;
}

interface Income {
    id: number;
    type: "dues" | "service" | "rent" | "sale" | "other";
    description: string;
    amount: number;
    date: string;
    paidBy?: string;
}

interface Expense {
    id: number;
    category: "personnel" | "utility" | "maintenance" | "repair" | "admin" | "insurance" | "other";
    description: string;
    amount: number;
    date: string;
    isRecurring: boolean;
}

interface Personnel {
    id: number;
    name: string;
    role: string;
    salary: number; // Görüntülemede maskelenecek
}

// Mock data
const mockPersonnel: Personnel[] = [
    { id: 1, name: "Ahmet Güvenlik", role: "Güvenlik", salary: 22000 },
    { id: 2, name: "Fatma Temizlik", role: "Temizlik", salary: 18000 },
    { id: 3, name: "Mehmet Bahçıvan", role: "Bahçıvan", salary: 16000 },
];

const mockDuesDecisions: DuesDecision[] = [
    {
        id: 1,
        amount: 1200,
        distributionMethod: "equal",
        effectiveDate: "2026-01-01",
        decisionNo: "2025/12",
        pageNo: "45",
        decisionDate: "2025-12-15",
        summary: "2026 yılı için aylık aidat 1.200 TL olarak belirlenmiştir.",
    },
];

const mockIncomes: Income[] = [
    { id: 1, type: "dues", description: "Ocak 2026 Aidat Ödemeleri", amount: 145600, date: "2026-01-31" },
    { id: 2, type: "rent", description: "Site Kafeterya Kirası", amount: 15000, date: "2026-01-05" },
];

const mockExpenses: Expense[] = [
    { id: 1, category: "personnel", description: "Ocak 2026 Personel Maaşları", amount: 56000, date: "2026-01-31", isRecurring: true },
    { id: 2, category: "utility", description: "Ortak Alan Elektrik", amount: 8500, date: "2026-01-15", isRecurring: true },
];

// Config
const incomeTypes: Record<string, { label: string; color: string }> = {
    dues: { label: "Aidat", color: "bg-blue-100 text-blue-700" },
    service: { label: "Ücretli Hizmet", color: "bg-green-100 text-green-700" },
    rent: { label: "Kira", color: "bg-purple-100 text-purple-700" },
    sale: { label: "Satış", color: "bg-orange-100 text-orange-700" },
    other: { label: "Diğer", color: "bg-gray-100 text-gray-700" },
};

const expenseCategories: Record<string, { label: string; icon: React.ElementType }> = {
    personnel: { label: "Personel", icon: Users },
    utility: { label: "Fatura", icon: Zap },
    maintenance: { label: "Bakım", icon: Wrench },
    repair: { label: "Onarım", icon: Building },
    admin: { label: "Yönetim", icon: FileText },
    insurance: { label: "Sigorta", icon: Receipt },
    other: { label: "Diğer", icon: CreditCard },
};

const distributionMethods: Record<string, string> = {
    equal: "Eşit Dağılım",
    landShare: "Arsa Payı",
    sqm: "Metrekare",
};

export default function AccountingPage() {
    const [activeTab, setActiveTab] = useState<"dues" | "income" | "expense" | "quick">("dues");
    const [isDuesModalOpen, setIsDuesModalOpen] = useState(false);
    const [isIncomeModalOpen, setIsIncomeModalOpen] = useState(false);
    const [isExpenseModalOpen, setIsExpenseModalOpen] = useState(false);
    const [isQuickActionModalOpen, setIsQuickActionModalOpen] = useState(false);
    const [quickActionType, setQuickActionType] = useState<string>("");

    const [duesDecisions, setDuesDecisions] = useState(mockDuesDecisions);
    const [incomes, setIncomes] = useState(mockIncomes);
    const [expenses, setExpenses] = useState(mockExpenses);

    useEffect(() => {
        apiClient.loadToken();
        apiClient.getExpenses().then((data) => {
            const items = data?.data ?? data;
            if (Array.isArray(items) && items.length > 0) {
                setExpenses(items.map((e: any) => ({
                    id: e.id,
                    category: e.category_name?.toLowerCase().includes("personel") ? "personnel"
                        : e.category_name?.toLowerCase().includes("elektrik") || e.category_name?.toLowerCase().includes("fatura") ? "utility"
                        : e.category_name?.toLowerCase().includes("bakım") ? "maintenance"
                        : e.category_name?.toLowerCase().includes("onarım") ? "repair"
                        : "other",
                    description: e.description,
                    amount: e.amount,
                    date: e.expense_date,
                    isRecurring: false,
                })));
            }
        }).catch(() => {});
    }, []);

    // Form states
    const [newDues, setNewDues] = useState({
        amount: 0,
        distributionMethod: "equal",
        effectiveDate: "",
        decisionNo: "",
        pageNo: "",
        decisionDate: "",
        summary: "",
    });

    const [newIncome, setNewIncome] = useState({
        type: "dues",
        description: "",
        amount: 0,
        date: "",
        paidBy: "",
    });

    const [newExpense, setNewExpense] = useState({
        category: "personnel",
        description: "",
        amount: 0,
        date: "",
        isRecurring: false,
    });

    const totalIncome = incomes.reduce((sum, i) => sum + i.amount, 0);
    const totalExpense = expenses.reduce((sum, e) => sum + e.amount, 0);
    const balance = totalIncome - totalExpense;

    const handleAddDues = (e: React.FormEvent) => {
        e.preventDefault();
        setDuesDecisions([
            ...duesDecisions,
            { id: duesDecisions.length + 1, ...newDues, distributionMethod: newDues.distributionMethod as "equal" | "landShare" | "sqm" },
        ]);
        setNewDues({ amount: 0, distributionMethod: "equal", effectiveDate: "", decisionNo: "", pageNo: "", decisionDate: "", summary: "" });
        setIsDuesModalOpen(false);
    };

    const handleAddIncome = (e: React.FormEvent) => {
        e.preventDefault();
        setIncomes([...incomes, { id: incomes.length + 1, ...newIncome, type: newIncome.type as Income["type"] }]);
        setNewIncome({ type: "dues", description: "", amount: 0, date: "", paidBy: "" });
        setIsIncomeModalOpen(false);
    };

    const handleAddExpense = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            await apiClient.createExpense({
                category: newExpense.category,
                description: newExpense.description,
                amount: newExpense.amount,
                expense_date: newExpense.date,
                is_recurring: newExpense.isRecurring,
            });
        } catch {}
        setExpenses([...expenses, { id: expenses.length + 1, ...newExpense, category: newExpense.category as Expense["category"] }]);
        setNewExpense({ category: "personnel", description: "", amount: 0, date: "", isRecurring: false });
        setIsExpenseModalOpen(false);
    };

    const handleQuickAction = (type: string) => {
        setQuickActionType(type);
        setIsQuickActionModalOpen(true);
    };

    const confirmQuickAction = () => {
        const today = new Date().toISOString().split("T")[0];
        if (quickActionType === "personnel") {
            const totalSalary = mockPersonnel.reduce((sum, p) => sum + p.salary, 0);
            setExpenses([...expenses, {
                id: expenses.length + 1,
                category: "personnel",
                description: `${new Date().toLocaleString("tr-TR", { month: "long", year: "numeric" })} Personel Maaşları`,
                amount: totalSalary,
                date: today,
                isRecurring: true,
            }]);
        } else if (quickActionType === "maintenance") {
            setExpenses([...expenses, {
                id: expenses.length + 1,
                category: "maintenance",
                description: `${new Date().toLocaleString("tr-TR", { month: "long", year: "numeric" })} Aylık Bakım`,
                amount: 12500, // Mock değer
                date: today,
                isRecurring: true,
            }]);
        } else if (quickActionType === "sgk") {
            setExpenses([...expenses, {
                id: expenses.length + 1,
                category: "admin",
                description: `${new Date().toLocaleString("tr-TR", { month: "long", year: "numeric" })} SGK/Vergi`,
                amount: 18000, // Mock değer
                date: today,
                isRecurring: true,
            }]);
        }
        setIsQuickActionModalOpen(false);
    };

    const tabs = [
        { id: "dues", label: "Aidat Belirleme", icon: Receipt },
        { id: "income", label: "Gelirler", icon: TrendingUp },
        { id: "expense", label: "Giderler", icon: TrendingDown },
        { id: "quick", label: "Toplu İşlemler", icon: Zap },
    ];

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Muhasebe</h1>
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                        Aidat belirleme, gelir-gider takibi
                    </p>
                </div>
            </div>

            {/* Summary Cards */}
            <div className="grid gap-4 md:grid-cols-4">
                <div className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
                    <p className="text-sm text-gray-500">Aylık Aidat</p>
                    <p className="mt-1 text-2xl font-bold text-primary">
                        ₺{duesDecisions[duesDecisions.length - 1]?.amount.toLocaleString() || 0}
                    </p>
                </div>
                <div className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
                    <p className="text-sm text-gray-500">Toplam Gelir</p>
                    <p className="mt-1 text-2xl font-bold text-green-600">₺{totalIncome.toLocaleString()}</p>
                </div>
                <div className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
                    <p className="text-sm text-gray-500">Toplam Gider</p>
                    <p className="mt-1 text-2xl font-bold text-red-600">₺{totalExpense.toLocaleString()}</p>
                </div>
                <div className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
                    <p className="text-sm text-gray-500">Net Bakiye</p>
                    <p className={`mt-1 text-2xl font-bold ${balance >= 0 ? "text-green-600" : "text-red-600"}`}>
                        ₺{balance.toLocaleString()}
                    </p>
                </div>
            </div>

            {/* Tabs */}
            <div className="flex gap-2 border-b border-gray-200 dark:border-gray-700">
                {tabs.map((tab) => (
                    <button
                        key={tab.id}
                        onClick={() => setActiveTab(tab.id as typeof activeTab)}
                        className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${activeTab === tab.id
                                ? "border-primary text-primary"
                                : "border-transparent text-gray-500 hover:text-gray-700"
                            }`}
                    >
                        <tab.icon className="h-4 w-4" />
                        {tab.label}
                    </button>
                ))}
            </div>

            {/* Tab Content */}
            <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                {/* Aidat Belirleme */}
                {activeTab === "dues" && (
                    <div className="space-y-6">
                        <div className="flex items-center justify-between">
                            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Aidat Kararları</h2>
                            <button
                                onClick={() => setIsDuesModalOpen(true)}
                                className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90"
                            >
                                <Plus className="h-4 w-4" />
                                Yeni Aidat Kararı
                            </button>
                        </div>

                        <div className="space-y-4">
                            {duesDecisions.map((decision) => (
                                <div key={decision.id} className="rounded-lg border border-gray-200 p-4 dark:border-gray-700">
                                    <div className="flex items-start justify-between">
                                        <div className="flex-1">
                                            <div className="flex items-center gap-3 mb-2">
                                                <span className="text-2xl font-bold text-primary">₺{decision.amount.toLocaleString()}</span>
                                                <span className="rounded-full bg-blue-100 px-3 py-1 text-xs font-medium text-blue-700">
                                                    {distributionMethods[decision.distributionMethod]}
                                                </span>
                                            </div>
                                            <p className="text-gray-600 dark:text-gray-400 mb-2">{decision.summary}</p>
                                            <div className="flex flex-wrap gap-4 text-sm text-gray-500">
                                                <span className="flex items-center gap-1">
                                                    <FileText className="h-4 w-4" />
                                                    Karar No: {decision.decisionNo}
                                                </span>
                                                <span>Sayfa: {decision.pageNo}</span>
                                                <span className="flex items-center gap-1">
                                                    <Calendar className="h-4 w-4" />
                                                    {new Date(decision.decisionDate).toLocaleDateString("tr-TR")}
                                                </span>
                                            </div>
                                        </div>
                                        {decision.documentUrl && (
                                            <button className="text-primary hover:underline text-sm">Belge Görüntüle</button>
                                        )}
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                )}

                {/* Gelirler */}
                {activeTab === "income" && (
                    <div className="space-y-6">
                        <div className="flex items-center justify-between">
                            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Gelir Kayıtları</h2>
                            <button
                                onClick={() => setIsIncomeModalOpen(true)}
                                className="flex items-center gap-2 rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700"
                            >
                                <Plus className="h-4 w-4" />
                                Gelir Ekle
                            </button>
                        </div>

                        <table className="w-full">
                            <thead>
                                <tr className="border-b border-gray-200 dark:border-gray-700">
                                    <th className="py-3 text-left text-sm font-medium text-gray-500">Tarih</th>
                                    <th className="py-3 text-left text-sm font-medium text-gray-500">Tür</th>
                                    <th className="py-3 text-left text-sm font-medium text-gray-500">Açıklama</th>
                                    <th className="py-3 text-right text-sm font-medium text-gray-500">Tutar</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                                {incomes.map((income) => (
                                    <tr key={income.id}>
                                        <td className="py-3 text-gray-600 dark:text-gray-400">
                                            {new Date(income.date).toLocaleDateString("tr-TR")}
                                        </td>
                                        <td className="py-3">
                                            <span className={`rounded-full px-3 py-1 text-xs font-medium ${incomeTypes[income.type].color}`}>
                                                {incomeTypes[income.type].label}
                                            </span>
                                        </td>
                                        <td className="py-3 text-gray-900 dark:text-white">{income.description}</td>
                                        <td className="py-3 text-right font-medium text-green-600">+₺{income.amount.toLocaleString()}</td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}

                {/* Giderler */}
                {activeTab === "expense" && (
                    <div className="space-y-6">
                        <div className="flex items-center justify-between">
                            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Gider Kayıtları</h2>
                            <button
                                onClick={() => setIsExpenseModalOpen(true)}
                                className="flex items-center gap-2 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700"
                            >
                                <Plus className="h-4 w-4" />
                                Gider Ekle
                            </button>
                        </div>

                        <table className="w-full">
                            <thead>
                                <tr className="border-b border-gray-200 dark:border-gray-700">
                                    <th className="py-3 text-left text-sm font-medium text-gray-500">Tarih</th>
                                    <th className="py-3 text-left text-sm font-medium text-gray-500">Kategori</th>
                                    <th className="py-3 text-left text-sm font-medium text-gray-500">Açıklama</th>
                                    <th className="py-3 text-right text-sm font-medium text-gray-500">Tutar</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                                {expenses.map((expense) => {
                                    const CategoryIcon = expenseCategories[expense.category].icon;
                                    return (
                                        <tr key={expense.id}>
                                            <td className="py-3 text-gray-600 dark:text-gray-400">
                                                {new Date(expense.date).toLocaleDateString("tr-TR")}
                                            </td>
                                            <td className="py-3">
                                                <span className="flex items-center gap-2">
                                                    <CategoryIcon className="h-4 w-4 text-gray-400" />
                                                    {expenseCategories[expense.category].label}
                                                </span>
                                            </td>
                                            <td className="py-3 text-gray-900 dark:text-white">{expense.description}</td>
                                            <td className="py-3 text-right font-medium text-red-600">-₺{expense.amount.toLocaleString()}</td>
                                        </tr>
                                    );
                                })}
                            </tbody>
                        </table>
                    </div>
                )}

                {/* Toplu İşlemler */}
                {activeTab === "quick" && (
                    <div className="space-y-6">
                        <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Toplu Gider İşlemleri</h2>
                        <p className="text-gray-500">Aşağıdaki butonlarla periyodik ödemeleri tek tıkla giderlere ekleyebilirsiniz.</p>

                        <div className="grid gap-4 md:grid-cols-3">
                            <button
                                onClick={() => handleQuickAction("personnel")}
                                className="flex flex-col items-center gap-3 rounded-xl border-2 border-dashed border-gray-300 p-6 hover:border-primary hover:bg-primary/5 transition-colors"
                            >
                                <div className="rounded-full bg-blue-100 p-3">
                                    <Users className="h-6 w-6 text-blue-600" />
                                </div>
                                <span className="font-medium text-gray-900 dark:text-white">Personel Maaşları Ödendi</span>
                                <span className="text-sm text-gray-500">
                                    Toplam: ₺{mockPersonnel.reduce((sum, p) => sum + p.salary, 0).toLocaleString()}
                                </span>
                            </button>

                            <button
                                onClick={() => handleQuickAction("maintenance")}
                                className="flex flex-col items-center gap-3 rounded-xl border-2 border-dashed border-gray-300 p-6 hover:border-primary hover:bg-primary/5 transition-colors"
                            >
                                <div className="rounded-full bg-orange-100 p-3">
                                    <Wrench className="h-6 w-6 text-orange-600" />
                                </div>
                                <span className="font-medium text-gray-900 dark:text-white">Aylık Bakım Ödemeleri</span>
                                <span className="text-sm text-gray-500">Asansör, Jeneratör, Temizlik</span>
                            </button>

                            <button
                                onClick={() => handleQuickAction("sgk")}
                                className="flex flex-col items-center gap-3 rounded-xl border-2 border-dashed border-gray-300 p-6 hover:border-primary hover:bg-primary/5 transition-colors"
                            >
                                <div className="rounded-full bg-purple-100 p-3">
                                    <FileText className="h-6 w-6 text-purple-600" />
                                </div>
                                <span className="font-medium text-gray-900 dark:text-white">SGK/Vergi Ödemeleri</span>
                                <span className="text-sm text-gray-500">Aylık zorunlu ödemeler</span>
                            </button>
                        </div>
                    </div>
                )}
            </div>

            {/* Aidat Modal */}
            {isDuesModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-lg rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800 max-h-[90vh] overflow-y-auto">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">Yeni Aidat Kararı</h2>
                            <button onClick={() => setIsDuesModalOpen(false)} className="rounded-lg p-1 hover:bg-gray-100 dark:hover:bg-gray-700">
                                <X className="h-5 w-5 text-gray-500" />
                            </button>
                        </div>
                        <form onSubmit={handleAddDues} className="space-y-4">
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Aidat Tutarı (₺)</label>
                                    <input
                                        type="number"
                                        required
                                        value={newDues.amount || ""}
                                        onChange={(e) => setNewDues({ ...newDues, amount: Number(e.target.value) })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm focus:border-primary focus:outline-none dark:border-gray-600 dark:bg-gray-700"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Dağıtım Yöntemi</label>
                                    <select
                                        value={newDues.distributionMethod}
                                        onChange={(e) => setNewDues({ ...newDues, distributionMethod: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                    >
                                        <option value="equal">Eşit Dağılım</option>
                                        <option value="landShare">Arsa Payı</option>
                                        <option value="sqm">Metrekare</option>
                                    </select>
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Geçerlilik Tarihi</label>
                                <input
                                    type="date"
                                    required
                                    value={newDues.effectiveDate}
                                    onChange={(e) => setNewDues({ ...newDues, effectiveDate: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                />
                            </div>
                            <div className="border-t border-gray-200 pt-4 dark:border-gray-700">
                                <h3 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">Defter Referansı</h3>
                                <div className="grid grid-cols-3 gap-4">
                                    <div>
                                        <label className="block text-xs text-gray-500 mb-1">Karar No</label>
                                        <input
                                            type="text"
                                            value={newDues.decisionNo}
                                            onChange={(e) => setNewDues({ ...newDues, decisionNo: e.target.value })}
                                            className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                            placeholder="2025/12"
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-xs text-gray-500 mb-1">Sayfa No</label>
                                        <input
                                            type="text"
                                            value={newDues.pageNo}
                                            onChange={(e) => setNewDues({ ...newDues, pageNo: e.target.value })}
                                            className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                            placeholder="45"
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-xs text-gray-500 mb-1">Karar Tarihi</label>
                                        <input
                                            type="date"
                                            value={newDues.decisionDate}
                                            onChange={(e) => setNewDues({ ...newDues, decisionDate: e.target.value })}
                                            className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                        />
                                    </div>
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Karar Özeti</label>
                                <textarea
                                    rows={3}
                                    value={newDues.summary}
                                    onChange={(e) => setNewDues({ ...newDues, summary: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                    placeholder="Aidat kararının özeti..."
                                />
                            </div>
                            <div className="border-t border-gray-200 pt-4 dark:border-gray-700">
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Belge Yükle (Opsiyonel)</label>
                                <div className="flex items-center justify-center w-full h-24 border-2 border-dashed border-gray-300 rounded-lg hover:border-primary cursor-pointer">
                                    <div className="flex flex-col items-center gap-1 text-gray-500">
                                        <Upload className="h-6 w-6" />
                                        <span className="text-sm">PDF veya resim yükle</span>
                                    </div>
                                </div>
                            </div>
                            <div className="flex gap-3 pt-4">
                                <button type="button" onClick={() => setIsDuesModalOpen(false)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">
                                    İptal
                                </button>
                                <button type="submit" className="flex-1 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90">
                                    Kaydet
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Income Modal */}
            {isIncomeModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">Gelir Ekle</h2>
                            <button onClick={() => setIsIncomeModalOpen(false)} className="rounded-lg p-1 hover:bg-gray-100 dark:hover:bg-gray-700">
                                <X className="h-5 w-5 text-gray-500" />
                            </button>
                        </div>
                        <form onSubmit={handleAddIncome} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Gelir Türü</label>
                                <select
                                    value={newIncome.type}
                                    onChange={(e) => setNewIncome({ ...newIncome, type: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                >
                                    <option value="dues">Aidat</option>
                                    <option value="service">Ücretli Hizmet</option>
                                    <option value="rent">Kira</option>
                                    <option value="sale">Satış</option>
                                    <option value="other">Diğer</option>
                                </select>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Açıklama</label>
                                <input
                                    type="text"
                                    required
                                    value={newIncome.description}
                                    onChange={(e) => setNewIncome({ ...newIncome, description: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Tutar (₺)</label>
                                    <input
                                        type="number"
                                        required
                                        value={newIncome.amount || ""}
                                        onChange={(e) => setNewIncome({ ...newIncome, amount: Number(e.target.value) })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Tarih</label>
                                    <input
                                        type="date"
                                        required
                                        value={newIncome.date}
                                        onChange={(e) => setNewIncome({ ...newIncome, date: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                    />
                                </div>
                            </div>
                            <div className="flex gap-3 pt-4">
                                <button type="button" onClick={() => setIsIncomeModalOpen(false)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">
                                    İptal
                                </button>
                                <button type="submit" className="flex-1 rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700">
                                    Ekle
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Expense Modal */}
            {isExpenseModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">Gider Ekle</h2>
                            <button onClick={() => setIsExpenseModalOpen(false)} className="rounded-lg p-1 hover:bg-gray-100 dark:hover:bg-gray-700">
                                <X className="h-5 w-5 text-gray-500" />
                            </button>
                        </div>
                        <form onSubmit={handleAddExpense} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Kategori</label>
                                <select
                                    value={newExpense.category}
                                    onChange={(e) => setNewExpense({ ...newExpense, category: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                >
                                    <option value="personnel">Personel</option>
                                    <option value="utility">Fatura</option>
                                    <option value="maintenance">Bakım</option>
                                    <option value="repair">Onarım</option>
                                    <option value="admin">Yönetim</option>
                                    <option value="insurance">Sigorta</option>
                                    <option value="other">Diğer</option>
                                </select>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Açıklama</label>
                                <input
                                    type="text"
                                    required
                                    value={newExpense.description}
                                    onChange={(e) => setNewExpense({ ...newExpense, description: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Tutar (₺)</label>
                                    <input
                                        type="number"
                                        required
                                        value={newExpense.amount || ""}
                                        onChange={(e) => setNewExpense({ ...newExpense, amount: Number(e.target.value) })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Tarih</label>
                                    <input
                                        type="date"
                                        required
                                        value={newExpense.date}
                                        onChange={(e) => setNewExpense({ ...newExpense, date: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                    />
                                </div>
                            </div>
                            <div className="flex items-center gap-2">
                                <input
                                    type="checkbox"
                                    id="isRecurring"
                                    checked={newExpense.isRecurring}
                                    onChange={(e) => setNewExpense({ ...newExpense, isRecurring: e.target.checked })}
                                    className="h-4 w-4 rounded border-gray-300 text-primary"
                                />
                                <label htmlFor="isRecurring" className="text-sm text-gray-700 dark:text-gray-300">
                                    Periyodik gider (her ay tekrarlanan)
                                </label>
                            </div>
                            <div className="flex gap-3 pt-4">
                                <button type="button" onClick={() => setIsExpenseModalOpen(false)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">
                                    İptal
                                </button>
                                <button type="submit" className="flex-1 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700">
                                    Ekle
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Quick Action Confirmation Modal */}
            {isQuickActionModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-sm rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800">
                        <div className="flex flex-col items-center text-center">
                            <div className="rounded-full bg-yellow-100 p-3 mb-4">
                                <Check className="h-6 w-6 text-yellow-600" />
                            </div>
                            <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-2">Onay Gerekli</h2>
                            <p className="text-gray-500 mb-6">
                                {quickActionType === "personnel" && "Tüm personel maaşlarını giderlere eklemek istediğinize emin misiniz?"}
                                {quickActionType === "maintenance" && "Aylık bakım ödemelerini giderlere eklemek istediğinize emin misiniz?"}
                                {quickActionType === "sgk" && "SGK/Vergi ödemelerini giderlere eklemek istediğinize emin misiniz?"}
                            </p>
                            <div className="flex gap-3 w-full">
                                <button
                                    onClick={() => setIsQuickActionModalOpen(false)}
                                    className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300"
                                >
                                    İptal
                                </button>
                                <button
                                    onClick={confirmQuickAction}
                                    className="flex-1 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90"
                                >
                                    Onayla
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
