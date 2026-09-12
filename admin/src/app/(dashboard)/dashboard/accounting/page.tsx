"use client";

import { useState, useEffect, useCallback } from "react";
import apiClient from "@/lib/api-client";
import { EmptyState, ErrorState, LoadingState, NotImplementedNotice, toUserMessage } from "@/components/ui/data-state";
import {
    Plus, X, FileText, TrendingUp, TrendingDown,
    Users, Zap, Wrench, Building, Receipt, CreditCard, Calendar, Edit, Trash2,
} from "lucide-react";

interface DuesDecision { id: number; amount: number; distributionMethod: string; effectiveDate: string; decisionNo: string; pageNo: string; decisionDate: string; summary: string; }
interface Income { id: number; type: string; description: string; amount: number; date: string; paidBy?: string; }
interface Expense { id: number; category: string; description: string; amount: number; date: string; isRecurring: boolean; }

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
const distributionMethods: Record<string, string> = { equal: "Eşit Dağılım", landShare: "Arsa Payı", sqm: "Metrekare" };

export default function AccountingPage() {
    const [activeTab, setActiveTab] = useState<"dues" | "income" | "expense" | "quick">("dues");
    const [isDuesModalOpen, setIsDuesModalOpen] = useState(false);
    const [isIncomeModalOpen, setIsIncomeModalOpen] = useState(false);
    const [isExpenseModalOpen, setIsExpenseModalOpen] = useState(false);

    // Aidat kararları ve gelirler için veritabanı tablosu / API uç noktası yok:
    // listeler boş başlar, uydurma başlangıç verisi kullanılmaz.
    const [duesDecisions] = useState<DuesDecision[]>([]);
    const [incomes] = useState<Income[]>([]);
    const [expenses, setExpenses] = useState<Expense[]>([]);

    const [loading, setLoading] = useState(true);
    const [loadError, setLoadError] = useState<string | null>(null);
    const [formError, setFormError] = useState<string | null>(null);
    const [submitting, setSubmitting] = useState(false);
    const [deleteError, setDeleteError] = useState<string | null>(null);

    const [editingIncome, setEditingIncome] = useState<Income | null>(null);
    const [editingExpense, setEditingExpense] = useState<Expense | null>(null);
    const [deleteConfirm, setDeleteConfirm] = useState<{ type: "income" | "expense" | "dues"; id: number } | null>(null);

    const loadExpenses = useCallback(async () => {
        setLoading(true);
        setLoadError(null);
        try {
            const data = await apiClient.getExpenses();
            const items = data?.data ?? data;
            setExpenses(
                (Array.isArray(items) ? items : []).map((e: any) => ({
                    id: e.id,
                    category: e.category_name?.toLowerCase().includes("personel") ? "personnel" : e.category_name?.toLowerCase().includes("elektrik") ? "utility" : e.category_name?.toLowerCase().includes("bakım") ? "maintenance" : "other",
                    description: e.description, amount: Number(e.amount ?? 0), date: e.expense_date, isRecurring: false,
                }))
            );
        } catch (err) {
            setExpenses([]);
            setLoadError(toUserMessage(err));
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        apiClient.loadToken();
        loadExpenses();
    }, [loadExpenses]);

    const [newDues, setNewDues] = useState({ amount: 0, distributionMethod: "equal", effectiveDate: "", decisionNo: "", pageNo: "", decisionDate: "", summary: "" });
    const [newIncome, setNewIncome] = useState({ type: "dues", description: "", amount: 0, date: "", paidBy: "" });
    const [newExpense, setNewExpense] = useState({ category: "personnel", description: "", amount: 0, date: "", isRecurring: false });

    const activeIncomes = incomes;
    const activeExpenses = expenses;
    const activeDues = duesDecisions;
    const totalExpense = activeExpenses.reduce((sum, e) => sum + e.amount, 0);

    // Mali özet: gelir tarafı için hiçbir veri kaynağı olmadığından tutar uydurulmaz.
    // Gider toplamı da yalnızca sunucudan veri geldiğinde gösterilir.
    const expenseReady = !loading && !loadError;
    const summaryCards = [
        { label: "Aylık Aidat", value: "—", color: "text-primary" },
        { label: "Toplam Gelir", value: "—", color: "text-green-600" },
        { label: "Toplam Gider", value: expenseReady ? `₺${totalExpense.toLocaleString("tr-TR")}` : "—", color: "text-red-600" },
        { label: "Net Bakiye", value: "—", color: "text-gray-900 dark:text-white" },
    ];

    const handleAddDues = (e: React.FormEvent) => {
        e.preventDefault();
        // dues_decisions tablosu ve uç noktası yok; kaydı yalnızca ekranda tutmak sahte başarıdır.
        setFormError("Aidat kararları için veritabanı tablosu ve sunucu uç noktası henüz yok. Karar kaydedilmedi.");
    };

    const handleAddIncome = (e: React.FormEvent) => {
        e.preventDefault();
        // incomes tablosu ve uç noktası yok.
        setFormError("Gelir kayıtları için veritabanı tablosu ve sunucu uç noktası henüz yok. Kayıt saklanmadı.");
    };

    const handleAddExpense = async (e: React.FormEvent) => {
        e.preventDefault();
        setFormError(null);
        // Gider güncelleme uç noktası yok (api-client.ts'te updateExpense bulunmuyor).
        if (editingExpense) {
            setFormError("Gider güncelleme henüz sunucu tarafında desteklenmiyor. Değişiklik kaydedilmedi.");
            return;
        }
        setSubmitting(true);
        try {
            await apiClient.createExpense({
                category: newExpense.category,
                description: newExpense.description,
                amount: newExpense.amount,
                expense_date: newExpense.date,
                is_recurring: newExpense.isRecurring,
            });
            setNewExpense({ category: "personnel", description: "", amount: 0, date: "", isRecurring: false });
            setIsExpenseModalOpen(false);
            setEditingExpense(null);
            await loadExpenses();
        } catch (err) {
            setFormError(toUserMessage(err, "Gider kaydedilemedi."));
        } finally {
            setSubmitting(false);
        }
    };

    const openEditIncome = (inc: Income) => { setEditingIncome(inc); setNewIncome({ type: inc.type, description: inc.description, amount: inc.amount, date: inc.date, paidBy: inc.paidBy ?? "" }); setFormError(null); setIsIncomeModalOpen(true); };
    const openEditExpense = (exp: Expense) => { setEditingExpense(exp); setNewExpense({ category: exp.category, description: exp.description, amount: exp.amount, date: exp.date, isRecurring: exp.isRecurring }); setFormError(null); setIsExpenseModalOpen(true); };

    // Silme uç noktası hiçbir kalem için yok; kaydı yalnızca ekrandan kaldırmak
    // yenilemede geri geldiği için sahte başarıdır.
    const handleDeleteConfirm = () => {
        if (!deleteConfirm) return;
        setDeleteError(
            deleteConfirm.type === "expense"
                ? "Gider silme henüz sunucu tarafında desteklenmiyor. Kayıt silinmedi."
                : "Bu bölüm için silme işlemi sunucu tarafında henüz yok. Kayıt silinmedi."
        );
    };

    const closeDeleteConfirm = () => { setDeleteConfirm(null); setDeleteError(null); };

    const tabs = [
        { id: "dues", label: "Aidat Belirleme", icon: Receipt },
        { id: "income", label: "Gelirler", icon: TrendingUp },
        { id: "expense", label: "Giderler", icon: TrendingDown },
        { id: "quick", label: "Toplu İşlemler", icon: Zap },
    ];

    return (
        <div className="space-y-6">
            <NotImplementedNotice detail="Muhasebe servisi henüz kalıcı kayıt yapmıyor. Mali özet tutarları yalnızca sunucudan gelen veriyle gösterilir; veri yoksa tahmini/örnek rakam gösterilmez." />

            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Muhasebe</h1>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Aidat belirleme, gelir-gider takibi</p>
                </div>
            </div>

            <div className="grid gap-4 md:grid-cols-4">
                {summaryCards.map(c => (
                    <div key={c.label} className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
                        <p className="text-sm text-gray-500">{c.label}</p>
                        <p className={`mt-1 text-2xl font-bold ${c.color}`}>{c.value}</p>
                    </div>
                ))}
            </div>

            <div className="flex gap-2 border-b border-gray-200 dark:border-gray-700">
                {tabs.map((tab) => (
                    <button key={tab.id} onClick={() => setActiveTab(tab.id as typeof activeTab)}
                        className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${activeTab === tab.id ? "border-primary text-primary" : "border-transparent text-gray-500 hover:text-gray-700"}`}>
                        <tab.icon className="h-4 w-4" />{tab.label}
                    </button>
                ))}
            </div>

            <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                {activeTab === "dues" && (
                    <div className="space-y-6">
                        <NotImplementedNotice detail="Bu bölüm için veritabanı tabloları henüz oluşturulmadı; girilen kayıtlar saklanmaz." />
                        <div className="flex items-center justify-between">
                            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Aidat Kararları</h2>
                            <button onClick={() => { setFormError(null); setIsDuesModalOpen(true); }} className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90">
                                <Plus className="h-4 w-4" /> Yeni Aidat Kararı
                            </button>
                        </div>
                        <div className="space-y-4">
                            {activeDues.length === 0 && (
                                <EmptyState title="Aidat kararı yok" description="Aidat kararları için sunucu tarafı veri kaynağı henüz mevcut değil." />
                            )}
                            {activeDues.map((decision) => (
                                <div key={decision.id} className="rounded-lg border border-gray-200 p-4 dark:border-gray-700">
                                    <div className="flex items-start justify-between">
                                        <div className="flex-1">
                                            <div className="flex items-center gap-3 mb-2">
                                                <span className="text-2xl font-bold text-primary">₺{decision.amount.toLocaleString()}</span>
                                                <span className="rounded-full bg-blue-100 px-3 py-1 text-xs font-medium text-blue-700">{distributionMethods[decision.distributionMethod]}</span>
                                            </div>
                                            <p className="text-gray-600 dark:text-gray-400 mb-2">{decision.summary}</p>
                                            <div className="flex flex-wrap gap-4 text-sm text-gray-500">
                                                <span className="flex items-center gap-1"><FileText className="h-4 w-4" />Karar No: {decision.decisionNo}</span>
                                                <span>Sayfa: {decision.pageNo}</span>
                                                <span className="flex items-center gap-1"><Calendar className="h-4 w-4" />{new Date(decision.decisionDate).toLocaleDateString("tr-TR")}</span>
                                            </div>
                                        </div>
                                        <button onClick={() => setDeleteConfirm({ type: "dues", id: decision.id })} className="p-1.5 rounded-lg hover:bg-red-100 text-red-500 ml-4">
                                            <Trash2 className="h-4 w-4" />
                                        </button>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                )}

                {activeTab === "income" && (
                    <div className="space-y-6">
                        <NotImplementedNotice detail="Bu bölüm için veritabanı tabloları henüz oluşturulmadı; girilen kayıtlar saklanmaz." />
                        <div className="flex items-center justify-between">
                            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Gelir Kayıtları</h2>
                            <button onClick={() => { setEditingIncome(null); setNewIncome({ type: "dues", description: "", amount: 0, date: "", paidBy: "" }); setFormError(null); setIsIncomeModalOpen(true); }} className="flex items-center gap-2 rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700">
                                <Plus className="h-4 w-4" /> Gelir Ekle
                            </button>
                        </div>
                        <table className="w-full">
                            <thead>
                                <tr className="border-b border-gray-200 dark:border-gray-700">
                                    <th className="py-3 text-left text-sm font-medium text-gray-500">Tarih</th>
                                    <th className="py-3 text-left text-sm font-medium text-gray-500">Tür</th>
                                    <th className="py-3 text-left text-sm font-medium text-gray-500">Açıklama</th>
                                    <th className="py-3 text-right text-sm font-medium text-gray-500">Tutar</th>
                                    <th className="py-3 text-right text-sm font-medium text-gray-500">İşlem</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                                {activeIncomes.map((income) => (
                                    <tr key={income.id}>
                                        <td className="py-3 text-gray-600 dark:text-gray-400">{new Date(income.date).toLocaleDateString("tr-TR")}</td>
                                        <td className="py-3"><span className={`rounded-full px-3 py-1 text-xs font-medium ${incomeTypes[income.type]?.color ?? "bg-gray-100 text-gray-700"}`}>{incomeTypes[income.type]?.label ?? income.type}</span></td>
                                        <td className="py-3 text-gray-900 dark:text-white">{income.description}</td>
                                        <td className="py-3 text-right font-medium text-green-600">+₺{income.amount.toLocaleString()}</td>
                                        <td className="py-3 text-right">
                                            <div className="flex justify-end gap-1">
                                                <button onClick={() => openEditIncome(income)} className="p-1.5 rounded hover:bg-blue-100 text-blue-500"><Edit className="h-4 w-4" /></button>
                                                <button onClick={() => setDeleteConfirm({ type: "income", id: income.id })} className="p-1.5 rounded hover:bg-red-100 text-red-500"><Trash2 className="h-4 w-4" /></button>
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                        {activeIncomes.length === 0 && (
                            <EmptyState title="Gelir kaydı yok" description="Gelir kayıtları için sunucu tarafı veri kaynağı henüz mevcut değil." />
                        )}
                    </div>
                )}

                {activeTab === "expense" && (
                    <div className="space-y-6">
                        <div className="flex items-center justify-between">
                            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Gider Kayıtları</h2>
                            <button onClick={() => { setEditingExpense(null); setNewExpense({ category: "personnel", description: "", amount: 0, date: "", isRecurring: false }); setFormError(null); setIsExpenseModalOpen(true); }} className="flex items-center gap-2 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700">
                                <Plus className="h-4 w-4" /> Gider Ekle
                            </button>
                        </div>
                        {loading ? (
                            <LoadingState />
                        ) : loadError ? (
                            <ErrorState message={loadError} onRetry={loadExpenses} />
                        ) : activeExpenses.length === 0 ? (
                            <EmptyState title="Gider kaydı yok" description="Seçili dönemde sunucudan gider kaydı gelmedi." />
                        ) : (
                        <table className="w-full">
                            <thead>
                                <tr className="border-b border-gray-200 dark:border-gray-700">
                                    <th className="py-3 text-left text-sm font-medium text-gray-500">Tarih</th>
                                    <th className="py-3 text-left text-sm font-medium text-gray-500">Kategori</th>
                                    <th className="py-3 text-left text-sm font-medium text-gray-500">Açıklama</th>
                                    <th className="py-3 text-right text-sm font-medium text-gray-500">Tutar</th>
                                    <th className="py-3 text-right text-sm font-medium text-gray-500">İşlem</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                                {activeExpenses.map((expense) => {
                                    const catInfo = expenseCategories[expense.category];
                                    const CategoryIcon = catInfo?.icon ?? FileText;
                                    return (
                                        <tr key={expense.id}>
                                            <td className="py-3 text-gray-600 dark:text-gray-400">{new Date(expense.date).toLocaleDateString("tr-TR")}</td>
                                            <td className="py-3"><span className="flex items-center gap-2"><CategoryIcon className="h-4 w-4 text-gray-400" />{catInfo?.label ?? expense.category}</span></td>
                                            <td className="py-3 text-gray-900 dark:text-white">{expense.description}</td>
                                            <td className="py-3 text-right font-medium text-red-600">-₺{expense.amount.toLocaleString()}</td>
                                            <td className="py-3 text-right">
                                                <div className="flex justify-end gap-1">
                                                    <button onClick={() => openEditExpense(expense)} className="p-1.5 rounded hover:bg-blue-100 text-blue-500"><Edit className="h-4 w-4" /></button>
                                                    <button onClick={() => setDeleteConfirm({ type: "expense", id: expense.id })} className="p-1.5 rounded hover:bg-red-100 text-red-500"><Trash2 className="h-4 w-4" /></button>
                                                </div>
                                            </td>
                                        </tr>
                                    );
                                })}
                            </tbody>
                        </table>
                        )}
                    </div>
                )}

                {activeTab === "quick" && (
                    <div className="space-y-6">
                        <NotImplementedNotice detail="Toplu gider işlemleri sunucu tarafında hazır değil. Tutarlar personel/bakım servislerinden okunamadığı için bu düğmeler devre dışı bırakıldı." />
                        <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Toplu Gider İşlemleri</h2>
                        <p className="text-gray-500">Periyodik ödemeleri tek tıkla giderlere ekleyin.</p>
                        <div className="grid gap-4 md:grid-cols-3">
                            {[
                                { type: "personnel", icon: Users, color: "bg-blue-100 text-blue-600", label: "Personel Maaşları Ödendi", sub: "Personel maaş toplamı sunucudan alınamıyor" },
                                { type: "maintenance", icon: Wrench, color: "bg-orange-100 text-orange-600", label: "Aylık Bakım Ödemeleri", sub: "Asansör, Jeneratör, Temizlik" },
                                { type: "sgk", icon: FileText, color: "bg-purple-100 text-purple-600", label: "SGK/Vergi Ödemeleri", sub: "Aylık zorunlu ödemeler" },
                            ].map(item => (
                                <button key={item.type} type="button" disabled
                                    className="flex flex-col items-center gap-3 rounded-xl border-2 border-dashed border-gray-300 p-6 transition-colors disabled:opacity-50 disabled:cursor-not-allowed">
                                    <div className={`rounded-full p-3 ${item.color}`}><item.icon className="h-6 w-6" /></div>
                                    <span className="font-medium text-gray-900 dark:text-white">{item.label}</span>
                                    <span className="text-sm text-gray-500">{item.sub}</span>
                                </button>
                            ))}
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
                            <button onClick={() => { setIsDuesModalOpen(false); setFormError(null); }}><X className="h-5 w-5 text-gray-500" /></button>
                        </div>
                        {formError && (
                            <div role="alert" className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                                {formError}
                            </div>
                        )}
                        <form onSubmit={handleAddDues} className="space-y-4">
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Aidat Tutarı (₺)</label>
                                    <input type="number" required value={newDues.amount || ""} onChange={(e) => setNewDues({ ...newDues, amount: Number(e.target.value) })} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Dağıtım Yöntemi</label>
                                    <select value={newDues.distributionMethod} onChange={(e) => setNewDues({ ...newDues, distributionMethod: e.target.value })} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700">
                                        <option value="equal">Eşit Dağılım</option><option value="landShare">Arsa Payı</option><option value="sqm">Metrekare</option>
                                    </select>
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Geçerlilik Tarihi</label>
                                <input type="date" required value={newDues.effectiveDate} onChange={(e) => setNewDues({ ...newDues, effectiveDate: e.target.value })} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                            </div>
                            <div className="border-t border-gray-200 pt-4 dark:border-gray-700">
                                <h3 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">Defter Referansı</h3>
                                <div className="grid grid-cols-3 gap-4">
                                    <div><label className="block text-xs text-gray-500 mb-1">Karar No</label><input type="text" value={newDues.decisionNo} onChange={(e) => setNewDues({ ...newDues, decisionNo: e.target.value })} placeholder="2025/12" className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" /></div>
                                    <div><label className="block text-xs text-gray-500 mb-1">Sayfa No</label><input type="text" value={newDues.pageNo} onChange={(e) => setNewDues({ ...newDues, pageNo: e.target.value })} placeholder="45" className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" /></div>
                                    <div><label className="block text-xs text-gray-500 mb-1">Karar Tarihi</label><input type="date" value={newDues.decisionDate} onChange={(e) => setNewDues({ ...newDues, decisionDate: e.target.value })} className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" /></div>
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Karar Özeti</label>
                                <textarea rows={3} value={newDues.summary} onChange={(e) => setNewDues({ ...newDues, summary: e.target.value })} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" placeholder="Aidat kararının özeti..." />
                            </div>
                            <div className="flex gap-3 pt-4">
                                <button type="button" onClick={() => { setIsDuesModalOpen(false); setFormError(null); }} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">İptal</button>
                                <button type="submit" className="flex-1 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90">Kaydet</button>
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
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">{editingIncome ? "Geliri Düzenle" : "Gelir Ekle"}</h2>
                            <button onClick={() => { setIsIncomeModalOpen(false); setEditingIncome(null); setFormError(null); }}><X className="h-5 w-5 text-gray-500" /></button>
                        </div>
                        {formError && (
                            <div role="alert" className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                                {formError}
                            </div>
                        )}
                        <form onSubmit={handleAddIncome} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Gelir Türü</label>
                                <select value={newIncome.type} onChange={(e) => setNewIncome({ ...newIncome, type: e.target.value })} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700">
                                    <option value="dues">Aidat</option><option value="service">Ücretli Hizmet</option><option value="rent">Kira</option><option value="sale">Satış</option><option value="other">Diğer</option>
                                </select>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Açıklama</label>
                                <input type="text" required value={newIncome.description} onChange={(e) => setNewIncome({ ...newIncome, description: e.target.value })} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div><label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Tutar (₺)</label><input type="number" required value={newIncome.amount || ""} onChange={(e) => setNewIncome({ ...newIncome, amount: Number(e.target.value) })} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" /></div>
                                <div><label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Tarih</label><input type="date" required value={newIncome.date} onChange={(e) => setNewIncome({ ...newIncome, date: e.target.value })} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" /></div>
                            </div>
                            <div className="flex gap-3 pt-4">
                                <button type="button" onClick={() => { setIsIncomeModalOpen(false); setEditingIncome(null); setFormError(null); }} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">İptal</button>
                                <button type="submit" className="flex-1 rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700">{editingIncome ? "Güncelle" : "Ekle"}</button>
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
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">{editingExpense ? "Gideri Düzenle" : "Gider Ekle"}</h2>
                            <button onClick={() => { setIsExpenseModalOpen(false); setEditingExpense(null); }}><X className="h-5 w-5 text-gray-500" /></button>
                        </div>
                        <form onSubmit={handleAddExpense} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Kategori</label>
                                <select value={newExpense.category} onChange={(e) => setNewExpense({ ...newExpense, category: e.target.value })} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700">
                                    <option value="personnel">Personel</option><option value="utility">Fatura</option><option value="maintenance">Bakım</option><option value="repair">Onarım</option><option value="admin">Yönetim</option><option value="insurance">Sigorta</option><option value="other">Diğer</option>
                                </select>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Açıklama</label>
                                <input type="text" required value={newExpense.description} onChange={(e) => setNewExpense({ ...newExpense, description: e.target.value })} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div><label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Tutar (₺)</label><input type="number" required value={newExpense.amount || ""} onChange={(e) => setNewExpense({ ...newExpense, amount: Number(e.target.value) })} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" /></div>
                                <div><label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Tarih</label><input type="date" required value={newExpense.date} onChange={(e) => setNewExpense({ ...newExpense, date: e.target.value })} className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" /></div>
                            </div>
                            <div className="flex items-center gap-2">
                                <input type="checkbox" id="isRecurring" checked={newExpense.isRecurring} onChange={(e) => setNewExpense({ ...newExpense, isRecurring: e.target.checked })} className="h-4 w-4 rounded border-gray-300 text-primary" />
                                <label htmlFor="isRecurring" className="text-sm text-gray-700 dark:text-gray-300">Periyodik gider (her ay tekrarlanan)</label>
                            </div>
                            <div className="flex gap-3 pt-4">
                                <button type="button" onClick={() => { setIsExpenseModalOpen(false); setEditingExpense(null); }} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">İptal</button>
                                <button type="submit" className="flex-1 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700">{editingExpense ? "Güncelle" : "Ekle"}</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Not: "Hızlı işlem" onay modalı kaldırıldı (2026-09-09).
                "Tüm personel maaşlarını giderlere ekle" / "Aylık bakım ödemelerini ekle" gibi toplu
                işlemler yalnızca React state'ini değiştiriyordu; sunucuda karşılığı yoktu ve kullanıcıya
                yapılmamış bir işlem yapılmış gibi gösteriliyordu. Toplu gider oluşturma, gider servisi
                veritabanına bağlandığında (tasks/roadmap.md FAZ 5.5) gerçek uç noktayla yeniden eklenecek. */}

            {/* Delete Confirm */}
            {deleteConfirm && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-sm rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800 text-center">
                        <div className="flex justify-center mb-4"><div className="rounded-full bg-red-100 p-3"><Trash2 className="h-6 w-6 text-red-600" /></div></div>
                        <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-2">Kaydı Sil</h2>
                        <p className="text-gray-500 text-sm mb-6">Bu kayıt silinecek. Emin misiniz?</p>
                        <div className="flex gap-3">
                            <button onClick={() => setDeleteConfirm(null)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">İptal</button>
                            <button onClick={handleDeleteConfirm} className="flex-1 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700">Sil</button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
