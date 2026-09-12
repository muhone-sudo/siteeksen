import NextAuth from "next-auth";
import type { NextAuthOptions } from "next-auth";
import CredentialsProvider from "next-auth/providers/credentials";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api/v1";
const SERVER_API_URL = process.env.API_URL || API_URL;

/**
 * Telefon numarasını log için maskeler (KVKK: kişisel veri log'a düz metin yazılmaz).
 * Örn: "+905551234567" -> "+9055*****67"
 */
function maskPhone(phone: string): string {
    if (phone.length <= 6) return "***";
    return `${phone.slice(0, 5)}*****${phone.slice(-2)}`;
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

                    return {
                        id: data.user.id,
                        name: `${data.user.first_name} ${data.user.last_name}`,
                        email: data.user.email,
                        phone: data.user.phone,
                        roles: data.user.roles,
                        accessToken: data.access_token,
                        refreshToken: data.refresh_token,
                        propertyId: data.user.active_property_id,
                    };
                } catch (error) {
                    console.error("Auth error:", error);
                    return null;
                }
            },
        }),
    ],
    callbacks: {
        async jwt({ token, user }) {
            if (user) {
                token.accessToken = (user as any).accessToken;
                token.refreshToken = (user as any).refreshToken;
                token.roles = (user as any).roles;
                token.propertyId = (user as any).propertyId;
                token.phone = (user as any).phone;
            }
            return token;
        },
        async session({ session, token }) {
            session.accessToken = token.accessToken as string;
            session.refreshToken = token.refreshToken as string;
            session.user.id = token.sub as string;
            session.user.roles = token.roles as string[];
            session.user.propertyId = token.propertyId as string;
            session.user.phone = token.phone as string;
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
