"use client";

import { useCallback, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useSession } from "next-auth/react";
import { toUserMessage } from "@/components/ui/data-state";
import { isAuditorOnly, isManagement } from "@/lib/rbac";

/**
 * Okuma kancası. Oturum hazır olmadan istek ATILMAZ: önceki sayfalar jeton
 * yazılmadan istek atıyor, 401 alıp kullanıcıyı giriş ekranına atıyordu.
 * İlk anahtar öğesi "kaynak adı"dır; yazma işlemleri bu adla önbelleği tazeler.
 */
export function useApi<T>(key: readonly unknown[], fn: () => Promise<T>, enabled = true) {
    const { status } = useSession();
    return useQuery({
        queryKey: key,
        queryFn: fn,
        enabled: status === "authenticated" && enabled,
    });
}

/**
 * Yazma kancası: bekleme, hata ve başarı mesajı tek yerde.
 *
 * Başarı mesajı yalnızca SUNUCU işlemi kabul ettiğinde gösterilir; sunucunun
 * döndürdüğü `note` (ör. "ücret hesaplandı ama TAHSİL EDİLMEDİ") kullanıcıdan
 * saklanmaz — başarı mesajının yanına eklenir.
 */
export function useAction() {
    const qc = useQueryClient();
    const [pending, setPending] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [message, setMessage] = useState<string | null>(null);

    const run = useCallback(
        async <R,>(
            fn: () => Promise<R>,
            opts?: { invalidate?: string[]; success?: string | ((r: R) => string); fallbackError?: string }
        ): Promise<R | undefined> => {
            setPending(true);
            setError(null);
            setMessage(null);
            try {
                const r = await fn();
                for (const k of opts?.invalidate ?? []) {
                    await qc.invalidateQueries({ queryKey: [k] });
                }
                const base = typeof opts?.success === "function" ? opts.success(r) : opts?.success;
                const note = (r as { note?: unknown } | undefined)?.note;
                const parts = [base, typeof note === "string" ? note : undefined].filter(Boolean);
                setMessage(parts.length ? parts.join(" — ") : null);
                return r;
            } catch (e) {
                setError(toUserMessage(e, opts?.fallbackError ?? "İşlem tamamlanamadı."));
                return undefined;
            } finally {
                setPending(false);
            }
        },
        [qc]
    );

    const clear = useCallback(() => {
        setError(null);
        setMessage(null);
    }, []);

    return { run, pending, error, message, clear };
}

/** Oturumdaki rollerden yazma yetkisi. Denetçi okur ama yazamaz (KMK m.41). */
export function useRoles() {
    const { data } = useSession();
    const roles = data?.user?.roles ?? [];
    return {
        roles,
        canWrite: isManagement(roles),
        auditorOnly: isAuditorOnly(roles),
        isStaff: roles.includes("STAFF"),
        userId: data?.user?.id ?? "",
    };
}
