"use client";

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
} from "lucide-react";
import { cn } from "@/lib/utils";

const navigation = [
    { name: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
    { name: "Sakinler", href: "/dashboard/residents", icon: Users },
    { name: "Aidatlar", href: "/dashboard/assessments", icon: Receipt },
    { name: "Sayaç Okuma", href: "/dashboard/meters", icon: Gauge },
    { name: "Duyurular", href: "/dashboard/announcements", icon: Bell },
    { name: "Talepler", href: "/dashboard/requests", icon: MessageSquare },
    { name: "Raporlar", href: "/dashboard/reports", icon: FileText },
];

export function Sidebar() {
    const pathname = usePathname();

    return (
        <div className="hidden lg:flex lg:w-64 lg:flex-col">
            <div className="flex flex-1 flex-col bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700">
                {/* Logo */}
                <div className="flex h-16 items-center gap-2 px-6 border-b border-gray-200 dark:border-gray-700">
                    <Building2 className="h-8 w-8 text-primary" />
                    <span className="text-xl font-bold text-primary">SiteEksen</span>
                </div>

                {/* Site Seçici */}
                <div className="px-4 py-4 border-b border-gray-200 dark:border-gray-700">
                    <select className="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm dark:bg-gray-700 dark:border-gray-600">
                        <option>Güneş Sitesi</option>
                        <option>Yıldız Apartmanı</option>
                        <option>+ Yeni Site Ekle</option>
                    </select>
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
