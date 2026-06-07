"use client";

import { useEffect, useState } from "react";
import { useSession } from "next-auth/react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
    LayoutDashboard,
    Users,
    Receipt,
    Gauge,
    Bell,
    MessageSquare,
    FileText,
    Settings,
    Building2,
    Calculator,
    BellRing,
    KeyRound,
    TrendingDown,
    Car,
    UserCog,
    CalendarCheck,
    UserCheck,
    MapPin,
    X,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { apiClient } from "@/lib/api-client";

const navigation = [
    { name: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
    { name: "Sakinler", href: "/dashboard/residents", icon: Users },
    { name: "Muhasebe", href: "/dashboard/accounting", icon: Calculator },
    { name: "Gider Yönetimi", href: "/dashboard/expenses", icon: TrendingDown },
    { name: "Aidatlar", href: "/dashboard/assessments", icon: Receipt },
    { name: "Sayaç Okuma", href: "/dashboard/meters", icon: Gauge },
    { name: "Duyurular", href: "/dashboard/announcements", icon: Bell },
    { name: "Bildirimler", href: "/dashboard/notifications", icon: BellRing },
    { name: "Talepler", href: "/dashboard/requests", icon: MessageSquare },
    { name: "Otopark", href: "/dashboard/parking", icon: Car },
    { name: "Personel", href: "/dashboard/personnel", icon: UserCog },
    { name: "Rezervasyon", href: "/dashboard/reservations", icon: CalendarCheck },
    { name: "Ziyaretçi", href: "/dashboard/visitors", icon: UserCheck },
    { name: "Raporlar", href: "/dashboard/reports", icon: FileText },
    { name: "Sistem Şifreleri", href: "/dashboard/credentials", icon: KeyRound },
];


interface SiteOption {
    id: string;
    name: string;
}

export function Sidebar() {
    const pathname = usePathname();
    const { data: session, status } = useSession();
    const [sites, setSites] = useState<SiteOption[]>([]);
    const [activeSiteId, setActiveSiteId] = useState<string | null>(null);
    const [switching, setSwitching] = useState(false);
    const [isAddModalOpen, setIsAddModalOpen] = useState(false);
    const [creating, setCreating] = useState(false);
    const [newSite, setNewSite] = useState({ name: "", type: "SITE", address: "", city: "", district: "" });

    useEffect(() => {
        if (status !== "authenticated" || !session?.accessToken) return;

        apiClient.setToken(session.accessToken, session.refreshToken);
        setActiveSiteId(apiClient.getActivePropertyId());

        apiClient.getUserProperties()
            .then((properties) => {
                const unique = new Map<string, string>();
                properties.forEach((p) => unique.set(p.property_id, p.property_name));
                setSites(Array.from(unique, ([id, name]) => ({ id, name })));
            })
            .catch(() => setSites([]));
    }, [status, session]);

    const handleSiteChange = async (e: React.ChangeEvent<HTMLSelectElement>) => {
        const id = e.target.value;
        if (id === activeSiteId || switching) return;

        setSwitching(true);
        try {
            await apiClient.setActiveProperty(id);
            await apiClient.refreshAccessToken();
            window.location.reload();
        } catch {
            alert("Site değiştirilemedi. Lütfen tekrar deneyin.");
            setSwitching(false);
        }
    };

    const handleCreateSite = async (e: React.FormEvent) => {
        e.preventDefault();
        if (creating) return;

        setCreating(true);
        try {
            const property = await apiClient.createProperty(newSite);
            await apiClient.setActiveProperty(property.id);
            await apiClient.refreshAccessToken();
            window.location.reload();
        } catch {
            alert("Site oluşturulamadı. Lütfen tekrar deneyin.");
            setCreating(false);
        }
    };

    return (
        <div className="hidden lg:flex lg:w-64 lg:flex-col">
            <div className="flex flex-1 flex-col bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700">
                {/* Logo */}
                <div className="flex h-16 items-center gap-2 px-6 border-b border-gray-200 dark:border-gray-700">
                    <Building2 className="h-8 w-8 text-primary" />
                    <span className="text-xl font-bold text-primary">SiteEksen</span>
                </div>

                {/* Site Seçici */}
                <div className="px-4 py-4 border-b border-gray-200 dark:border-gray-700 space-y-2">
                    <select
                        value={activeSiteId ?? ""}
                        onChange={handleSiteChange}
                        disabled={switching || sites.length === 0}
                        className="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm dark:bg-gray-700 dark:border-gray-600 disabled:opacity-60"
                    >
                        {sites.length === 0 && <option value="">Yükleniyor...</option>}
                        {sites.map((site) => (
                            <option key={site.id} value={site.id}>{site.name}</option>
                        ))}
                    </select>
                    <button
                        type="button"
                        onClick={() => {
                            setNewSite({ name: "", type: "SITE", address: "", city: "", district: "" });
                            setIsAddModalOpen(true);
                        }}
                        className="text-xs text-primary hover:underline"
                    >
                        + Yeni Taşınmaz Ekle
                    </button>
                </div>

                {/* Navigation */}
                <nav className="flex-1 space-y-1 px-3 py-4">
                    {navigation.map((item) => {
                        const isActive = pathname === item.href;
                        return (
                            <Link
                                key={item.name}
                                href={item.href}
                                className={cn(
                                    "flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors",
                                    isActive
                                        ? "bg-primary text-white"
                                        : "text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-700"
                                )}
                            >
                                <item.icon className="h-5 w-5" />
                                {item.name}
                            </Link>
                        );
                    })}
                </nav>

                {/* Settings */}
                <div className="border-t border-gray-200 dark:border-gray-700 p-4">
                    <Link
                        href="/dashboard/settings"
                        className="flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-700"
                    >
                        <Settings className="h-5 w-5" />
                        Ayarlar
                    </Link>
                </div>
            </div>

            {/* Yeni Site Ekle Modal */}
            {isAddModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">Yeni Taşınmaz Ekle</h2>
                            <button onClick={() => setIsAddModalOpen(false)} className="rounded-lg p-1 hover:bg-gray-100 dark:hover:bg-gray-700">
                                <X className="h-5 w-5 text-gray-500" />
                            </button>
                        </div>
                        <form onSubmit={handleCreateSite} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Ad</label>
                                <div className="relative">
                                    <Building2 className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                                    <input type="text" required value={newSite.name} onChange={(e) => setNewSite({ ...newSite, name: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 bg-white py-2 pl-10 pr-4 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                                        placeholder="Güneş Sitesi" />
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Tür</label>
                                <select value={newSite.type} onChange={(e) => setNewSite({ ...newSite, type: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700">
                                    <option value="SITE">Site</option>
                                    <option value="APARTMENT">Apartman</option>
                                    <option value="BUILDING">Bina</option>
                                </select>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Adres</label>
                                <div className="relative">
                                    <MapPin className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                                    <input type="text" required value={newSite.address} onChange={(e) => setNewSite({ ...newSite, address: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 bg-white py-2 pl-10 pr-4 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                                        placeholder="Atatürk Cad. No:1" />
                                </div>
                            </div>
                            <div className="grid grid-cols-2 gap-3">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Şehir</label>
                                    <input type="text" required value={newSite.city} onChange={(e) => setNewSite({ ...newSite, city: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                                        placeholder="İstanbul" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">İlçe</label>
                                    <input type="text" value={newSite.district} onChange={(e) => setNewSite({ ...newSite, district: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                                        placeholder="Kadıköy" />
                                </div>
                            </div>
                            <div className="flex gap-3 pt-4">
                                <button type="button" onClick={() => setIsAddModalOpen(false)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700">
                                    İptal
                                </button>
                                <button type="submit" disabled={creating} className="flex-1 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90 disabled:opacity-60">
                                    {creating ? "Oluşturuluyor..." : "Oluştur ve Geç"}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
