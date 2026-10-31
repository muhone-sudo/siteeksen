import { NextResponse } from "next/server";
import { getToken } from "next-auth/jwt";
import type { NextRequest } from "next/server";
import { areaFor, canAccess, homeFor, requiredRolesFor } from "@/lib/rbac";

/**
 * Kimlik ve yetki kapısı.
 *
 * GÜVENLİK (2026-09-13, todo 0.A.10): Önceki sürüm yalnızca "giriş yapılmış mı?"
 * sorusunu soruyordu. Giriş yapan HERKES adres çubuğuna `/dashboard/personnel`
 * ya da `/dashboard/integrations` yazarak maaş bordrosuna ve sistem API
 * anahtarlarına erişebiliyordu. Artık yol bazlı rol kontrolü de yapılır.
 *
 * NOT: Bu kontrol bir güvenlik SINIRI değildir — asıl yetki denetimi sunucudadır
 * (`pkg/middleware.RequireRole`). Burada amaç, kullanıcıyı erişemeyeceği ekrana
 * hiç götürmemek ve yanlışlıkla veri sızdıran bir istemci isteği tetiklememektir.
 */

/**
 * Yönlendirme döngüsü koruması.
 *
 * Hedef yol ile bulunulan yol aynıysa yönlendirme YAPILMAZ; istek olduğu gibi
 * geçirilir. Böyle bir yönlendirme tarayıcıda ERR_TOO_MANY_REDIRECTS ile
 * sonuçlanır ve kullanıcı hiçbir sayfayı göremez — hatanın kendisinden daha
 * kötü bir sonuçtur.
 */
function safeRedirect(request: NextRequest, target: URL): NextResponse {
    if (target.pathname === request.nextUrl.pathname) {
        return NextResponse.next();
    }
    return NextResponse.redirect(target);
}

export async function middleware(request: NextRequest) {
    const token = await getToken({ req: request });
    const { pathname } = request.nextUrl;
    const isAuthPage = pathname.startsWith("/login");
    const isDashboardPage = pathname.startsWith("/dashboard");

    const roles = token ? (token as { roles?: string[] }).roles : undefined;
    const area = areaFor(pathname);

    if (isAuthPage && token) {
        return safeRedirect(request, new URL(homeFor(roles), request.url));
    }

    // Pazaryeri alanları (FAZ M): giriş/kayıt herkese açık; oturum varsa alanın ana sayfasına gider.
    if (area) {
        const isPublic = area.publicPaths.includes(pathname);
        if (isPublic) {
            return token && area.roles.some((r) => roles?.includes(r))
                ? safeRedirect(request, new URL(area.prefix, request.url))
                : NextResponse.next();
        }
        if (!token) {
            return safeRedirect(request, new URL(area.login, request.url));
        }
        if (!area.roles.some((r) => roles?.includes(r))) {
            const url = new URL("/dashboard/forbidden", request.url);
            url.searchParams.set("from", pathname);
            url.searchParams.set("reason", area.reason);
            return safeRedirect(request, url);
        }
        return NextResponse.next();
    }

    if (isDashboardPage && !token) {
        return safeRedirect(request, new URL("/login", request.url));
    }

    if (isDashboardPage && token) {
        // Yalnız tedarikçi ya da platform yöneticisi olan kişi yönetim paneli yerine kendi alanına gider.
        const home = homeFor(roles);
        if (home !== "/dashboard" && !pathname.startsWith("/dashboard/forbidden")) {
            return safeRedirect(request, new URL(home, request.url));
        }
        if (!canAccess(pathname, roles)) {
            const rule = requiredRolesFor(pathname);
            const url = new URL("/dashboard/forbidden", request.url);
            url.searchParams.set("from", pathname);
            if (rule) url.searchParams.set("reason", rule.reason);
            return safeRedirect(request, url);
        }
    }

    return NextResponse.next();
}

export const config = {
    matcher: ["/dashboard/:path*", "/login", "/tedarikci/:path*", "/tedarikci", "/platform/:path*", "/platform"],
};
