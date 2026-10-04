"use client";

import { useEffect, useState } from "react";
import { useSession } from "next-auth/react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
    LayoutDashboard, Users, Receipt, Gauge, Bell, MessageSquare, FileText, Settings, Building2,
    Calculator, BellRing, KeyRound, TrendingDown, Car, UserCog, CalendarCheck, UserCheck, MapPin, X,
    Landmark, Package, FileSignature, FolderArchive, Wrench, Boxes, Vote, ShieldCheck, Megaphone,
    Zap, AlertTriangle, Smile, Leaf,
} from "lucide-react";
import { cn } from "@/lib/utils";
import apiClient from "@/lib/api-client";
import { api } from "@/lib/api";
import { canAccess } from "@/lib/rbac";

type NavItem = { name: string; href: string; icon: React.ElementType };

/** Menü, modül gruplarına ayrılmıştır; kullanıcı yalnızca yetkili olduğu öğeleri görür. */
const sections: { title: string; items: NavItem[] }[] = [
    { title: "", items: [{ name: "Panel", href: "/dashboard", icon: LayoutDashboard }] },
    {
        title: "Sakinler ve İletişim",
        items: [
            { name: "Sakinler", href: "/dashboard/residents", icon: Users },
            { name: "Bağımsız Bölümler", href: "/dashboard/units", icon: Building2 },
            { name: "Görevlendirmeler", href: "/dashboard/roles", icon: ShieldCheck },
            { name: "KVKK Başvuruları", href: "/dashboard/kvkk", icon: FileText },
            { name: "Talepler", href: "/dashboard/requests", icon: MessageSquare },
            { name: "Duyurular", href: "/dashboard/announcements", icon: Bell },
            { name: "İlan Panosu", href: "/dashboard/bulletins", icon: Megaphone },
            { name: "Anketler", href: "/dashboard/surveys", icon: Vote },
            { name: "Bildirimler", href: "/dashboard/notifications", icon: BellRing },
        ],
    },
    {
        title: "Mali",
        items: [
            { name: "Aidat Tahakkuku", href: "/dashboard/assessments", icon: Receipt },
            { name: "Tahsilat ve Borçlar", href: "/dashboard/accounting", icon: Calculator },
            { name: "Giderler", href: "/dashboard/expenses", icon: TrendingDown },
            { name: "Sayaç ve Isı Payı", href: "/dashboard/meters", icon: Gauge },
            { name: "Tahsilat Riski", href: "/dashboard/collection", icon: AlertTriangle },
        ],
    },
    {
        title: "Yönetişim (KMK)",
        items: [
            { name: "İşletme Projesi", href: "/dashboard/governance/budgets", icon: Landmark },
            { name: "Genel Kurul", href: "/dashboard/governance/assemblies", icon: Vote },
            { name: "Defterler", href: "/dashboard/governance/books", icon: FileText },
            { name: "İcra ve Dava", href: "/dashboard/governance/legal", icon: ShieldCheck },
            { name: "Sözleşmeler", href: "/dashboard/contracts", icon: FileSignature },
            { name: "Belge Arşivi", href: "/dashboard/documents", icon: FolderArchive },
        ],
    },
    {
        title: "Operasyon",
        items: [
            { name: "Ziyaretçi", href: "/dashboard/visitors", icon: UserCheck },
            { name: "Kargo", href: "/dashboard/packages", icon: Package },
            { name: "Otopark", href: "/dashboard/parking", icon: Car },
            { name: "Rezervasyon", href: "/dashboard/reservations", icon: CalendarCheck },
            { name: "Devriye", href: "/dashboard/patrol", icon: ShieldCheck },
            { name: "Personel", href: "/dashboard/personnel", icon: UserCog },
            { name: "Demirbaş", href: "/dashboard/assets", icon: Wrench },
            { name: "Stok", href: "/dashboard/inventory", icon: Boxes },
        ],
    },
    {
        title: "Analiz",
        items: [
            { name: "Enerji", href: "/dashboard/energy", icon: Zap },
            { name: "Memnuniyet (NPS)", href: "/dashboard/nps", icon: Smile },
            { name: "Karbon Ayak İzi", href: "/dashboard/esg", icon: Leaf },
            { name: "Raporlar", href: "/dashboard/reports", icon: FileText },
        ],
    },
    { title: "Sistem", items: [{ name: "Entegrasyon Anahtarları", href: "/dashboard/credentials", icon: KeyRound }] },
];

interface SiteOption {
    id: string;
    name: string;
}

