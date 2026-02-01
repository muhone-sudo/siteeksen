import { NextResponse } from "next/server";
import { getToken } from "next-auth/jwt";
import type { NextRequest } from "next/server";

export async function middleware(request: NextRequest) {
    const token = await getToken({ req: request });
    const isAuthPage = request.nextUrl.pathname.startsWith("/login");
    const isDashboardPage = request.nextUrl.pathname.startsWith("/dashboard");

    // Giriş yapmış kullanıcı login sayfasına erişmeye çalışıyorsa dashboard'a yönlendir
    if (isAuthPage && token) {
        return NextResponse.redirect(new URL("/dashboard", request.url));
    }

    // Giriş yapmamış kullanıcı dashboard'a erişmeye çalışıyorsa login'e yönlendir
    if (isDashboardPage && !token) {
        return NextResponse.redirect(new URL("/login", request.url));
    }

    return NextResponse.next();
}

export const config = {
    matcher: ["/dashboard/:path*", "/login"],
};
