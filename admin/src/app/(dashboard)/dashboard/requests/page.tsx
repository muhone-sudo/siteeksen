"use client";

import { useState } from "react";
import { Search, MessageSquare, Clock, User, X, Edit, Trash2, CheckCircle, ChevronDown } from "lucide-react";

interface Request {
    id: number;
    ticketNo: string;
    title: string;
    category: string;
    unit: string;
    resident: string;
    status: string;
    priority: string;
    createdAt: string;
    description?: string;
    assignedTo?: string;
    resolvedAt?: string;
    deleted: number;
}

const mockRequests: Request[] = [
    { id: 1, ticketNo: "TLP-2026-0142", title: "Asansör arızası - A Blok", category: "Asansör", unit: "Ortak Alan", resident: "Ahmet Yılmaz", status: "OPEN", priority: "HIGH", createdAt: "2026-01-31T10:30:00", description: "A Blok asansörü 2. katta duruyor, hareket etmiyor.", deleted: 0 },
    { id: 2, ticketNo: "TLP-2026-0141", title: "Merdiven aydınlatma arızası", category: "Elektrik", unit: "A Blok", resident: "Ayşe Kaya", status: "IN_PROGRESS", priority: "NORMAL", createdAt: "2026-01-30T14:15:00", assignedTo: "Elektrikçi - Mehmet Usta", deleted: 0 },
    { id: 3, ticketNo: "TLP-2026-0140", title: "Bahçe sulama sistemi", category: "Bahçe", unit: "Ortak Alan", resident: "Ali Demir", status: "RESOLVED", priority: "LOW", createdAt: "2026-01-28T09:00:00", resolvedAt: "2026-01-29T16:00:00", deleted: 0 },
];

const statusConfig: Record<string, { label: string; color: string }> = {
    OPEN: { label: "Açık", color: "bg-yellow-100 text-yellow-700" },
    IN_PROGRESS: { label: "İşlemde", color: "bg-blue-100 text-blue-700" },
    RESOLVED: { label: "Çözüldü", color: "bg-green-100 text-green-700" },
    CLOSED: { label: "Kapatıldı", color: "bg-gray-100 text-gray-700" },
};

const priorityConfig: Record<string, { label: string; color: string }> = {
    LOW: { label: "Düşük", color: "text-gray-500" },
    NORMAL: { label: "Normal", color: "text-blue-500" },
    HIGH: { label: "Yüksek", color: "text-orange-500" },
    URGENT: { label: "Acil", color: "text-red-500" },
};

const emptyForm = { title: "", category: "Asansör", unit: "", resident: "", priority: "NORMAL", assignedTo: "", description: "" };

