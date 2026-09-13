import { NextResponse } from "next/server";
import { getToken } from "next-auth/jwt";
import type { NextRequest } from "next/server";
import { canAccess, requiredRolesFor } from "@/lib/rbac";

/**
 * Kimlik ve yetki kapısı.
 *
 * GÜVENLİK (2026-09-13, todo 0.A.10): Önceki sürüm yalnızca "giriş yapılmış mı?"
 * sorusunu soruyordu. Giriş yapan HERKES adres çubuğuna `/dashboard/personnel`
 * ya da `/dashboard/credentials` yazarak maaş bordrosuna ve sistem API
 * anahtarlarına erişebiliyordu. Artık yol bazlı rol kontrolü de yapılır.
 *
 * NOT: Bu kontrol bir güvenlik SINIRI değildir — asıl yetki denetimi sunucudadır
 * (`pkg/middleware.RequireRole`). Burada amaç, kullanıcıyı erişemeyeceği ekrana
 * hiç götürmemek ve yanlışlıkla veri sızdıran bir istemci isteği tetiklememektir.
 */
export async function middleware(request: NextRequest) {
    const token = await getToken({ req: request });
    const { pathname } = request.nextUrl;
    const isAuthPage = pathname.startsWith("/login");
    const isDashboardPage = pathname.startsWith("/dashboard");

    if (isAuthPage && token) {
        return NextResponse.redirect(new URL("/dashboard", request.url));
    }

    if (isDashboardPage && !token) {
        return NextResponse.redirect(new URL("/login", request.url));
    }

    if (isDashboardPage && token) {
        const roles = (token as { roles?: string[] }).roles;
        if (!canAccess(pathname, roles)) {
            const rule = requiredRolesFor(pathname);
            const url = new URL("/dashboard/forbidden", request.url);
            url.searchParams.set("from", pathname);
            if (rule) url.searchParams.set("reason", rule.reason);
            return NextResponse.redirect(url);
        }
    }

    return NextResponse.next();
}

export const config = {
    matcher: ["/dashboard/:path*", "/login"],
};
