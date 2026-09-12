"use client";

import { useState, useCallback } from "react";
import {
    Plus, X, Eye, Copy, Key, Shield, Wifi, Server,
    Monitor, Globe, Edit, Trash2, Clock, Lock,
} from "lucide-react";
import { NotImplementedNotice } from "@/components/ui/data-state";

interface SystemCredential {
    id: number;
    systemName: string;
    category: CredentialCategory;
    username?: string;
    ipAddress?: string;
    port?: number;
    apiKey?: string;
    notes?: string;
    accessLevel: AccessLevel[];
    lastModified: string;
    modifiedBy: string;
    deleted: number;
}

interface AccessLog {
    id: number;
    credentialId: number;
    credentialName: string;
    action: "view" | "copy" | "edit" | "delete";
    user: string;
    timestamp: string;
}

type CredentialCategory = "security" | "infrastructure" | "network" | "software" | "vendor" | "other";
type AccessLevel = "admin" | "board" | "manager" | "technician";

const categoryConfig: Record<CredentialCategory, { label: string; icon: React.ElementType; color: string }> = {
    security: { label: "Güvenlik", icon: Shield, color: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400" },
    infrastructure: { label: "Altyapı", icon: Server, color: "bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400" },
    network: { label: "Ağ", icon: Wifi, color: "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400" },
    software: { label: "Yazılım", icon: Monitor, color: "bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400" },
    vendor: { label: "Tedarikçi", icon: Globe, color: "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400" },
    other: { label: "Diğer", icon: Key, color: "bg-gray-100 text-gray-700 dark:bg-gray-700/30 dark:text-gray-400" },
};

const accessLevelLabels: Record<AccessLevel, string> = {
    admin: "Yönetici",
    board: "YK Üyesi",
    manager: "Site Yöneticisi",
    technician: "Teknisyen",
};

const mockCredentials: SystemCredential[] = [
    { id: 1, systemName: "Kamera DVR Sistemi", category: "security", username: "admin", ipAddress: "192.168.1.100", port: 8080, notes: "Ana giriş kamera sistemi. Hikvision marka.", accessLevel: ["admin", "board", "technician"], lastModified: "2026-01-15T10:30:00", modifiedBy: "Ahmet Yönetici", deleted: 0 },
    { id: 2, systemName: "Yangın Alarm Paneli", category: "security", username: "operator", notes: "B1 katında. Aylık test gerekli.", accessLevel: ["admin", "technician"], lastModified: "2026-01-10T14:00:00", modifiedBy: "Mehmet Teknisyen", deleted: 0 },
    { id: 3, systemName: "Asansör Kontrol Sistemi", category: "infrastructure", username: "service", notes: "Otis servis paneli. Aylık bakım: 15.", accessLevel: ["admin", "technician"], lastModified: "2025-12-20T09:00:00", modifiedBy: "Ahmet Yönetici", deleted: 0 },
    { id: 4, systemName: "Site WiFi Router", category: "network", username: "admin", ipAddress: "192.168.1.1", notes: "TP-Link Archer AX50. Ortak alan WiFi.", accessLevel: ["admin", "technician"], lastModified: "2026-01-05T11:00:00", modifiedBy: "IT Destek", deleted: 0 },
    { id: 5, systemName: "E-Devlet Kurumsal", category: "software", username: "siteeksen@edevlet.gov.tr", notes: "Site Yönetimi kurumsal hesabı.", accessLevel: ["admin", "board"], lastModified: "2026-01-20T16:00:00", modifiedBy: "Ahmet Yönetici", deleted: 0 },
    { id: 6, systemName: "TEDAŞ Portal", category: "vendor", username: "1234567890", notes: "Elektrik abonelik ve fatura takibi.", accessLevel: ["admin", "manager"], lastModified: "2026-01-18T13:00:00", modifiedBy: "Fatma Muhasebe", deleted: 0 },
];

const mockLogs: AccessLog[] = [
    { id: 1, credentialId: 1, credentialName: "Kamera DVR Sistemi", action: "view", user: "Ahmet Yönetici", timestamp: "2026-02-03T09:00:00" },
    { id: 2, credentialId: 4, credentialName: "Site WiFi Router", action: "copy", user: "IT Destek", timestamp: "2026-02-02T14:30:00" },
    { id: 3, credentialId: 2, credentialName: "Yangın Alarm Paneli", action: "view", user: "Mehmet Teknisyen", timestamp: "2026-02-01T11:15:00" },
];

const CURRENT_USER = "Mevcut Kullanıcı";

export default function CredentialsPage() {
    const [credentials, setCredentials] = useState<SystemCredential[]>(mockCredentials);
    const [accessLogs, setAccessLogs] = useState<AccessLog[]>(mockLogs);

    const [selectedCategory, setSelectedCategory] = useState<CredentialCategory | "all">("all");
    const [isAddModalOpen, setIsAddModalOpen] = useState(false);
    const [editingCredential, setEditingCredential] = useState<SystemCredential | null>(null);
    const [isLogModalOpen, setIsLogModalOpen] = useState(false);
    const [deleteConfirmId, setDeleteConfirmId] = useState<number | null>(null);
    const [searchQuery, setSearchQuery] = useState("");
    const [copiedId, setCopiedId] = useState<number | null>(null);

    // Şifreler burada TUTULMAZ — sadece "göster" basılınca API'den çekilirdi.
    // Sunucuda böyle bir uç nokta olmadığı için özellik şu an devre dışı (bkz. handleRevealPassword).
    const [revealedPasswords, setRevealedPasswords] = useState<Record<number, string>>({});
    const [revealError, setRevealError] = useState<string | null>(null);

    const [newCredential, setNewCredential] = useState({
        systemName: "", category: "security" as CredentialCategory,
        username: "", password: "", ipAddress: "", port: "", apiKey: "", notes: "",
        accessLevel: ["admin"] as AccessLevel[],
    });

    // Erişim kaydı yalnızca bu tarayıcı oturumunda tutulur — sunucuya YAZILMAZ.
    // Arayüzde bu durum açıkça belirtilir; aksi halde kullanıcı erişimlerin kalıcı olarak
    // kayıt altına alındığını sanır (2026-09-09 denetim bulgusu).
    const writeLog = useCallback((credentialId: number, credentialName: string, action: AccessLog["action"]) => {
        const log: AccessLog = { id: Date.now(), credentialId, credentialName, action, user: CURRENT_USER, timestamp: new Date().toISOString() };
        setAccessLogs(prev => [log, ...prev]);
    }, []);

    /**
     * DÜZELTME (2026-09-09): Bu fonksiyon daha önce `/credentials/:id/test` ucunu çağırıyordu
     * (ki o bir "şifre göster" ucu değildir) ve hata alınca `catch` içinde kullanıcıya
     * UYDURMA bir şifre ("demo-sifre-2026") gösteriyordu.
     *
     * Backend'de şifre çözüp döndüren bir uç nokta HİÇ YOK: `settings` servisindeki
     * `GetDecrypted` fonksiyonu yazılmış ama hiçbir route'a bağlanmamış ve servisin tüm
     * CRUD işlemleri `// TODO: Veritabanına kaydet` durumunda. Yani gösterilecek gerçek bir
     * sır bulunmuyor.
     *
     * Uydurma şifre göstermek, kullanıcının yanlış bir değeri gerçek sanıp sisteme girmesine
     * yol açar. Bu nedenle özellik, gerçek uç nokta yazılana kadar dürüstçe devre dışıdır.
     */
    const handleRevealPassword = (credential: SystemCredential) => {
        setRevealError(
            "Şifre gösterme özelliği henüz kullanılamıyor: sunucu tarafında şifreleri güvenli biçimde " +
            "çözüp döndüren bir uç nokta bulunmuyor. Bu özellik, kimlik bilgileri servisi veritabanına " +
            "bağlandığında erişim kaydıyla birlikte devreye alınacaktır."
        );
        writeLog(credential.id, credential.systemName, "view");
    };

    const copyToClipboard = async (credential: SystemCredential) => {
        const password = revealedPasswords[credential.id];
        if (!password) {
            setRevealError("Kopyalanacak bir şifre yok — şifre gösterme özelliği henüz kullanılamıyor.");
            return;
        }
        await navigator.clipboard.writeText(password);
        setCopiedId(credential.id);
        setTimeout(() => setCopiedId(null), 2000);
        writeLog(credential.id, credential.systemName, "copy");
    };

    const handleAddCredential = (e: React.FormEvent) => {
        e.preventDefault();
        const now = new Date().toISOString();
        const newEntry: SystemCredential = {
            id: Date.now(), systemName: newCredential.systemName, category: newCredential.category,
            username: newCredential.username || undefined, ipAddress: newCredential.ipAddress || undefined,
            port: newCredential.port ? parseInt(newCredential.port) : undefined,
            apiKey: newCredential.apiKey || undefined, notes: newCredential.notes || undefined,
            accessLevel: newCredential.accessLevel, lastModified: now, modifiedBy: CURRENT_USER, deleted: 0,
        };
        setCredentials(prev => [...prev, newEntry]);
        if (newCredential.password) setRevealedPasswords(prev => ({ ...prev, [newEntry.id]: newCredential.password }));
        setNewCredential({ systemName: "", category: "security", username: "", password: "", ipAddress: "", port: "", apiKey: "", notes: "", accessLevel: ["admin"] });
        setIsAddModalOpen(false);
    };

    const handleEditSave = (e: React.FormEvent) => {
        e.preventDefault();
        if (!editingCredential) return;
        setCredentials(prev => prev.map(c => c.id === editingCredential.id ? { ...editingCredential, lastModified: new Date().toISOString(), modifiedBy: CURRENT_USER } : c));
        writeLog(editingCredential.id, editingCredential.systemName, "edit");
        setEditingCredential(null);
    };

    const handleDelete = (id: number) => {
        const cred = credentials.find(c => c.id === id);
        setCredentials(prev => prev.map(c => c.id === id ? { ...c, deleted: 1 } : c));
        if (cred) writeLog(id, cred.systemName, "delete");
        setDeleteConfirmId(null);
    };

    const toggleAccessLevel = (level: AccessLevel) => {
        setNewCredential(prev => ({
            ...prev, accessLevel: prev.accessLevel.includes(level)
                ? prev.accessLevel.filter(l => l !== level)
                : [...prev.accessLevel, level],
        }));
    };

    const active = credentials.filter(c => c.deleted === 0);
    const filtered = active.filter(c => {
        if (selectedCategory !== "all" && c.category !== selectedCategory) return false;
        if (searchQuery && !c.systemName.toLowerCase().includes(searchQuery.toLowerCase())) return false;
        return true;
    });

    const grouped = filtered.reduce((acc, cred) => {
        if (!acc[cred.category]) acc[cred.category] = [];
        acc[cred.category].push(cred);
        return acc;
    }, {} as Record<CredentialCategory, SystemCredential[]>);

    const categories: Array<{ id: CredentialCategory | "all"; label: string }> = [
        { id: "all", label: "Tümü" },
        ...Object.entries(categoryConfig).map(([id, config]) => ({ id: id as CredentialCategory, label: config.label })),
    ];

    const actionLabels: Record<string, string> = { view: "görüntüledi", copy: "kopyaladı", edit: "düzenledi", delete: "sildi" };

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Sistem Kimlik Bilgileri</h1>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Site sistemlerine ait hesap bilgilerinin envanteri</p>
                </div>
                <div className="flex gap-2">
                    <button onClick={() => setIsLogModalOpen(true)} className="flex items-center gap-2 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">
                        <Clock className="h-4 w-4" /> Erişim Kaydı ({accessLogs.length})
                    </button>
                    <button onClick={() => setIsAddModalOpen(true)} className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90">
                        <Plus className="h-4 w-4" /> Yeni Kayıt
                    </button>
                </div>
            </div>

            <NotImplementedNotice
                detail={
                    "Kimlik bilgileri servisi henüz veritabanına bağlı değil: burada eklenen/düzenlenen kayıtlar " +
                    "kalıcı olarak saklanmaz, sayfa yenilendiğinde kaybolur. Şifre gösterme özelliği de sunucu " +
                    "tarafında hazır olmadığı için devre dışıdır. Erişim kaydı yalnızca bu tarayıcı oturumunda tutulur."
                }
            />

            {revealError && (
                <div role="alert" className="flex items-start gap-3 rounded-lg border border-red-200 bg-red-50 px-4 py-3">
                    <Lock className="mt-0.5 h-5 w-5 shrink-0 text-red-600" aria-hidden="true" />
                    <div className="flex-1 text-sm text-red-800">{revealError}</div>
                    <button
                        type="button"
                        onClick={() => setRevealError(null)}
                        className="rounded p-1 text-red-600 hover:bg-red-100"
                        aria-label="Kapat"
                    >
                        <X className="h-4 w-4" />
                    </button>
                </div>
            )}

            <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
                <div className="relative flex-1 max-w-md">
                    <Key className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                    <input type="text" value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} placeholder="Sistem ara..."
                        className="w-full rounded-lg border border-gray-300 py-2 pl-10 pr-4 text-sm dark:border-gray-600 dark:bg-gray-800" />
                </div>
                <div className="flex gap-2 overflow-x-auto">
                    {categories.map((cat) => (
                        <button key={cat.id} onClick={() => setSelectedCategory(cat.id)}
                            className={`whitespace-nowrap rounded-lg px-4 py-2 text-sm font-medium transition-colors ${selectedCategory === cat.id ? "bg-primary text-white" : "bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-300"}`}>
                            {cat.label}
                        </button>
                    ))}
                </div>
            </div>

            <div className="space-y-6">
                {Object.entries(grouped).map(([category, creds]) => {
                    const config = categoryConfig[category as CredentialCategory];
                    const CategoryIcon = config.icon;
                    return (
                        <div key={category}>
                            <div className="flex items-center gap-2 mb-3">
                                <div className={`rounded-lg p-2 ${config.color}`}><CategoryIcon className="h-4 w-4" /></div>
                                <h2 className="text-lg font-semibold text-gray-900 dark:text-white">{config.label}</h2>
                                <span className="text-sm text-gray-500">({creds.length})</span>
                            </div>
                            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                                {creds.map((credential) => {
                                    const isRevealed = !!revealedPasswords[credential.id];
                                    return (
                                        <div key={credential.id} className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm dark:border-gray-700 dark:bg-gray-800">
                                            <div className="flex items-start justify-between mb-3">
                                                <div>
                                                    <h3 className="font-medium text-gray-900 dark:text-white">{credential.systemName}</h3>
                                                    {credential.ipAddress && (
                                                        <p className="text-xs text-gray-500">{credential.ipAddress}{credential.port ? `:${credential.port}` : ""}</p>
                                                    )}
                                                </div>
                                                <div className="flex gap-1">
                                                    <button onClick={() => setEditingCredential({ ...credential })} className="p-1.5 rounded-lg hover:bg-blue-100 dark:hover:bg-blue-900/30" title="Düzenle">
                                                        <Edit className="h-4 w-4 text-blue-500" />
                                                    </button>
                                                    <button onClick={() => setDeleteConfirmId(credential.id)} className="p-1.5 rounded-lg hover:bg-red-100 dark:hover:bg-red-900/30" title="Sil">
                                                        <Trash2 className="h-4 w-4 text-red-500" />
                                                    </button>
                                                </div>
                                            </div>
                                            {credential.username && (
                                                <div className="mb-2">
                                                    <label className="text-xs text-gray-500">Kullanıcı</label>
                                                    <p className="text-sm font-mono text-gray-900 dark:text-white">{credential.username}</p>
                                                </div>
                                            )}
                                            <div className="mb-3">
                                                <label className="text-xs text-gray-500 flex items-center gap-1">
                                                    <Lock className="h-3 w-3" /> Şifre
                                                </label>
                                                <div className="flex items-center gap-2 bg-gray-50 dark:bg-gray-700/50 rounded-lg px-3 py-1.5 mt-1">
                                                    <p className="flex-1 text-sm font-mono text-gray-900 dark:text-white tracking-widest">
                                                        {isRevealed ? revealedPasswords[credential.id] : "••••••••••••"}
                                                    </p>
                                                    <button
                                                        onClick={() => handleRevealPassword(credential)}
                                                        className="p-1 rounded hover:bg-gray-200 dark:hover:bg-gray-600"
                                                        title="Şifre gösterme henüz kullanılamıyor"
                                                    >
                                                        <Eye className="h-4 w-4 text-gray-400" />
                                                    </button>
                                                    <button
                                                        onClick={() => copyToClipboard(credential)}
                                                        className="p-1 rounded hover:bg-gray-200 dark:hover:bg-gray-600"
                                                        title="Kopyala"
                                                    >
                                                        <Copy className={`h-4 w-4 ${copiedId === credential.id ? "text-green-500" : "text-gray-500"}`} />
                                                    </button>
                                                </div>
                                            </div>
                                            <div className="flex flex-wrap gap-1">
                                                {credential.accessLevel.map((level) => (
                                                    <span key={level} className="rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-600 dark:bg-gray-700 dark:text-gray-400">
                                                        {accessLevelLabels[level]}
                                                    </span>
                                                ))}
                                            </div>
                                            <div className="mt-3 pt-3 border-t border-gray-100 dark:border-gray-700">
                                                <p className="text-xs text-gray-400">Son güncelleme: {new Date(credential.lastModified).toLocaleDateString("tr-TR")} — {credential.modifiedBy}</p>
                                            </div>
                                        </div>
                                    );
                                })}
                            </div>
                        </div>
                    );
                })}
                {filtered.length === 0 && (
                    <div className="rounded-xl bg-white p-12 text-center text-gray-400 shadow-sm dark:bg-gray-800">Kayıt bulunamadı</div>
                )}
            </div>

            {/* Add Modal */}
            {isAddModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-lg rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800 max-h-[90vh] overflow-y-auto">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">Yeni Kimlik Bilgisi</h2>
                            <button onClick={() => setIsAddModalOpen(false)} className="rounded-lg p-1 hover:bg-gray-100 dark:hover:bg-gray-700"><X className="h-5 w-5 text-gray-500" /></button>
                        </div>
                        <form onSubmit={handleAddCredential} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Sistem Adı</label>
                                <input type="text" required value={newCredential.systemName} onChange={(e) => setNewCredential({ ...newCredential, systemName: e.target.value })}
                                    placeholder="Örn: Kamera DVR Sistemi"
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Kategori</label>
                                <select value={newCredential.category} onChange={(e) => setNewCredential({ ...newCredential, category: e.target.value as CredentialCategory })}
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700">
                                    {Object.entries(categoryConfig).map(([key, config]) => <option key={key} value={key}>{config.label}</option>)}
                                </select>
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Kullanıcı Adı</label>
                                    <input type="text" value={newCredential.username} onChange={(e) => setNewCredential({ ...newCredential, username: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Şifre *</label>
                                    <input type="password" required value={newCredential.password} onChange={(e) => setNewCredential({ ...newCredential, password: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                                </div>
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">IP Adresi</label>
                                    <input type="text" value={newCredential.ipAddress} onChange={(e) => setNewCredential({ ...newCredential, ipAddress: e.target.value })}
                                        placeholder="192.168.1.100" className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Port</label>
                                    <input type="number" value={newCredential.port} onChange={(e) => setNewCredential({ ...newCredential, port: e.target.value })}
                                        placeholder="8080" className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Notlar</label>
                                <textarea rows={2} value={newCredential.notes} onChange={(e) => setNewCredential({ ...newCredential, notes: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Erişim Yetkileri</label>
                                <div className="flex flex-wrap gap-2">
                                    {Object.entries(accessLevelLabels).map(([level, label]) => (
                                        <button key={level} type="button" onClick={() => toggleAccessLevel(level as AccessLevel)}
                                            className={`rounded-lg px-3 py-1.5 text-sm font-medium transition-colors ${newCredential.accessLevel.includes(level as AccessLevel) ? "bg-primary text-white" : "bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-300"}`}>
                                            {label}
                                        </button>
                                    ))}
                                </div>
                            </div>
                            <div className="flex gap-3 pt-4">
                                <button type="button" onClick={() => setIsAddModalOpen(false)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">İptal</button>
                                <button type="submit" className="flex-1 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90">Kaydet</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Edit Modal */}
            {editingCredential && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-lg rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800 max-h-[90vh] overflow-y-auto">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">Düzenle: {editingCredential.systemName}</h2>
                            <button onClick={() => setEditingCredential(null)}><X className="h-5 w-5 text-gray-500" /></button>
                        </div>
                        <form onSubmit={handleEditSave} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Sistem Adı</label>
                                <input type="text" required value={editingCredential.systemName} onChange={e => setEditingCredential({ ...editingCredential, systemName: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Kullanıcı Adı</label>
                                    <input type="text" value={editingCredential.username ?? ""} onChange={e => setEditingCredential({ ...editingCredential, username: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">IP Adresi</label>
                                    <input type="text" value={editingCredential.ipAddress ?? ""} onChange={e => setEditingCredential({ ...editingCredential, ipAddress: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Notlar</label>
                                <textarea rows={2} value={editingCredential.notes ?? ""} onChange={e => setEditingCredential({ ...editingCredential, notes: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700" />
                            </div>
                            <div className="flex gap-3 pt-2">
                                <button type="button" onClick={() => setEditingCredential(null)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">İptal</button>
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
                        <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-2">Kimlik Bilgisini Sil</h2>
                        <p className="text-gray-500 text-sm mb-6">Bu kayıt silinecek ve işlem loglanacak. Emin misiniz?</p>
                        <div className="flex gap-3">
                            <button onClick={() => setDeleteConfirmId(null)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">İptal</button>
                            <button onClick={() => handleDelete(deleteConfirmId)} className="flex-1 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700">Sil</button>
                        </div>
                    </div>
                </div>
            )}

            {/* Access Log Modal */}
            {isLogModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-lg rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">Erişim Geçmişi</h2>
                            <button onClick={() => setIsLogModalOpen(false)} className="rounded-lg p-1 hover:bg-gray-100 dark:hover:bg-gray-700"><X className="h-5 w-5 text-gray-500" /></button>
                        </div>
                        <div className="space-y-3 max-h-96 overflow-y-auto">
                            {accessLogs.map((log) => (
                                <div key={log.id} className="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                                    <div className={`rounded-full p-2 ${log.action === "view" ? "bg-blue-100 text-blue-600" : log.action === "copy" ? "bg-green-100 text-green-600" : log.action === "delete" ? "bg-red-100 text-red-600" : "bg-yellow-100 text-yellow-600"}`}>
                                        {log.action === "view" ? <Eye className="h-4 w-4" /> : log.action === "copy" ? <Copy className="h-4 w-4" /> : log.action === "delete" ? <Trash2 className="h-4 w-4" /> : <Edit className="h-4 w-4" />}
                                    </div>
                                    <div className="flex-1">
                                        <p className="text-sm font-medium text-gray-900 dark:text-white">
                                            {log.user} <span className="font-normal text-gray-500">{actionLabels[log.action] ?? log.action}</span>
                                        </p>
                                        <p className="text-xs text-gray-500">{log.credentialName}</p>
                                    </div>
                                    <p className="text-xs text-gray-400">{new Date(log.timestamp).toLocaleString("tr-TR")}</p>
                                </div>
                            ))}
                            {accessLogs.length === 0 && <p className="text-center text-gray-400 py-8">Henüz log kaydı yok</p>}
                        </div>
                        <button onClick={() => setIsLogModalOpen(false)} className="w-full mt-4 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">Kapat</button>
                    </div>
                </div>
            )}
        </div>
    );
}

const actionLabels: Record<string, string> = { view: "görüntüledi", copy: "kopyaladı", edit: "düzenledi", delete: "sildi" };