export default function RequestsPage() {
    const [statusFilter, setStatusFilter] = useState("all");
    const [searchQuery, setSearchQuery] = useState("");
    const [requests, setRequests] = useState<Request[]>(mockRequests);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingId, setEditingId] = useState<number | null>(null);
    const [detailId, setDetailId] = useState<number | null>(null);
    const [deleteConfirmId, setDeleteConfirmId] = useState<number | null>(null);
    const [statusChangeId, setStatusChangeId] = useState<number | null>(null);
    const [formData, setFormData] = useState(emptyForm);

    const active = requests.filter(r => r.deleted === 0);

    const filteredRequests = active.filter((r) => {
        if (statusFilter !== "all" && r.status !== statusFilter) return false;
        if (searchQuery && !r.title.toLowerCase().includes(searchQuery.toLowerCase()) && !r.ticketNo.toLowerCase().includes(searchQuery.toLowerCase())) return false;
        return true;
    });

    const openEdit = (r: Request) => {
        setEditingId(r.id);
        setFormData({ title: r.title, category: r.category, unit: r.unit, resident: r.resident, priority: r.priority, assignedTo: r.assignedTo ?? "", description: r.description ?? "" });
        setIsModalOpen(true);
    };

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        if (editingId !== null) {
            setRequests(prev => prev.map(r => r.id === editingId ? { ...r, ...formData } : r));
        }
        setIsModalOpen(false); setEditingId(null);
    };

    const handleStatusChange = (id: number, newStatus: string) => {
        setRequests(prev => prev.map(r => r.id === id ? { ...r, status: newStatus, resolvedAt: newStatus === "RESOLVED" ? new Date().toISOString() : r.resolvedAt } : r));
        setStatusChangeId(null);
    };

    const handleDelete = (id: number) => {
        setRequests(prev => prev.map(r => r.id === id ? { ...r, deleted: 1 } : r));
        setDeleteConfirmId(null);
    };

    const detailRequest = requests.find(r => r.id === detailId);

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Talep Yönetimi</h1>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Site sakinlerinin talep ve şikayetleri</p>
                </div>
            </div>

            <div className="grid gap-4 md:grid-cols-4">
                {[
                    { label: "Açık", status: "OPEN", color: "text-yellow-600" },
                    { label: "İşlemde", status: "IN_PROGRESS", color: "text-blue-600" },
                    { label: "Çözüldü", status: "RESOLVED", color: "text-green-600" },
                    { label: "Kapalı", status: "CLOSED", color: "text-gray-600" },
                ].map(s => (
                    <div key={s.label} className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
                        <p className="text-sm text-gray-500">{s.label}</p>
                        <p className={`mt-1 text-2xl font-bold ${s.color}`}>{active.filter(r => r.status === s.status).length}</p>
                    </div>
                ))}
            </div>

            <div className="flex gap-4">
                <div className="relative flex-1">
                    <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                    <input type="text" placeholder="Talep ara..." value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)}
                        className="w-full rounded-lg border border-gray-300 bg-white py-2 pl-10 pr-4 text-sm focus:border-primary focus:outline-none dark:border-gray-600 dark:bg-gray-800" />
                </div>
                <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}
                    className="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-800">
                    <option value="all">Tüm Durumlar</option>
                    <option value="OPEN">Açık</option>
                    <option value="IN_PROGRESS">İşlemde</option>
                    <option value="RESOLVED">Çözüldü</option>
                    <option value="CLOSED">Kapatıldı</option>
                </select>
            </div>

            <div className="space-y-4">
                {filteredRequests.map((request) => (
                    <div key={request.id} className="rounded-xl bg-white p-6 shadow-sm transition-shadow hover:shadow-md dark:bg-gray-800">
                        <div className="flex items-start justify-between">
                            <div className="flex-1">
                                <div className="mb-2 flex items-center gap-3">
                                    <span className="text-sm font-mono text-gray-500">{request.ticketNo}</span>
                                    <span className={`rounded-full px-3 py-1 text-xs font-medium ${statusConfig[request.status]?.color ?? "bg-gray-100 text-gray-700"}`}>
                                        {statusConfig[request.status]?.label ?? request.status}
                                    </span>
                                    <span className={`text-sm font-medium ${priorityConfig[request.priority]?.color ?? "text-gray-500"}`}>
                                        {priorityConfig[request.priority]?.label ?? request.priority}
                                    </span>
                                </div>
                                <h3 className="mb-2 text-lg font-semibold text-gray-900 dark:text-white">{request.title}</h3>
                                <div className="flex flex-wrap items-center gap-4 text-sm text-gray-500">
                                    <span className="flex items-center gap-1"><User className="h-4 w-4" />{request.resident}</span>
                                    <span>{request.category}</span>
                                    <span className="flex items-center gap-1"><Clock className="h-4 w-4" />{new Date(request.createdAt).toLocaleString("tr-TR")}</span>
                                </div>
                            </div>
                            <div className="flex gap-2 ml-4">
                                {/* Status change dropdown */}
                                <div className="relative">
                                    <button onClick={() => setStatusChangeId(statusChangeId === request.id ? null : request.id)}
                                        className="flex items-center gap-1 rounded-lg border border-gray-300 px-3 py-1.5 text-xs font-medium hover:bg-gray-50 dark:border-gray-600 dark:hover:bg-gray-700">
                                        Durum <ChevronDown className="h-3 w-3" />
                                    </button>
                                    {statusChangeId === request.id && (
                                        <div className="absolute right-0 top-8 z-10 w-36 rounded-lg border border-gray-200 bg-white py-1 shadow-lg dark:border-gray-700 dark:bg-gray-800">
                                            {Object.entries(statusConfig).map(([key, cfg]) => (
                                                <button key={key} onClick={() => handleStatusChange(request.id, key)}
                                                    className={`flex w-full items-center px-4 py-2 text-xs hover:bg-gray-100 dark:hover:bg-gray-700 ${request.status === key ? "font-bold text-primary" : "text-gray-700 dark:text-gray-300"}`}>
                                                    {cfg.label}
                                                </button>
                                            ))}
                                        </div>
                                    )}
                                </div>
                                <button onClick={() => setDetailId(request.id)} className="rounded-lg border border-gray-300 px-3 py-1.5 text-xs font-medium hover:bg-gray-50 dark:border-gray-600 dark:hover:bg-gray-700">Detay</button>
                                <button onClick={() => openEdit(request)} className="p-1.5 rounded-lg hover:bg-blue-100 text-blue-500"><Edit className="h-4 w-4" /></button>
                                <button onClick={() => setDeleteConfirmId(request.id)} className="p-1.5 rounded-lg hover:bg-red-100 text-red-500"><Trash2 className="h-4 w-4" /></button>
                            </div>
                        </div>
                    </div>
                ))}
                {filteredRequests.length === 0 && (
                    <div className="rounded-xl bg-white p-12 text-center text-gray-400 shadow-sm dark:bg-gray-800">Talep bulunamadı</div>
                )}
            </div>

            {/* Edit Modal */}
            {isModalOpen && editingId !== null && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">Talebi Düzenle</h2>
                            <button onClick={() => setIsModalOpen(false)}><X className="h-5 w-5 text-gray-500" /></button>
                        </div>
                        <form onSubmit={handleSubmit} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Başlık</label>
                                <input required value={formData.title} onChange={e => setFormData({ ...formData, title: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Kategori</label>
                                    <select value={formData.category} onChange={e => setFormData({ ...formData, category: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700">
                                        {["Asansör", "Elektrik", "Su", "Isıtma", "Bahçe", "Güvenlik", "Temizlik", "Diğer"].map(c => <option key={c}>{c}</option>)}
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Öncelik</label>
                                    <select value={formData.priority} onChange={e => setFormData({ ...formData, priority: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700">
                                        <option value="LOW">Düşük</option>
                                        <option value="NORMAL">Normal</option>
                                        <option value="HIGH">Yüksek</option>
                                        <option value="URGENT">Acil</option>
                                    </select>
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Atanan Kişi</label>
                                <input value={formData.assignedTo} onChange={e => setFormData({ ...formData, assignedTo: e.target.value })} placeholder="İsim veya ekip"
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Açıklama</label>
                                <textarea rows={3} value={formData.description} onChange={e => setFormData({ ...formData, description: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                            </div>
                            <div className="flex gap-3 pt-2">
                                <button type="button" onClick={() => setIsModalOpen(false)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">İptal</button>
                                <button type="submit" className="flex-1 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90">Güncelle</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Detail Modal */}
            {detailRequest && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">{detailRequest.ticketNo}</h2>
                            <button onClick={() => setDetailId(null)}><X className="h-5 w-5 text-gray-500" /></button>
                        </div>
                        <div className="space-y-3 text-sm">
                            <div><label className="text-xs text-gray-500">Başlık</label><p className="font-medium">{detailRequest.title}</p></div>
                            {detailRequest.description && <div><label className="text-xs text-gray-500">Açıklama</label><p className="text-gray-700 dark:text-gray-300">{detailRequest.description}</p></div>}
                            <div className="grid grid-cols-2 gap-3">
                                <div><label className="text-xs text-gray-500">Sakin</label><p>{detailRequest.resident}</p></div>
                                <div><label className="text-xs text-gray-500">Daire</label><p>{detailRequest.unit}</p></div>
                                <div><label className="text-xs text-gray-500">Kategori</label><p>{detailRequest.category}</p></div>
                                <div><label className="text-xs text-gray-500">Durum</label>
                                    <span className={`inline-block rounded-full px-2 py-0.5 text-xs font-medium ${statusConfig[detailRequest.status]?.color}`}>
                                        {statusConfig[detailRequest.status]?.label}
                                    </span>
                                </div>
                                {detailRequest.assignedTo && <div className="col-span-2"><label className="text-xs text-gray-500">Atanan</label><p>{detailRequest.assignedTo}</p></div>}
                            </div>
                            <div><label className="text-xs text-gray-500">Oluşturulma</label><p>{new Date(detailRequest.createdAt).toLocaleString("tr-TR")}</p></div>
                            {detailRequest.resolvedAt && <div><label className="text-xs text-gray-500">Çözüm Tarihi</label><p>{new Date(detailRequest.resolvedAt).toLocaleString("tr-TR")}</p></div>}
                        </div>
                        <button onClick={() => setDetailId(null)} className="w-full mt-4 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">Kapat</button>
                    </div>
                </div>
            )}

            {/* Delete Confirm */}
            {deleteConfirmId !== null && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-sm rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800 text-center">
                        <div className="flex justify-center mb-4"><div className="rounded-full bg-red-100 p-3"><Trash2 className="h-6 w-6 text-red-600" /></div></div>
                        <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-2">Talebi Sil</h2>
                        <p className="text-gray-500 text-sm mb-6">Bu talep silinecek. Emin misiniz?</p>
                        <div className="flex gap-3">
                            <button onClick={() => setDeleteConfirmId(null)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">İptal</button>
                            <button onClick={() => handleDelete(deleteConfirmId)} className="flex-1 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700">Sil</button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
