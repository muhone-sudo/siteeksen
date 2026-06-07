"use client";

import { useState, useRef } from "react";
import { Plus, Send, Pin, Clock, Users, X, FileText, Edit, Trash2, Download, Upload } from "lucide-react";

const SAMPLE_CSV = `baslik,icerik,kategori,oncelik,sabitlensin
Asansör Bakımı,Asansör periyodik bakımı yapılacak,MAINTENANCE,HIGH,false
Aidat Hatırlatması,Son ödeme tarihi yaklaşıyor,PAYMENT,NORMAL,false`;

interface Announcement {
    id: number;
    title: string;
    content: string;
    category: string;
    priority: string;
    createdAt: string;
    isPinned: boolean;
    readCount: number;
    totalResidents: number;
    deleted: number;
}

const mockAnnouncements: Announcement[] = [
    { id: 1, title: "Asansör Bakımı", content: "5 Şubat 2026 Perşembe günü saat 10:00-14:00 arasında asansör periyodik bakımı yapılacaktır.", category: "MAINTENANCE", priority: "HIGH", createdAt: "2026-01-30", isPinned: true, readCount: 87, totalResidents: 124, deleted: 0 },
    { id: 2, title: "Ocak Ayı Aidat Hatırlatması", content: "Ocak ayı aidatlarının son ödeme tarihi 10 Ocak 2026'dır. Geç ödemelerde gecikme faizi uygulanacaktır.", category: "PAYMENT", priority: "NORMAL", createdAt: "2026-01-05", isPinned: false, readCount: 112, totalResidents: 124, deleted: 0 },
    { id: 3, title: "Bahçe Düzenleme Çalışması", content: "Mart ayı içerisinde site bahçesinde peyzaj düzenleme çalışması yapılacaktır.", category: "INFO", priority: "LOW", createdAt: "2026-01-28", isPinned: false, readCount: 45, totalResidents: 124, deleted: 0 },
];

const categoryConfig: Record<string, { label: string; color: string }> = {
    MAINTENANCE: { label: "Bakım", color: "bg-orange-100 text-orange-700" },
    PAYMENT: { label: "Ödeme", color: "bg-blue-100 text-blue-700" },
    INFO: { label: "Duyuru", color: "bg-gray-100 text-gray-700" },
    EMERGENCY: { label: "Acil", color: "bg-red-100 text-red-700" },
};

const emptyForm = { title: "", content: "", category: "INFO", priority: "NORMAL", isPinned: false };

