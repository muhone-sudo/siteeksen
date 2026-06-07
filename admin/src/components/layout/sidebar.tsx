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
                        onClick={() => alert("Yeni site ekleme özelliği yakında eklenecek.")}
                        className="text-xs text-primary hover:underline"
                    >
                        + Yeni Site Ekle
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
        </div>
    );
}
