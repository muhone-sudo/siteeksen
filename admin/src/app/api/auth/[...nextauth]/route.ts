import NextAuth from "next-auth";
import type { NextAuthOptions } from "next-auth";
import CredentialsProvider from "next-auth/providers/credentials";
import type { JWT } from "next-auth/jwt";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8888/api/v1";
const SERVER_API_URL = process.env.API_URL || API_URL;

/**
 * Telefon numarasını log için maskeler (KVKK: kişisel veri log'a düz metin yazılmaz).
 * Örn: "+905551234567" -> "+9055*****67"
 */
function maskPhone(phone: string): string {
    if (phone.length <= 6) return "***";
    return `${phone.slice(0, 5)}*****${phone.slice(-2)}`;
}

/**
 * Sunucudan gelen rol listesini oturuma yazılabilir hale getirir.
 *
 * Roller `lib/rbac.ts` içinde BÜYÜK HARFLE tanımlıdır (`MANAGER`, `AUDITOR`…);
 * karşılaştırma birebir eşitlikle yapılır. Bu yüzden gelen değer burada tek bir
 * biçime indirgenir — aksi halde yalnızca harf büyüklüğü yüzünden yetkili bir
 * kullanıcı yetkisiz sayılabilir.
 *
 * Alan hiç gelmezse boş dizi döner: rol bilinmiyorsa erişim kapalıdır
 * (fail-closed), `undefined` ile sessizce devam edilmez.
 */
function normalizeRoles(value: unknown): string[] {
    if (!Array.isArray(value)) return [];
    return value
        .filter((role): role is string => typeof role === "string")
        .map((role) => role.trim().toUpperCase())
        .filter((role) => role.length > 0);
}

/** Erişim jetonunun gövdesini okur (imza doğrulaması sunucudadır; burada yalnızca görüntü). */
function decodeClaims(accessToken: string): { exp?: number; roles?: unknown; property_id?: string } {
    try {
        const part = accessToken.split(".")[1].replace(/-/g, "+").replace(/_/g, "/");
        return JSON.parse(Buffer.from(part, "base64").toString("utf8"));
    } catch {
        return {};
    }
}

/** Roller ve aktif site HER ZAMAN jetonun kendisinden alınır — iki kopya ayrışmasın. */
function applyClaims(token: JWT, accessToken: string) {
    const c = decodeClaims(accessToken);
    token.accessExpires = typeof c.exp === "number" ? c.exp * 1000 : 0;
    token.roles = normalizeRoles(c.roles);
    token.propertyId = c.property_id ?? "";
}

async function refreshAccessToken(token: JWT): Promise<JWT> {
    try {
        const res = await fetch(`${SERVER_API_URL}/auth/refresh`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ refresh_token: token.refreshToken }),
        });
        if (!res.ok) {
            console.warn(`[auth] jeton yenilenemedi (HTTP ${res.status}); oturum kapatılacak`);
            return { ...token, error: "RefreshFailed" };
        }
        const data = await res.json();
        const next: JWT = { ...token, accessToken: data.access_token, refreshToken: data.refresh_token ?? token.refreshToken };
        applyClaims(next, data.access_token);
        delete next.error;
        return next;
    } catch (e) {
        console.error("[auth] jeton yenileme hatası:", e);
        return { ...token, error: "RefreshFailed" };
    }
}

