"use client";

import { useState, useEffect } from "react";
import apiClient from "@/lib/api-client";
import {
    Plus,
    X,
    Eye,
    EyeOff,
    Copy,
    Key,
    Shield,
    Wifi,
    Server,
    Camera,
    Flame,
    Building,
    Monitor,
    Globe,
    Edit,
    Trash2,
    Clock,
    User,
    Lock,
    CheckCircle,
} from "lucide-react";

// Types
interface SystemCredential {
    id: number;
    systemName: string;
    category: CredentialCategory;
    username?: string;
    password: string;
    ipAddress?: string;
    port?: number;
    apiKey?: string;
    notes?: string;
    accessLevel: AccessLevel[];
    lastModified: string;
    modifiedBy: string;
}

interface AccessLog {
    id: number;
    credentialId: number;
    action: "view" | "copy" | "edit";
    user: string;
    timestamp: string;
}

type CredentialCategory = "security" | "infrastructure" | "network" | "software" | "vendor" | "other";
type AccessLevel = "admin" | "board" | "manager" | "technician";

// Config
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

// Mock data
const mockCredentials: SystemCredential[] = [
    {
        id: 1,
        systemName: "Kamera DVR Sistemi",
        category: "security",
        username: "admin",
        password: "Kam3ra2026!",
        ipAddress: "192.168.1.100",
        port: 8080,
        notes: "Ana giriş kamera sistemi. Hikvision marka.",
        accessLevel: ["admin", "board", "technician"],
        lastModified: "2026-01-15T10:30:00",
        modifiedBy: "Ahmet Yönetici",
    },
    {
        id: 2,
        systemName: "Yangın Alarm Paneli",
        category: "security",
        username: "operator",
        password: "Fire@2026",
        notes: "B1 katında. Aylık test gerekli.",
        accessLevel: ["admin", "technician"],
        lastModified: "2026-01-10T14:00:00",
        modifiedBy: "Mehmet Teknisyen",
    },
    {
        id: 3,
        systemName: "Asansör Kontrol Sistemi",
        category: "infrastructure",
        username: "service",
        password: "Elev@t0r2026",
        notes: "Otis servis paneli. Aylık bakım: 15.",
        accessLevel: ["admin", "technician"],
        lastModified: "2025-12-20T09:00:00",
        modifiedBy: "Ahmet Yönetici",
    },
    {
        id: 4,
        systemName: "Site WiFi Router",
        category: "network",
        username: "admin",
        password: "W1f1S1te2026!",
        ipAddress: "192.168.1.1",
        notes: "TP-Link Archer AX50. Ortak alan WiFi.",
        accessLevel: ["admin", "technician"],
        lastModified: "2026-01-05T11:00:00",
        modifiedBy: "IT Destek",
    },
    {
        id: 5,
        systemName: "E-Devlet Kurumsal",
        category: "software",
        username: "siteeksen@edevlet.gov.tr",
        password: "eDevlet2026#",
        notes: "Site Yönetimi kurumsal hesabı.",
        accessLevel: ["admin", "board"],
        lastModified: "2026-01-20T16:00:00",
        modifiedBy: "Ahmet Yönetici",
    },
    {
        id: 6,
        systemName: "TEDAŞ Portal",
        category: "vendor",
        username: "1234567890",
        password: "Tedas@2026",
        notes: "Elektrik abonelik ve fatura takibi.",
        accessLevel: ["admin", "manager"],
        lastModified: "2026-01-18T13:00:00",
        modifiedBy: "Fatma Muhasebe",
    },
];

const mockAccessLogs: AccessLog[] = [
    { id: 1, credentialId: 1, action: "view", user: "Ahmet Yönetici", timestamp: "2026-02-03T09:00:00" },
    { id: 2, credentialId: 4, action: "copy", user: "IT Destek", timestamp: "2026-02-02T14:30:00" },
    { id: 3, credentialId: 2, action: "view", user: "Mehmet Teknisyen", timestamp: "2026-02-01T11:15:00" },
];

