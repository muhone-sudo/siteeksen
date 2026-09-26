"use client";

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { SessionProvider, signOut, useSession } from "next-auth/react";
import { useEffect, useState } from "react";
import apiClient from "@/lib/api-client";

/**
 * Oturumdaki erişim jetonunu API istemcisine aktarır — TEK yerden.
 *
 * Önceden her sayfa ve kenar çubuğu jetonu ayrı ayrı yazıyordu; sıra yarışında
 * sayfa isteği jeton yazılmadan gidiyor ve kullanıcı giriş ekranına
 * atılıyordu. Jeton render sırasında (çocukların efektlerinden ÖNCE) yazılır.
 */
function AuthSync({ children }: { children: React.ReactNode }) {
    const { data: session } = useSession();
    apiClient.setToken(session?.accessToken ?? null);

    useEffect(() => {
        // Sunucu tarafı yenileme başarısızsa geçersiz jetonla devam edilmez.
        if (session?.error) void signOut({ callbackUrl: "/login" });
    }, [session?.error]);

    return <>{children}</>;
}

export function Providers({ children }: { children: React.ReactNode }) {
    const [queryClient] = useState(
        () =>
            new QueryClient({
                defaultOptions: {
                    queries: {
                        staleTime: 30 * 1000,
                        refetchOnWindowFocus: false,
                        // Hata 4xx ise tekrar denemek anlamsız; kullanıcıya hemen gösterilir.
                        retry: false,
                    },
                },
            })
    );

    // Oturum her 4 dakikada tazelenir: erişim jetonu 15 dakikada dolar ve
    // `jwt` geri çağrısı süresi yaklaşan jetonu sunucu tarafında yeniler.
    return (
        <SessionProvider refetchInterval={240} refetchOnWindowFocus>
            <AuthSync>
                <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
            </AuthSync>
        </SessionProvider>
    );
}
