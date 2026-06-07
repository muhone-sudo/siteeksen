"use client";

import { useState, useEffect, useRef } from "react";
import { Plus, Search, MoreVertical, Home, X, Edit, Trash2, Phone, User, Upload, Download, AlertTriangle, Loader2, Mail } from "lucide-react";
import apiClient from "@/lib/api-client";

interface Resident {
    id: string;
    first_name: string;
    last_name: string;
    phone: string;
    email: string;
    unit_id: string;
    unit: string;
    role: string;
    is_active: boolean;
}

interface Unit {
    id: string;
    block: string;
    floor: number;
    door_number: string;
}

const ROLE_LABELS: Record<string, string> = {
    OWNER: "Ev Sahibi",
    TENANT: "Kiracı",
    PROXY: "Vekil",
};
const ROLE_VALUES = Object.keys(ROLE_LABELS);

const SAMPLE_CSV = `Ad Soyad,Telefon,Birim ID,Rol
Ahmet Yılmaz,+90 555 123 4567,<unit-uuid>,OWNER
Mehmet Demir,+90 555 987 6543,<unit-uuid>,TENANT`;

function downloadSampleCSV() {
    const blob = new Blob([SAMPLE_CSV], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a"); a.href = url; a.download = "sakinler_ornek.csv"; a.click();
    URL.revokeObjectURL(url);
}

export default function ResidentsPage() {
    const [searchQuery, setSearchQuery] = useState("");
    const [selectedBlock, setSelectedBlock] = useState("all");
    const [selectedRole, setSelectedRole] = useState("all");
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingResident, setEditingResident] = useState<Resident | null>(null);
    const [openMenuId, setOpenMenuId] = useState<string | null>(null);
    const [residents, setResidents] = useState<Resident[]>([]);
    const [units, setUnits] = useState<Unit[]>([]);
    const [loading, setLoading] = useState(true);
    const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);
    const [csvError, setCsvError] = useState("");
    const [formError, setFormError] = useState("");
    const [submitting, setSubmitting] = useState(false);
    const menuRef = useRef<HTMLDivElement>(null);
    const fileInputRef = useRef<HTMLInputElement>(null);

    const [formData, setFormData] = useState({ first_name: "", last_name: "", phone: "", email: "", unit_id: "", role: "OWNER" });

    useEffect(() => {
        apiClient.loadToken();
        load();
    }, []);

    async function load() {
        setLoading(true);
        try {
            const [resRes, unitRes] = await Promise.all([apiClient.getResidents(), apiClient.getUnits()]);
            setResidents(resRes?.data ?? resRes ?? []);
            setUnits(unitRes?.data ?? unitRes ?? []);
        } catch {
            setResidents([]);
            setUnits([]);
        } finally {
            setLoading(false);
        }
    }

    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (menuRef.current && !menuRef.current.contains(event.target as Node)) setOpenMenuId(null);
        };
        document.addEventListener("mousedown", handleClickOutside);
        return () => document.removeEventListener("mousedown", handleClickOutside);
    }, []);

    const active = residents.filter(r => r.is_active);

    const filteredResidents = active.filter((r) => {
        const fullName = `${r.first_name} ${r.last_name}`.toLowerCase();
        const matchesSearch = fullName.includes(searchQuery.toLowerCase()) || r.unit.toLowerCase().includes(searchQuery.toLowerCase());
        const matchesBlock = selectedBlock === "all" || r.unit.startsWith(selectedBlock);
        const matchesRole = selectedRole === "all" || r.role === selectedRole;
        return matchesSearch && matchesBlock && matchesRole;
    });

    const blocks = Array.from(new Set(units.map(u => u.block).filter(Boolean))).sort();

    const openAdd = () => {
        setEditingResident(null);
        setFormError("");
        setFormData({ first_name: "", last_name: "", phone: "", email: "", unit_id: units[0]?.id ?? "", role: "OWNER" });
        setIsModalOpen(true);
    };
    const openEdit = (r: Resident) => {
        setEditingResident(r);
        setFormError("");
        setFormData({ first_name: r.first_name, last_name: r.last_name, phone: r.phone, email: r.email, unit_id: r.unit_id, role: r.role });
        setIsModalOpen(true);
        setOpenMenuId(null);
    };

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        setFormError("");
        setSubmitting(true);
        try {
            if (editingResident) {
                await apiClient.updateResident(editingResident.id, { role: formData.role });
            } else {
                await apiClient.createResident({
                    first_name: formData.first_name,
                    last_name: formData.last_name,
                    phone: formData.phone,
                    email: formData.email || undefined,
                    unit_id: formData.unit_id,
                    role: formData.role,
                });
            }
            setIsModalOpen(false);
            await load();
        } catch (err: any) {
            setFormError(err?.response?.data?.error ?? "İşlem gerçekleştirilemedi, lütfen tekrar deneyin");
        } finally {
            setSubmitting(false);
        }
    }

    async function handleDelete(id: string) {
        try {
            await apiClient.updateResident(id, { is_active: false });
            setDeleteConfirmId(null);
            setOpenMenuId(null);
            await load();
        } catch {
            setCsvError("Sakin pasifleştirilemedi, lütfen tekrar deneyin.");
            setDeleteConfirmId(null);
        }
    }

    function handleCSVUpload(e: React.ChangeEvent<HTMLInputElement>) {
        const file = e.target.files?.[0];
        if (!file) return;
        const reader = new FileReader();
        reader.onload = async (ev) => {
            try {
                const lines = (ev.target?.result as string).trim().split("\n").slice(1);
                const rows = lines.map(line => {
                    const [name, phone, unit_id, role] = line.split(",").map(s => s.trim());
                    const [first_name, ...rest] = name.split(" ");
                    return { first_name, last_name: rest.join(" ") || first_name, phone, unit_id, role: role || "OWNER" };
                }).filter(r => r.first_name && r.phone && r.unit_id);

                if (rows.length === 0) { setCsvError("CSV boş veya hatalı format."); return; }
                for (const row of rows) {
                    await apiClient.createResident(row);
                }
                setCsvError("");
                await load();
            } catch {
                setCsvError("CSV içe aktarılamadı. Örnek formatı indirip kontrol edin.");
            }
        };
        reader.readAsText(file);
        e.target.value = "";
    }

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Sakinler</h1>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Toplam {active.length} aktif sakin</p>
                </div>
                <div className="flex gap-2">
                    <button onClick={downloadSampleCSV} className="flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm font-medium hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800">
                        <Download className="h-4 w-4" /> Örnek CSV
                    </button>
                    <button onClick={() => fileInputRef.current?.click()} className="flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm font-medium hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800">
                        <Upload className="h-4 w-4" /> CSV Yükle
                    </button>
                    <input ref={fileInputRef} type="file" accept=".csv" className="hidden" onChange={handleCSVUpload} />
                    <button onClick={openAdd} className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90">
                        <Plus className="h-4 w-4" /> Yeni Sakin
                    </button>
                </div>
            </div>

            {csvError && (
                <div className="flex items-center gap-2 rounded-lg bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700">
                    <AlertTriangle className="h-4 w-4" /> {csvError}
                </div>
            )}

            <div className="flex gap-4">
                <div className="relative flex-1">
                    <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                    <input type="text" placeholder="İsim veya daire ara..." value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)}
                        className="w-full rounded-lg border border-gray-300 bg-white py-2 pl-10 pr-4 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-800" />
                </div>
                <select value={selectedBlock} onChange={(e) => setSelectedBlock(e.target.value)}
                    className="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-800">
                    <option value="all">Tüm Bloklar</option>
                    {blocks.map(b => <option key={b} value={b}>{b} Blok</option>)}
                </select>
                <select value={selectedRole} onChange={(e) => setSelectedRole(e.target.value)}
                    className="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-800">
                    <option value="all">Tüm Roller</option>
                    {ROLE_VALUES.map(r => <option key={r} value={r}>{ROLE_LABELS[r]}</option>)}
                </select>
            </div>

            <div className="overflow-hidden rounded-xl bg-white shadow-sm dark:bg-gray-800">
                {loading ? (
                    <div className="flex items-center justify-center gap-2 px-6 py-16 text-gray-400">
                        <Loader2 className="h-5 w-5 animate-spin" /> Yükleniyor...
                    </div>
                ) : (
                <table className="w-full">
                    <thead className="border-b border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-900">
                        <tr>
                            <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Sakin</th>
                            <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Daire</th>
                            <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Rol</th>
                            <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Durum</th>
                            <th className="px-6 py-3 text-right text-xs font-medium uppercase text-gray-500">İşlem</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                        {filteredResidents.map((resident) => (
                            <tr key={resident.id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50">
                                <td className="px-6 py-4">
                                    <div className="flex items-center gap-3">
                                        <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10 text-primary font-medium">
                                            {resident.first_name[0]}{resident.last_name[0]}
                                        </div>
                                        <div>
                                            <p className="font-medium text-gray-900 dark:text-white">{resident.first_name} {resident.last_name}</p>
                                            <p className="text-sm text-gray-500">{resident.phone}</p>
                                        </div>
                                    </div>
                                </td>
                                <td className="px-6 py-4">
                                    <div className="flex items-center gap-2">
                                        <Home className="h-4 w-4 text-gray-400" />
                                        <span className="text-gray-900 dark:text-white">{resident.unit}</span>
                                    </div>
                                </td>
                                <td className="px-6 py-4 text-gray-900 dark:text-white">{ROLE_LABELS[resident.role] ?? resident.role}</td>
                                <td className="px-6 py-4">
                                    <span className="rounded-full bg-green-100 px-3 py-1 text-xs font-medium text-green-700">Aktif</span>
                                </td>
                                <td className="px-6 py-4 text-right relative">
                                    <button onClick={() => setOpenMenuId(openMenuId === resident.id ? null : resident.id)}
                                        className="rounded-lg p-2 hover:bg-gray-100 dark:hover:bg-gray-700">
                                        <MoreVertical className="h-4 w-4 text-gray-500" />
                                    </button>
                                    {openMenuId === resident.id && (
                                        <div ref={menuRef} className="absolute right-6 top-12 z-10 w-40 rounded-lg border border-gray-200 bg-white py-1 shadow-lg dark:border-gray-700 dark:bg-gray-800">
                                            <button onClick={() => openEdit(resident)} className="flex w-full items-center gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-700">
                                                <Edit className="h-4 w-4" /> Düzenle
                                            </button>
                                            <button onClick={() => { setDeleteConfirmId(resident.id); setOpenMenuId(null); }}
                                                className="flex w-full items-center gap-2 px-4 py-2 text-sm text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20">
                                                <Trash2 className="h-4 w-4" /> Pasifleştir
                                            </button>
                                        </div>
                                    )}
                                </td>
                            </tr>
                        ))}
                        {filteredResidents.length === 0 && (
                            <tr><td colSpan={5} className="px-6 py-12 text-center text-gray-400">Sakin bulunamadı</td></tr>
                        )}
                    </tbody>
                </table>
                )}
            </div>

            {/* Add/Edit Modal */}
            {isModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">
                                {editingResident ? "Sakini Düzenle" : "Yeni Sakin Ekle"}
                            </h2>
                            <button onClick={() => setIsModalOpen(false)} className="rounded-lg p-1 hover:bg-gray-100 dark:hover:bg-gray-700">
                                <X className="h-5 w-5 text-gray-500" />
                            </button>
                        </div>
                        {formError && (
                            <div className="mb-4 flex items-center gap-2 rounded-lg bg-red-50 border border-red-200 px-4 py-2 text-sm text-red-700">
                                <AlertTriangle className="h-4 w-4" /> {formError}
                            </div>
                        )}
                        <form onSubmit={handleSubmit} className="space-y-4">
                            <div className="grid grid-cols-2 gap-3">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Ad</label>
                                    <div className="relative">
                                        <User className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                                        <input type="text" required disabled={!!editingResident} value={formData.first_name} onChange={(e) => setFormData({ ...formData, first_name: e.target.value })}
                                            className="w-full rounded-lg border border-gray-300 bg-white py-2 pl-10 pr-4 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700 disabled:opacity-60"
                                            placeholder="Ahmet" />
                                    </div>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Soyad</label>
                                    <input type="text" required disabled={!!editingResident} value={formData.last_name} onChange={(e) => setFormData({ ...formData, last_name: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 bg-white py-2 px-4 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700 disabled:opacity-60"
                                        placeholder="Yılmaz" />
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Telefon</label>
                                <div className="relative">
                                    <Phone className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                                    <input type="tel" required disabled={!!editingResident} value={formData.phone} onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 bg-white py-2 pl-10 pr-4 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700 disabled:opacity-60"
                                        placeholder="+90 555 123 4567" />
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">E-posta (opsiyonel)</label>
                                <div className="relative">
                                    <Mail className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                                    <input type="email" disabled={!!editingResident} value={formData.email} onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 bg-white py-2 pl-10 pr-4 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700 disabled:opacity-60"
                                        placeholder="ahmet@ornek.com" />
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Daire</label>
                                <div className="relative">
                                    <Home className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400 z-10" />
                                    <select required disabled={!!editingResident} value={formData.unit_id} onChange={(e) => setFormData({ ...formData, unit_id: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 bg-white py-2 pl-10 pr-4 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700 disabled:opacity-60">
                                        <option value="">Birim seçin</option>
                                        {units.map(u => <option key={u.id} value={u.id}>{u.block ? `${u.block}-${u.door_number}` : u.door_number} (Kat {u.floor})</option>)}
                                    </select>
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Rol</label>
                                <select value={formData.role} onChange={(e) => setFormData({ ...formData, role: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700">
                                    {ROLE_VALUES.map(r => <option key={r} value={r}>{ROLE_LABELS[r]}</option>)}
                                </select>
                            </div>
                            <div className="flex gap-3 pt-4">
                                <button type="button" onClick={() => setIsModalOpen(false)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700">
                                    İptal
                                </button>
                                <button type="submit" disabled={submitting} className="flex-1 flex items-center justify-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90 disabled:opacity-60">
                                    {submitting && <Loader2 className="h-4 w-4 animate-spin" />}
                                    {editingResident ? "Güncelle" : "Kaydet"}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Delete Confirm Modal */}
            {deleteConfirmId !== null && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-sm rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800 text-center">
                        <div className="flex justify-center mb-4">
                            <div className="rounded-full bg-red-100 p-3">
                                <Trash2 className="h-6 w-6 text-red-600" />
                            </div>
                        </div>
                        <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-2">Sakini Pasifleştir</h2>
                        <p className="text-gray-500 text-sm mb-6">Bu sakinin birim ilişkisi pasifleştirilecek (geri alınabilir). Emin misiniz?</p>
                        <div className="flex gap-3">
                            <button onClick={() => setDeleteConfirmId(null)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">
                                İptal
                            </button>
                            <button onClick={() => handleDelete(deleteConfirmId)} className="flex-1 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700">
                                Pasifleştir
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