export default function CredentialsPage() {
    const [credentials, setCredentials] = useState(mockCredentials);
    const [accessLogs] = useState(mockAccessLogs);

    useEffect(() => {
        apiClient.loadToken();
        apiClient.getApiCredentials().then((data) => {
            const items = data?.data ?? data;
            if (Array.isArray(items) && items.length > 0) {
                const mapped = items.map((c: any, idx: number) => ({
                    id: idx + 1000,
                    systemName: c.display_name ?? c.service_name,
                    category: c.category === "banking" ? "vendor"
                        : c.category === "payment" ? "vendor"
                        : c.category === "ai" ? "software"
                        : c.category === "push" ? "infrastructure"
                        : "other" as CredentialCategory,
                    username: c.api_key_masked ?? "",
                    password: "••••••••",
                    notes: `Servis: ${c.service_name}. Durum: ${c.test_status ?? "bilinmiyor"}`,
                    accessLevel: ["admin"] as AccessLevel[],
                    lastModified: c.last_modified ?? new Date().toISOString(),
                    modifiedBy: c.modified_by ?? "sistem",
                }));
                setCredentials([...mockCredentials, ...mapped]);
            }
        }).catch(() => {});
    }, []);
    const [selectedCategory, setSelectedCategory] = useState<CredentialCategory | "all">("all");
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [isViewModalOpen, setIsViewModalOpen] = useState(false);
    const [isLogModalOpen, setIsLogModalOpen] = useState(false);
    const [selectedCredential, setSelectedCredential] = useState<SystemCredential | null>(null);
    const [visiblePasswords, setVisiblePasswords] = useState<Set<number>>(new Set());
    const [copiedId, setCopiedId] = useState<number | null>(null);
    const [searchQuery, setSearchQuery] = useState("");

    // Form state
    const [newCredential, setNewCredential] = useState({
        systemName: "",
        category: "security" as CredentialCategory,
        username: "",
        password: "",
        ipAddress: "",
        port: "",
        apiKey: "",
        notes: "",
        accessLevel: ["admin"] as AccessLevel[],
    });

    const filteredCredentials = credentials.filter((c) => {
        if (selectedCategory !== "all" && c.category !== selectedCategory) return false;
        if (searchQuery && !c.systemName.toLowerCase().includes(searchQuery.toLowerCase())) return false;
        return true;
    });

    const groupedCredentials = filteredCredentials.reduce((acc, cred) => {
        if (!acc[cred.category]) acc[cred.category] = [];
        acc[cred.category].push(cred);
        return acc;
    }, {} as Record<CredentialCategory, SystemCredential[]>);

    const togglePasswordVisibility = (id: number) => {
        const newVisible = new Set(visiblePasswords);
        if (newVisible.has(id)) {
            newVisible.delete(id);
        } else {
            newVisible.add(id);
            // Log görüntüleme
            console.log(`Password viewed for credential ${id}`);
        }
        setVisiblePasswords(newVisible);
    };

    const copyToClipboard = async (text: string, id: number) => {
        await navigator.clipboard.writeText(text);
        setCopiedId(id);
        setTimeout(() => setCopiedId(null), 2000);
        // Log kopyalama
        console.log(`Password copied for credential ${id}`);
    };

    const handleAddCredential = (e: React.FormEvent) => {
        e.preventDefault();
        const today = new Date().toISOString();
        setCredentials([
            ...credentials,
            {
                id: credentials.length + 1,
                ...newCredential,
                port: newCredential.port ? parseInt(newCredential.port) : undefined,
                lastModified: today,
                modifiedBy: "Mevcut Kullanıcı",
            },
        ]);
        setNewCredential({
            systemName: "",
            category: "security",
            username: "",
            password: "",
            ipAddress: "",
            port: "",
            apiKey: "",
            notes: "",
            accessLevel: ["admin"],
        });
        setIsModalOpen(false);
    };

    const handleViewCredential = (credential: SystemCredential) => {
        setSelectedCredential(credential);
        setIsViewModalOpen(true);
    };

    const handleDeleteCredential = (id: number) => {
        if (confirm("Bu kimlik bilgisini silmek istediğinize emin misiniz?")) {
            setCredentials(credentials.filter((c) => c.id !== id));
        }
    };

    const toggleAccessLevel = (level: AccessLevel) => {
        if (newCredential.accessLevel.includes(level)) {
            setNewCredential({
                ...newCredential,
                accessLevel: newCredential.accessLevel.filter((l) => l !== level),
            });
        } else {
            setNewCredential({
                ...newCredential,
                accessLevel: [...newCredential.accessLevel, level],
            });
        }
    };

    const categories: Array<{ id: CredentialCategory | "all"; label: string }> = [
        { id: "all", label: "Tümü" },
        ...Object.entries(categoryConfig).map(([id, config]) => ({ id: id as CredentialCategory, label: config.label })),
    ];

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Sistem Kimlik Bilgileri</h1>
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                        Güvenli şifre ve hesap yönetimi
                    </p>
                </div>
                <div className="flex gap-2">
                    <button
                        onClick={() => setIsLogModalOpen(true)}
                        className="flex items-center gap-2 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300"
                    >
                        <Clock className="h-4 w-4" />
                        Erişim Logu
                    </button>
                    <button
                        onClick={() => setIsModalOpen(true)}
                        className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90"
                    >
                        <Plus className="h-4 w-4" />
                        Yeni Kayıt
                    </button>
                </div>
            </div>

            {/* Search and Filters */}
            <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
                <div className="relative flex-1 max-w-md">
                    <Key className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                    <input
                        type="text"
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        placeholder="Sistem ara..."
                        className="w-full rounded-lg border border-gray-300 py-2 pl-10 pr-4 text-sm dark:border-gray-600 dark:bg-gray-800"
                    />
                </div>
                <div className="flex gap-2 overflow-x-auto">
                    {categories.map((cat) => (
                        <button
                            key={cat.id}
                            onClick={() => setSelectedCategory(cat.id)}
                            className={`whitespace-nowrap rounded-lg px-4 py-2 text-sm font-medium transition-colors ${selectedCategory === cat.id
                                    ? "bg-primary text-white"
                                    : "bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-300"
                                }`}
                        >
                            {cat.label}
                        </button>
                    ))}
                </div>
            </div>

            {/* Credentials Grid */}
            <div className="space-y-6">
                {Object.entries(groupedCredentials).map(([category, creds]) => {
                    const config = categoryConfig[category as CredentialCategory];
                    const CategoryIcon = config.icon;
                    return (
                        <div key={category}>
                            <div className="flex items-center gap-2 mb-3">
                                <div className={`rounded-lg p-2 ${config.color}`}>
                                    <CategoryIcon className="h-4 w-4" />
                                </div>
                                <h2 className="text-lg font-semibold text-gray-900 dark:text-white">{config.label}</h2>
                                <span className="text-sm text-gray-500">({creds.length})</span>
                            </div>
                            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                                {creds.map((credential) => {
                                    const isPasswordVisible = visiblePasswords.has(credential.id);
                                    const isCopied = copiedId === credential.id;
                                    return (
                                        <div
                                            key={credential.id}
                                            className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                                        >
                                            <div className="flex items-start justify-between mb-3">
                                                <div>
                                                    <h3 className="font-medium text-gray-900 dark:text-white">{credential.systemName}</h3>
                                                    {credential.ipAddress && (
                                                        <p className="text-xs text-gray-500">{credential.ipAddress}{credential.port ? `:${credential.port}` : ""}</p>
                                                    )}
                                                </div>
                                                <div className="flex gap-1">
                                                    <button
                                                        onClick={() => handleViewCredential(credential)}
                                                        className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700"
                                                        title="Detay"
                                                    >
                                                        <Eye className="h-4 w-4 text-gray-500" />
                                                    </button>
                                                    <button
                                                        onClick={() => handleDeleteCredential(credential.id)}
                                                        className="p-1.5 rounded-lg hover:bg-red-100 dark:hover:bg-red-900/30"
                                                        title="Sil"
                                                    >
                                                        <Trash2 className="h-4 w-4 text-red-500" />
                                                    </button>
                                                </div>
                                            </div>

                                            {/* Username */}
                                            {credential.username && (
                                                <div className="mb-2">
                                                    <label className="text-xs text-gray-500">Kullanıcı</label>
                                                    <p className="text-sm font-mono text-gray-900 dark:text-white">{credential.username}</p>
                                                </div>
                                            )}

                                            {/* Password */}
                                            <div className="mb-3">
                                                <label className="text-xs text-gray-500">Şifre</label>
                                                <div className="flex items-center gap-2">
                                                    <p className="flex-1 text-sm font-mono text-gray-900 dark:text-white">
                                                        {isPasswordVisible ? credential.password : "••••••••••"}
                                                    </p>
                                                    <button
                                                        onClick={() => togglePasswordVisibility(credential.id)}
                                                        className="p-1 rounded hover:bg-gray-100 dark:hover:bg-gray-700"
                                                        title={isPasswordVisible ? "Gizle" : "Göster"}
                                                    >
                                                        {isPasswordVisible ? (
                                                            <EyeOff className="h-4 w-4 text-gray-500" />
                                                        ) : (
                                                            <Eye className="h-4 w-4 text-gray-500" />
                                                        )}
                                                    </button>
                                                    <button
                                                        onClick={() => copyToClipboard(credential.password, credential.id)}
                                                        className="p-1 rounded hover:bg-gray-100 dark:hover:bg-gray-700"
                                                        title="Kopyala"
                                                    >
                                                        {isCopied ? (
                                                            <CheckCircle className="h-4 w-4 text-green-500" />
                                                        ) : (
                                                            <Copy className="h-4 w-4 text-gray-500" />
                                                        )}
                                                    </button>
                                                </div>
                                            </div>

                                            {/* Access Level */}
                                            <div className="flex flex-wrap gap-1">
                                                {credential.accessLevel.map((level) => (
                                                    <span
                                                        key={level}
                                                        className="rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-600 dark:bg-gray-700 dark:text-gray-400"
                                                    >
                                                        {accessLevelLabels[level]}
                                                    </span>
                                                ))}
                                            </div>

                                            {/* Last Modified */}
                                            <div className="mt-3 pt-3 border-t border-gray-100 dark:border-gray-700">
                                                <p className="text-xs text-gray-400">
                                                    Son güncelleme: {new Date(credential.lastModified).toLocaleDateString("tr-TR")} - {credential.modifiedBy}
                                                </p>
                                            </div>
                                        </div>
                                    );
                                })}
                            </div>
                        </div>
                    );
                })}
            </div>

            {/* Add Modal */}
            {isModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-lg rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800 max-h-[90vh] overflow-y-auto">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">Yeni Kimlik Bilgisi</h2>
                            <button onClick={() => setIsModalOpen(false)} className="rounded-lg p-1 hover:bg-gray-100 dark:hover:bg-gray-700">
                                <X className="h-5 w-5 text-gray-500" />
                            </button>
                        </div>
                        <form onSubmit={handleAddCredential} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Sistem Adı</label>
                                <input
                                    type="text"
                                    required
                                    value={newCredential.systemName}
                                    onChange={(e) => setNewCredential({ ...newCredential, systemName: e.target.value })}
                                    placeholder="Örn: Kamera DVR Sistemi"
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Kategori</label>
                                <select
                                    value={newCredential.category}
                                    onChange={(e) => setNewCredential({ ...newCredential, category: e.target.value as CredentialCategory })}
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                >
                                    {Object.entries(categoryConfig).map(([key, config]) => (
                                        <option key={key} value={key}>{config.label}</option>
                                    ))}
                                </select>
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Kullanıcı Adı</label>
                                    <input
                                        type="text"
                                        value={newCredential.username}
                                        onChange={(e) => setNewCredential({ ...newCredential, username: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Şifre *</label>
                                    <input
                                        type="password"
                                        required
                                        value={newCredential.password}
                                        onChange={(e) => setNewCredential({ ...newCredential, password: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                    />
                                </div>
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">IP Adresi</label>
                                    <input
                                        type="text"
                                        value={newCredential.ipAddress}
                                        onChange={(e) => setNewCredential({ ...newCredential, ipAddress: e.target.value })}
                                        placeholder="192.168.1.100"
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Port</label>
                                    <input
                                        type="number"
                                        value={newCredential.port}
                                        onChange={(e) => setNewCredential({ ...newCredential, port: e.target.value })}
                                        placeholder="8080"
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                    />
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">API Key (Opsiyonel)</label>
                                <input
                                    type="text"
                                    value={newCredential.apiKey}
                                    onChange={(e) => setNewCredential({ ...newCredential, apiKey: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Notlar</label>
                                <textarea
                                    rows={2}
                                    value={newCredential.notes}
                                    onChange={(e) => setNewCredential({ ...newCredential, notes: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Erişim Yetkileri</label>
                                <div className="flex flex-wrap gap-2">
                                    {Object.entries(accessLevelLabels).map(([level, label]) => (
                                        <button
                                            key={level}
                                            type="button"
                                            onClick={() => toggleAccessLevel(level as AccessLevel)}
                                            className={`rounded-lg px-3 py-1.5 text-sm font-medium transition-colors ${newCredential.accessLevel.includes(level as AccessLevel)
                                                    ? "bg-primary text-white"
                                                    : "bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-300"
                                                }`}
                                        >
                                            {label}
                                        </button>
                                    ))}
                                </div>
                            </div>
                            <div className="flex gap-3 pt-4">
                                <button type="button" onClick={() => setIsModalOpen(false)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">
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

            {/* View Detail Modal */}
            {isViewModalOpen && selectedCredential && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">{selectedCredential.systemName}</h2>
                            <button onClick={() => setIsViewModalOpen(false)} className="rounded-lg p-1 hover:bg-gray-100 dark:hover:bg-gray-700">
                                <X className="h-5 w-5 text-gray-500" />
                            </button>
                        </div>
                        <div className="space-y-4">
                            {selectedCredential.username && (
                                <div>
                                    <label className="text-xs text-gray-500">Kullanıcı Adı</label>
                                    <p className="text-sm font-mono bg-gray-50 dark:bg-gray-700 p-2 rounded">{selectedCredential.username}</p>
                                </div>
                            )}
                            <div>
                                <label className="text-xs text-gray-500">Şifre</label>
                                <div className="flex items-center gap-2 bg-gray-50 dark:bg-gray-700 p-2 rounded">
                                    <p className="flex-1 text-sm font-mono">
                                        {visiblePasswords.has(selectedCredential.id) ? selectedCredential.password : "••••••••••"}
                                    </p>
                                    <button onClick={() => togglePasswordVisibility(selectedCredential.id)} className="p-1 hover:bg-gray-200 rounded dark:hover:bg-gray-600">
                                        {visiblePasswords.has(selectedCredential.id) ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                                    </button>
                                    <button onClick={() => copyToClipboard(selectedCredential.password, selectedCredential.id)} className="p-1 hover:bg-gray-200 rounded dark:hover:bg-gray-600">
                                        {copiedId === selectedCredential.id ? <CheckCircle className="h-4 w-4 text-green-500" /> : <Copy className="h-4 w-4" />}
                                    </button>
                                </div>
                            </div>
                            {selectedCredential.ipAddress && (
                                <div>
                                    <label className="text-xs text-gray-500">IP Adresi</label>
                                    <p className="text-sm font-mono bg-gray-50 dark:bg-gray-700 p-2 rounded">
                                        {selectedCredential.ipAddress}{selectedCredential.port ? `:${selectedCredential.port}` : ""}
                                    </p>
                                </div>
                            )}
                            {selectedCredential.notes && (
                                <div>
                                    <label className="text-xs text-gray-500">Notlar</label>
                                    <p className="text-sm bg-gray-50 dark:bg-gray-700 p-2 rounded">{selectedCredential.notes}</p>
                                </div>
                            )}
                            <div className="pt-2 border-t border-gray-200 dark:border-gray-700">
                                <p className="text-xs text-gray-400">
                                    Son güncelleme: {new Date(selectedCredential.lastModified).toLocaleString("tr-TR")}
                                </p>
                                <p className="text-xs text-gray-400">Güncelleyen: {selectedCredential.modifiedBy}</p>
                            </div>
                        </div>
                        <button
                            onClick={() => setIsViewModalOpen(false)}
                            className="w-full mt-4 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300"
                        >
                            Kapat
                        </button>
                    </div>
                </div>
            )}

            {/* Access Log Modal */}
            {isLogModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-lg rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">Erişim Geçmişi</h2>
                            <button onClick={() => setIsLogModalOpen(false)} className="rounded-lg p-1 hover:bg-gray-100 dark:hover:bg-gray-700">
                                <X className="h-5 w-5 text-gray-500" />
                            </button>
                        </div>
                        <div className="space-y-3 max-h-96 overflow-y-auto">
                            {accessLogs.map((log) => {
                                const credential = credentials.find((c) => c.id === log.credentialId);
                                return (
                                    <div key={log.id} className="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                                        <div className={`rounded-full p-2 ${log.action === "view" ? "bg-blue-100 text-blue-600" :
                                                log.action === "copy" ? "bg-green-100 text-green-600" :
                                                    "bg-yellow-100 text-yellow-600"
                                            }`}>
                                            {log.action === "view" ? <Eye className="h-4 w-4" /> :
                                                log.action === "copy" ? <Copy className="h-4 w-4" /> :
                                                    <Edit className="h-4 w-4" />}
                                        </div>
                                        <div className="flex-1">
                                            <p className="text-sm font-medium text-gray-900 dark:text-white">
                                                {log.user}
                                                <span className="font-normal text-gray-500">
                                                    {log.action === "view" ? " görüntüledi" :
                                                        log.action === "copy" ? " kopyaladı" : " düzenledi"}
                                                </span>
                                            </p>
                                            <p className="text-xs text-gray-500">{credential?.systemName}</p>
                                        </div>
                                        <p className="text-xs text-gray-400">{new Date(log.timestamp).toLocaleString("tr-TR")}</p>
                                    </div>
                                );
                            })}
                        </div>
                        <button
                            onClick={() => setIsLogModalOpen(false)}
                            className="w-full mt-4 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300"
                        >
                            Kapat
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
}
