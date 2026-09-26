"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { signOut, useSession } from "next-auth/react";
import { Bell, ChevronDown, LogOut, Menu, User } from "lucide-react";
import apiClient from "@/lib/api-client";

/**
 * Üst çubuk.
 *
 * 2026-09-09 düzeltmeleri (denetim bulguları):
 *  - Kullanıcı adı ve unvanı "Ahmet Yılmaz / Yönetim Kurulu Başkanı" olarak KODA GÖMÜLÜYDÜ;
 *    kim giriş yaparsa yapsın bu isim görünüyordu. Artık oturumdan okunuyor.
 *  - Panelde ÇIKIŞ (logout) düğmesi hiç yoktu — kullanıcı oturumunu kapatamıyordu.
 *  - Bildirim zilinde her zaman kırmızı "okunmamış" noktası vardı ve düğmenin hiçbir
 *    işlevi yoktu; sahte gösterge kaldırıldı, düğme bildirimler sayfasına yönlendiriyor.
 *  - Arama kutusu hiçbir şeye bağlı değildi (onChange yok, global arama özelliği yok);
 *    çalışmayan bir arayüz öğesi bırakmak yerine kaldırıldı.
 */

const ROLE_LABELS: Record<string, string> = {
    MANAGER: "Site Yöneticisi",
    OWNER: "Malik",
    TENANT: "Kiracı",
    RESIDENT: "Sakin",
    AUDITOR: "Denetçi",
    STAFF: "Personel",
};

function roleLabel(roles?: string[]): string {
    if (!roles || roles.length === 0) return "";
    // Yetki sırasına göre en üst rolü göster
    const order = ["MANAGER", "AUDITOR", "STAFF", "OWNER", "TENANT", "RESIDENT"];
    const top = order.find((r) => roles.includes(r));
    return top ? ROLE_LABELS[top] : roles[0];
}

export function Header() {
    const { data: session, status } = useSession();
    const router = useRouter();
    const [menuOpen, setMenuOpen] = useState(false);
    const [signingOut, setSigningOut] = useState(false);

    const displayName = session?.user?.name?.trim() || session?.user?.phone || "Kullanıcı";
    const displayRole = roleLabel(session?.user?.roles);

    async function handleSignOut() {
        setSigningOut(true);
        // Önce SUNUCUDA oturum kapatılır (erişim + yenileme jetonu iptal edilir).
        // Önceki sürüm yalnızca tarayıcıdaki NextAuth oturumunu siliyordu; jeton
        // sunucuda geçerli kalıyor, yenileme jetonu 7 gün boyunca yeni oturum
        // açabiliyordu. İptal başarısız olursa kullanıcıya SÖYLENİR.
        let revoked = false;
        try {
            if (session?.accessToken) {
                apiClient.setToken(session.accessToken);
                const res = await apiClient.logout(session.refreshToken);
                revoked = !!res?.access_token_revoked && (!session.refreshToken || !!res?.refresh_token_revoked);
            }
        } catch {
            revoked = false;
        }
        if (!revoked && session?.accessToken) {
            window.alert(
                "Bu cihazdaki oturum kapatılıyor, ancak sunucudaki oturum iptal edilemedi. " +
                "Başka bir cihazda açık oturumunuz varsa güvenlik için şifrenizi değiştirin."
            );
        }
        await signOut({ callbackUrl: "/login" });
    }

    return (
        <header className="flex h-16 items-center justify-between border-b border-gray-200 bg-white px-6 dark:border-gray-700 dark:bg-gray-800">
            {/* Mobile menu button */}
            <button className="lg:hidden" aria-label="Menü">
                <Menu className="h-6 w-6" />
            </button>

            <div className="flex-1" />

            {/* Right side */}
            <div className="flex items-center gap-4">
                <button
                    onClick={() => router.push("/dashboard/notifications")}
                    className="rounded-lg p-2 hover:bg-gray-100 dark:hover:bg-gray-700"
                    title="Bildirim yönetimi"
                    aria-label="Bildirim yönetimi"
                >
                    <Bell className="h-5 w-5 text-gray-600 dark:text-gray-300" />
                </button>

                {/* Profile + logout */}
                <div className="relative">
                    <button
                        onClick={() => setMenuOpen((v) => !v)}
                        className="flex items-center gap-3 rounded-lg p-1 hover:bg-gray-100 dark:hover:bg-gray-700"
                        aria-haspopup="menu"
                        aria-expanded={menuOpen}
                    >
                        <div className="hidden text-right sm:block">
                            <p className="text-sm font-medium text-gray-900 dark:text-white">
                                {status === "loading" ? "…" : displayName}
                            </p>
                            {displayRole && (
                                <p className="text-xs text-gray-500 dark:text-gray-400">{displayRole}</p>
                            )}
                        </div>
                        <span className="flex h-10 w-10 items-center justify-center rounded-full bg-primary text-white">
                            <User className="h-5 w-5" />
                        </span>
                        <ChevronDown className="h-4 w-4 text-gray-400" />
                    </button>

                    {menuOpen && (
                        <>
                            {/* Dışarı tıklayınca kapat */}
                            <div
                                className="fixed inset-0 z-40"
                                onClick={() => setMenuOpen(false)}
                                aria-hidden="true"
                            />
                            <div
                                role="menu"
                                className="absolute right-0 z-50 mt-2 w-56 rounded-lg border border-gray-200 bg-white py-1 shadow-lg dark:border-gray-700 dark:bg-gray-800"
                            >
                                <div className="border-b border-gray-100 px-4 py-2 dark:border-gray-700">
                                    <p className="truncate text-sm font-medium text-gray-900 dark:text-white">
                                        {displayName}
                                    </p>
                                    {session?.user?.phone && (
                                        <p className="truncate text-xs text-gray-500">{session.user.phone}</p>
                                    )}
                                </div>
                                <button
                                    role="menuitem"
                                    onClick={handleSignOut}
                                    disabled={signingOut}
                                    className="flex w-full items-center gap-2 px-4 py-2 text-left text-sm text-red-600 hover:bg-red-50 disabled:opacity-50 dark:hover:bg-red-900/20"
                                >
                                    <LogOut className="h-4 w-4" />
                                    {signingOut ? "Çıkış yapılıyor…" : "Çıkış Yap"}
                                </button>
                            </div>
                        </>
                    )}
                </div>
            </div>
        </header>
    );
}