export default function AnnouncementsPage() {
    const [showForm, setShowForm] = useState(false);
    const [announcements, setAnnouncements] = useState<Announcement[]>(mockAnnouncements);
    const [editingId, setEditingId] = useState<number | null>(null);
    const [deleteConfirmId, setDeleteConfirmId] = useState<number | null>(null);
    const [formData, setFormData] = useState(emptyForm);
    const csvRef = useRef<HTMLInputElement>(null);

    const downloadSampleCSV = () => {
        const blob = new Blob([SAMPLE_CSV], { type: "text/csv;charset=utf-8;" });
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a"); a.href = url; a.download = "duyuru_ornek.csv"; a.click();
        URL.revokeObjectURL(url);
    };

    const handleCSVUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;
        const reader = new FileReader();
        reader.onload = (ev) => {
            const text = ev.target?.result as string;
            const rows = text.split("\n").slice(1).filter(r => r.trim());
            const imported: Announcement[] = rows.map((row, i) => {
                const [baslik, icerik, kategori, oncelik, sabit] = row.split(",").map(s => s.trim());
                return { id: Date.now() + i, title: baslik ?? "", content: icerik ?? "", category: kategori || "INFO", priority: oncelik || "NORMAL", isPinned: sabit === "true", createdAt: new Date().toISOString().split("T")[0], readCount: 0, totalResidents: 124, deleted: 0 };
            });
            setAnnouncements(prev => [...imported, ...prev]);
        };
        reader.readAsText(file);
        e.target.value = "";
    };

    const active = announcements.filter(a => a.deleted === 0);

    const openAdd = () => { setEditingId(null); setFormData(emptyForm); setShowForm(true); };
    const openEdit = (a: Announcement) => {
        setEditingId(a.id);
        setFormData({ title: a.title, content: a.content, category: a.category, priority: a.priority, isPinned: a.isPinned });
        setShowForm(true);
    };

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        if (editingId !== null) {
            setAnnouncements(prev => prev.map(a => a.id === editingId ? { ...a, ...formData } : a));
        } else {
            setAnnouncements(prev => [{ id: Date.now(), ...formData, createdAt: new Date().toISOString().split("T")[0], readCount: 0, totalResidents: 124, deleted: 0 }, ...prev]);
        }
        setFormData(emptyForm); setShowForm(false); setEditingId(null);
    };

    const handleDelete = (id: number) => {
        setAnnouncements(prev => prev.map(a => a.id === id ? { ...a, deleted: 1 } : a));
        setDeleteConfirmId(null);
    };

    const togglePin = (id: number) => setAnnouncements(prev => prev.map(a => a.id === id ? { ...a, isPinned: !a.isPinned } : a));

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Duyurular</h1>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Site sakinlerine duyuru yayınlayın</p>
                </div>
                <div className="flex gap-3">
                    <button onClick={downloadSampleCSV} className="flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm font-medium hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:hover:bg-gray-700">
                        <Download className="h-4 w-4" /> Örnek CSV
                    </button>
                    <button onClick={() => csvRef.current?.click()} className="flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm font-medium hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:hover:bg-gray-700">
                        <Upload className="h-4 w-4" /> CSV Yükle
                    </button>
                    <input ref={csvRef} type="file" accept=".csv" className="hidden" onChange={handleCSVUpload} />
                    <button onClick={openAdd} className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90">
                        <Plus className="h-4 w-4" /> Yeni Duyuru
                    </button>
                </div>
            </div>

            <div className="grid gap-4 md:grid-cols-3">
                {[
                    { icon: Send, label: "Aktif Duyuru", value: active.length, color: "bg-blue-100 text-blue-600" },
                    { icon: Users, label: "Ort. Okunma", value: `%${active.length ? Math.round(active.reduce((s, a) => s + (a.readCount / a.totalResidents) * 100, 0) / active.length) : 0}`, color: "bg-green-100 text-green-600" },
                    { icon: Pin, label: "Sabitlenmiş", value: active.filter(a => a.isPinned).length, color: "bg-purple-100 text-purple-600" },
                ].map(s => (
                    <div key={s.label} className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
                        <div className="flex items-center gap-3">
                            <div className={`rounded-lg p-2 ${s.color}`}><s.icon className="h-5 w-5" /></div>
                            <div>
                                <p className="text-2xl font-bold text-gray-900 dark:text-white">{s.value}</p>
                                <p className="text-sm text-gray-500">{s.label}</p>
                            </div>
                        </div>
                    </div>
                ))}
            </div>

            <div className="space-y-4">
                {active.map((announcement) => (
                    <div key={announcement.id} className={`rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800 ${announcement.isPinned ? "border-2 border-primary" : ""}`}>
                        <div className="flex items-start justify-between">
                            <div className="flex-1">
                                <div className="mb-2 flex items-center gap-3">
                                    {announcement.isPinned && <Pin className="h-4 w-4 text-primary" />}
                                    <h3 className="text-lg font-semibold text-gray-900 dark:text-white">{announcement.title}</h3>
                                    <span className={`rounded-full px-3 py-1 text-xs font-medium ${categoryConfig[announcement.category]?.color ?? "bg-gray-100 text-gray-700"}`}>
                                        {categoryConfig[announcement.category]?.label ?? announcement.category}
                                    </span>
                                </div>
                                <p className="mb-4 text-gray-600 dark:text-gray-400">{announcement.content}</p>
                                <div className="flex items-center gap-4 text-sm text-gray-500">
                                    <span className="flex items-center gap-1"><Clock className="h-4 w-4" />{new Date(announcement.createdAt).toLocaleDateString("tr-TR")}</span>
                                    <span className="flex items-center gap-1"><Users className="h-4 w-4" />{announcement.readCount}/{announcement.totalResidents} okudu</span>
                                </div>
                            </div>
                            <div className="ml-4 flex flex-col items-end gap-2">
                                <div className="text-right">
                                    <span className="text-2xl font-bold text-primary">%{Math.round((announcement.readCount / announcement.totalResidents) * 100)}</span>
                                    <p className="text-xs text-gray-500">okunma</p>
                                </div>
                                <div className="flex gap-1 mt-2">
                                    <button onClick={() => togglePin(announcement.id)} title={announcement.isPinned ? "Sabitlemeden Kaldır" : "Sabitle"}
                                        className={`p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 ${announcement.isPinned ? "text-primary" : "text-gray-400"}`}>
                                        <Pin className="h-4 w-4" />
                                    </button>
                                    <button onClick={() => openEdit(announcement)} className="p-1.5 rounded-lg hover:bg-blue-100 text-blue-500">
                                        <Edit className="h-4 w-4" />
                                    </button>
                                    <button onClick={() => setDeleteConfirmId(announcement.id)} className="p-1.5 rounded-lg hover:bg-red-100 text-red-500">
                                        <Trash2 className="h-4 w-4" />
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                ))}
                {active.length === 0 && (
                    <div className="rounded-xl bg-white p-12 text-center text-gray-400 shadow-sm dark:bg-gray-800">Duyuru bulunamadı</div>
                )}
            </div>

            {/* Add/Edit Modal */}
            {showForm && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-lg rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">{editingId ? "Duyuruyu Düzenle" : "Yeni Duyuru Oluştur"}</h2>
                            <button onClick={() => { setShowForm(false); setEditingId(null); }} className="rounded-lg p-1 hover:bg-gray-100 dark:hover:bg-gray-700">
                                <X className="h-5 w-5 text-gray-500" />
                            </button>
                        </div>
                        <form onSubmit={handleSubmit} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Başlık</label>
                                <div className="relative">
                                    <FileText className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                                    <input type="text" required value={formData.title} onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 bg-white py-2 pl-10 pr-4 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                                        placeholder="Duyuru başlığı" />
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">İçerik</label>
                                <textarea required rows={4} value={formData.content} onChange={(e) => setFormData({ ...formData, content: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                                    placeholder="Duyuru içeriği..." />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Kategori</label>
                                    <select value={formData.category} onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm focus:border-primary focus:outline-none dark:border-gray-600 dark:bg-gray-700">
                                        <option value="INFO">Duyuru</option>
                                        <option value="MAINTENANCE">Bakım</option>
                                        <option value="PAYMENT">Ödeme</option>
                                        <option value="EMERGENCY">Acil</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Öncelik</label>
                                    <select value={formData.priority} onChange={(e) => setFormData({ ...formData, priority: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm focus:border-primary focus:outline-none dark:border-gray-600 dark:bg-gray-700">
                                        <option value="LOW">Düşük</option>
                                        <option value="NORMAL">Normal</option>
                                        <option value="HIGH">Yüksek</option>
                                    </select>
                                </div>
                            </div>
                            <div className="flex items-center gap-2">
                                <input type="checkbox" id="isPinned" checked={formData.isPinned} onChange={(e) => setFormData({ ...formData, isPinned: e.target.checked })}
                                    className="h-4 w-4 rounded border-gray-300 text-primary focus:ring-primary" />
                                <label htmlFor="isPinned" className="text-sm text-gray-700 dark:text-gray-300">Sabit duyuru olarak yayınla</label>
                            </div>
                            <div className="flex gap-3 pt-4">
                                <button type="button" onClick={() => { setShowForm(false); setEditingId(null); }} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700">İptal</button>
                                <button type="submit" className="flex-1 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90">{editingId ? "Güncelle" : "Yayınla"}</button>
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
                        <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-2">Duyuruyu Sil</h2>
                        <p className="text-gray-500 text-sm mb-6">Bu duyuru silinecek. Emin misiniz?</p>
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