export function Sidebar() {
    const pathname = usePathname();
    const { data: session, status, update } = useSession();
    const [sites, setSites] = useState<SiteOption[]>([]);
    const [switching, setSwitching] = useState(false);
    const [switchError, setSwitchError] = useState<string | null>(null);
    const [isAddModalOpen, setIsAddModalOpen] = useState(false);
    const [creating, setCreating] = useState(false);
    const [newSite, setNewSite] = useState({ name: "", type: "SITE", address: "", city: "", district: "" });
    const activeSiteId = session?.user?.propertyId ?? null;

    useEffect(() => {
        if (status !== "authenticated") return;
        api.identity
            .properties()
            .then((properties) => {
                const unique = new Map<string, string>();
                (properties ?? []).forEach((p) => unique.set(p.property_id, p.property_name));
                setSites(Array.from(unique, ([id, name]) => ({ id, name })));
            })
            .catch(() => setSites([]));
    }, [status]);

    /**
     * Site değişimi: sunucuda aktif site değiştirilir, YENİ siteye ait jeton
     * alınır ve NextAuth oturumu bu jetonla güncellenir. Önceki sürüm yeni
     * jetonu yalnızca tarayıcı belleğine yazıyordu; sayfa yenilenince oturumdaki
     * ESKİ jeton geri geliyor ve istekler eski siteye gidiyordu.
     */
    const switchTo = async (id: string) => {
        setSwitchError(null);
        setSwitching(true);
        try {
            await api.identity.setActiveProperty(id);
            const tokens = await apiClient.refreshTokens(session!.refreshToken);
            await update({ accessToken: tokens.access_token, refreshToken: tokens.refresh_token });
            window.location.href = "/dashboard";
        } catch {
            setSwitchError("Site değiştirilemedi. Lütfen tekrar deneyin.");
            setSwitching(false);
        }
    };

    const handleCreateSite = async (e: React.FormEvent) => {
        e.preventDefault();
        if (creating) return;
        setCreating(true);
        try {
            const property = await api.identity.createProperty(newSite);
            await switchTo(property.id);
        } catch {
            setSwitchError("Site oluşturulamadı. Lütfen tekrar deneyin.");
            setCreating(false);
        }
    };

    const roles = session?.user?.roles;

    return (
        <div className="hidden lg:flex lg:w-64 lg:flex-col">
            <div className="flex flex-1 flex-col overflow-y-auto border-r border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-800">
                <div className="flex h-16 shrink-0 items-center gap-2 border-b border-gray-200 px-6 dark:border-gray-700">
                    <Building2 className="h-8 w-8 text-primary" />
                    <span className="text-xl font-bold text-primary">SiteEksen</span>
                </div>

                <div className="space-y-2 border-b border-gray-200 px-4 py-4 dark:border-gray-700">
                    <select
                        value={activeSiteId ?? ""}
                        onChange={(e) => e.target.value !== activeSiteId && void switchTo(e.target.value)}
                        disabled={switching || sites.length === 0}
                        aria-label="Aktif site"
                        className="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm disabled:opacity-60 dark:border-gray-600 dark:bg-gray-700"
                    >
                        {sites.length === 0 && <option value="">Yükleniyor...</option>}
                        {sites.map((site) => (
                            <option key={site.id} value={site.id}>
                                {site.name}
                            </option>
                        ))}
                    </select>
                    {switchError && <p className="text-xs text-red-600">{switchError}</p>}
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

                {/* RBAC: menü AKTİF SİTEDEKİ rollere göre süzülür (asıl kontrol sunucudadır). */}
                <nav className="flex-1 space-y-4 px-3 py-4">
                    {sections.map((sec) => {
                        const items = sec.items.filter((i) => canAccess(i.href, roles));
                        if (items.length === 0) return null;
                        return (
                            <div key={sec.title || "root"}>
                                {sec.title && <p className="mb-1 px-3 text-xs font-semibold uppercase tracking-wide text-gray-400">{sec.title}</p>}
                                <div className="space-y-0.5">
                                    {items.map((item) => {
                                        const active = item.href === "/dashboard" ? pathname === item.href : pathname.startsWith(item.href);
                                        return (
                                            <Link
                                                key={item.href}
                                                href={item.href}
                                                className={cn(
                                                    "flex items-center gap-3 rounded-lg px-3 py-1.5 text-sm font-medium transition-colors",
                                                    active ? "bg-primary text-white" : "text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-700"
                                                )}
                                            >
                                                <item.icon className="h-4 w-4" />
                                                {item.name}
                                            </Link>
                                        );
                                    })}
                                </div>
                            </div>
                        );
                    })}
                </nav>

                <div className="border-t border-gray-200 p-4 dark:border-gray-700">
                    {canAccess("/dashboard/settings", roles) && (
                        <Link
                            href="/dashboard/settings"
                            className="flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-700"
                        >
                            <Settings className="h-5 w-5" />
                            Ayarlar
                        </Link>
                    )}
                </div>
            </div>

            {isAddModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800">
                        <div className="mb-4 flex items-center justify-between">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">Yeni Taşınmaz Ekle</h2>
                            <button onClick={() => setIsAddModalOpen(false)} className="rounded-lg p-1 hover:bg-gray-100 dark:hover:bg-gray-700">
                                <X className="h-5 w-5 text-gray-500" />
                            </button>
                        </div>
                        <form onSubmit={handleCreateSite} className="space-y-4">
                            {[
                                { k: "name", label: "Ad", ph: "Güneş Sitesi", req: true },
                                { k: "address", label: "Adres", ph: "Atatürk Cad. No:1", req: true },
                                { k: "city", label: "Şehir", ph: "İstanbul", req: true },
                                { k: "district", label: "İlçe", ph: "Kadıköy", req: false },
                            ].map((f) => (
                                <div key={f.k}>
                                    <label className="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300">{f.label}</label>
                                    <div className="relative">
                                        {f.k === "address" && <MapPin className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />}
                                        <input
                                            type="text"
                                            required={f.req}
                                            value={(newSite as Record<string, string>)[f.k]}
                                            onChange={(e) => setNewSite({ ...newSite, [f.k]: e.target.value })}
                                            placeholder={f.ph}
                                            className={cn(
                                                "w-full rounded-lg border border-gray-300 bg-white py-2 pr-4 text-sm dark:border-gray-600 dark:bg-gray-700",
                                                f.k === "address" ? "pl-10" : "pl-3"
                                            )}
                                        />
                                    </div>
                                </div>
                            ))}
                            <div>
                                <label className="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300">Tür</label>
                                <select
                                    value={newSite.type}
                                    onChange={(e) => setNewSite({ ...newSite, type: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                >
                                    <option value="SITE">Site</option>
                                    <option value="APARTMENT">Apartman</option>
                                    <option value="BUILDING">Bina</option>
                                </select>
                            </div>
                            <div className="flex gap-3 pt-4">
                                <button type="button" onClick={() => setIsAddModalOpen(false)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">
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