const authOptions: NextAuthOptions = {
    providers: [
        CredentialsProvider({
            name: "Credentials",
            credentials: {
                phone: { label: "Telefon", type: "text", placeholder: "+905551234567" },
                password: { label: "Şifre", type: "password" },
            },
            async authorize(credentials) {
                // KVKK: Kimlik bilgileri (telefon, şifre) HİÇBİR koşulda log'a yazılmaz.
                // Önceki sürüm `console.log("...", credentials)` ile şifreyi düz metin olarak
                // sunucu log'una yazıyordu. Hata ayıklama gerekiyorsa yalnızca maskelenmiş
                // telefon ve HTTP durum kodu loglanır.
                if (!credentials?.phone || !credentials?.password) {
                    return null;
                }

                try {
                    const response = await fetch(`${SERVER_API_URL}/auth/login`, {
                        method: "POST",
                        headers: { "Content-Type": "application/json" },
                        body: JSON.stringify({
                            phone: credentials.phone,
                            password: credentials.password,
                        }),
                    });

                    if (!response.ok) {
                        console.warn(
                            `[auth] Giriş başarısız (HTTP ${response.status}) — telefon: ${maskPhone(credentials.phone)}`
                        );
                        return null;
                    }

                    const data = await response.json();
                    const roles = normalizeRoles(data.user?.roles);

                    // Rolsüz oturum, panelde hiçbir sayfayı açamaz. Bu sessizce
                    // "yetkiniz yok" ekranına dönüşmesin diye sunucu log'una
                    // düşürülür (kişisel veri yazılmaz).
                    if (roles.length === 0) {
                        console.warn(
                            `[auth] Giriş başarılı ama sunucu rol döndürmedi — telefon: ${maskPhone(credentials.phone)}. ` +
                                "Kullanıcının aktif sitesinde tanımlı rolü olmayabilir."
                        );
                    }

                    return {
                        id: data.user.id,
                        name: `${data.user.first_name} ${data.user.last_name}`,
                        email: data.user.email,
                        phone: data.user.phone,
                        roles,
                        accessToken: data.access_token,
                        refreshToken: data.refresh_token,
                        propertyId: data.user.active_property_id ?? "",
                    };
                } catch (error) {
                    console.error("Auth error:", error);
                    return null;
                }
            },
        }),
    ],
    callbacks: {
        /**
         * Oturum jetonu — tek doğruluk kaynağı.
         *
         * DÜZELTME (2026-09-26): önceki sürüm giriş anındaki erişim jetonunu 7 gün
         * boyunca olduğu gibi saklıyordu. Erişim jetonu 15 dakikada dolduğu için
         * panel ya sürekli 401 alıyor ya da istemcide ayrı bir kopya tutuluyordu;
         * site değiştirildiğinde roller ve aktif site ESKİ kalıyordu.
         *
         *   - Giriş: jetonlar ve jetondaki roller/site yazılır.
         *   - `update` (site değişimi): istemcinin aldığı yeni jeton çifti yazılır,
         *     roller ve site YENİ jetondan okunur.
         *   - Süresi dolmak üzereyse: sunucu tarafında yenilenir. Yenilenemezse
         *     `error` işaretlenir ve istemci oturumu kapatır — geçersiz jetonla
         *     çalışmaya devam edilmez.
         */
        async jwt({ token, user, trigger, session }) {
            if (user) {
                token.accessToken = (user as any).accessToken;
                token.refreshToken = (user as any).refreshToken;
                token.phone = (user as any).phone;
                applyClaims(token, token.accessToken as string);
                token.roles = normalizeRoles((user as any).roles);
                delete token.error;
                return token;
            }
            if (trigger === "update" && session?.accessToken) {
                token.accessToken = session.accessToken;
                if (session.refreshToken) token.refreshToken = session.refreshToken;
                applyClaims(token, session.accessToken);
                delete token.error;
                return token;
            }
            const exp = typeof token.accessExpires === "number" ? token.accessExpires : 0;
            if (exp && Date.now() < exp - 60_000) {
                return token;
            }
            return refreshAccessToken(token);
        },
        async session({ session, token }) {
            session.accessToken = token.accessToken as string;
            session.refreshToken = token.refreshToken as string;
            session.user.id = token.sub as string;
            // Eski (rolsüz) jetonlarla açılmış oturumlar için de dizi garantisi.
            session.user.roles = normalizeRoles(token.roles);
            session.user.propertyId = token.propertyId as string;
            session.user.phone = token.phone as string;
            if (token.error) session.error = token.error as string;
            return session;
        },
    },
    pages: {
        signIn: "/login",
        error: "/login",
    },
    session: {
        strategy: "jwt",
        maxAge: 7 * 24 * 60 * 60, // 7 days
    },
    secret: process.env.NEXTAUTH_SECRET,
};

const handler = NextAuth(authOptions);

export { handler as GET, handler as POST };
