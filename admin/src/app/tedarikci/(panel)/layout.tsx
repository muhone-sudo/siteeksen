import { MarketShell } from "@/components/market/market-shell";

/** Tedarikçi paneli sekmeleri; her aşamada gerçek ekranı olanlar eklenir (FAZ M). */
const SUPPLIER_NAV = [
    { href: "/tedarikci", label: "Hesabım" },
    { href: "/tedarikci/isletmeler", label: "İşletmelerim" },
    { href: "/tedarikci/bakiye", label: "Bakiye ve paket" },
    { href: "/tedarikci/bildirimler", label: "Bildirimler" },
];

export default function SupplierLayout({ children }: { children: React.ReactNode }) {
    return (
        <MarketShell title="Tedarikçi paneli" nav={SUPPLIER_NAV} loginPath="/tedarikci/giris">
            {children}
        </MarketShell>
    );
}
