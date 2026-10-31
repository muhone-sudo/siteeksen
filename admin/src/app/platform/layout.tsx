import { MarketShell } from "@/components/market/market-shell";

/** Platform yönetimi sekmeleri; her aşamada gerçek ekranı olanlar eklenir (FAZ M). */
const PLATFORM_NAV = [
    { href: "/platform", label: "Özet" },
    { href: "/platform/hesaplar", label: "Tedarikçi hesapları" },
    { href: "/platform/isletmeler", label: "İşletme onayı" },
    { href: "/platform/kategoriler", label: "Kategoriler" },
    { href: "/platform/paketler", label: "Paketler" },
    { href: "/platform/ayarlar", label: "Ayarlar" },
];

export default function PlatformLayout({ children }: { children: React.ReactNode }) {
    return (
        <MarketShell title="Platform yönetimi" nav={PLATFORM_NAV} loginPath="/login">
            {children}
        </MarketShell>
    );
}
