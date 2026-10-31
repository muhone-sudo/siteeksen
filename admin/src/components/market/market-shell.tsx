"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { signOut, useSession } from "next-auth/react";
import { LogOut, Store } from "lucide-react";
import { homeFor } from "@/lib/rbac";

/**
 * Pazaryeri alanlarının iskeleti (tedarikçi paneli, platform yönetimi): yönetim panelinden ayrı, sitesiz.
 * Üstte marka, kişi ve çıkış; altında alanın sekmeleri (telefonda yatay kaydırılır).
 */
export function MarketShell({ title, nav, loginPath, children }: {
    title: string;
    nav: { href: string; label: string }[];
    loginPath: string;
    children: React.ReactNode;
}) {
    const pathname = usePathname();
    const { data: session } = useSession();
    const roles = session?.user?.roles ?? [];
    const otherHome = homeFor(roles);
    return (
        <div className="min-h-screen bg-gray-100 dark:bg-gray-900">
            <header className="border-b bg-white dark:border-gray-700 dark:bg-gray-800">
                <div className="mx-auto flex max-w-6xl items-center justify-between gap-3 px-4 py-3">
                    <div className="flex min-w-0 items-center gap-2">
                        <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-primary">
                            <Store className="h-5 w-5 text-white" />
                        </div>
                        <div className="min-w-0">
                            <p className="truncate text-sm font-semibold">Usta &amp; Hizmet</p>
                            <p className="truncate text-xs text-gray-500">{title}</p>
                        </div>
                    </div>
                    <div className="flex items-center gap-3 text-sm">
                        {otherHome === "/dashboard" && roles.length > 0 && !pathname.startsWith("/dashboard") && (
                            <Link href="/dashboard" className="hidden text-primary hover:underline sm:inline">Yönetim paneli</Link>
                        )}
                        <span className="hidden truncate text-gray-600 sm:inline">{session?.user?.name}</span>
                        <button onClick={() => void signOut({ callbackUrl: loginPath })}
                            className="flex items-center gap-1 rounded-lg border px-3 py-1.5 text-gray-700 hover:bg-gray-50 dark:text-gray-200">
                            <LogOut className="h-4 w-4" /> Çıkış
                        </button>
                    </div>
                </div>
                <nav className="mx-auto flex max-w-6xl gap-1 overflow-x-auto px-4">
                    {nav.map((n) => {
                        const active = pathname === n.href || (n.href !== nav[0].href && pathname.startsWith(n.href + "/"));
                        return (
                            <Link key={n.href} href={n.href}
                                className={`whitespace-nowrap border-b-2 px-3 py-2 text-sm ${active ? "border-primary font-medium text-primary" : "border-transparent text-gray-600 hover:text-gray-900"}`}>
                                {n.label}
                            </Link>
                        );
                    })}
                </nav>
            </header>
            <main className="mx-auto max-w-6xl p-4 sm:p-6">{children}</main>
        </div>
    );
}
