"use client";

/**
 * Yetkisiz erişim sayfası.
 *
 * NEDEN VAR: Kullanıcı erişemeyeceği bir ekrana gittiğinde sessizce ana sayfaya
 * atmak kafa karıştırıcıdır ("tıkladım, bir şey olmadı"). Burada NEDEN erişemediği
 * ve hangi rolün gerektiği açıkça söylenir.
 */

import { Suspense } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { useSession } from "next-auth/react";
import { ShieldAlert } from "lucide-react";
import { requiredRolesFor } from "@/lib/rbac";

const ROLE_LABELS: Record<string, string> = {
    SUPER_ADMIN: "Sistem yöneticisi",
    MANAGER: "Yönetici",
    BOARD_MEMBER: "Yönetim kurulu üyesi",
    AUDITOR: "Denetçi",
    STAFF: "Görevli personel",
    RESIDENT: "Sakin",
    OWNER: "Malik",
    TENANT: "Kiracı",
};

function ForbiddenContent() {
    const params = useSearchParams();
    const { data: session } = useSession();

    const from = params.get("from") ?? "";
    const reason = params.get("reason") ?? "Bu sayfa";
    const rule = from ? requiredRolesFor(from) : null;
    const myRoles = session?.user?.roles ?? [];

    return (
        <div className="flex min-h-[60vh] items-center justify-center p-6">
            <div className="w-full max-w-lg rounded-xl border border-amber-200 bg-amber-50 p-6">
                <div className="flex items-start gap-4">
                    <ShieldAlert className="mt-1 h-6 w-6 shrink-0 text-amber-600" />
                    <div className="space-y-3">
                        <h1 className="text-lg font-semibold text-gray-900">
                            Bu sayfaya erişim yetkiniz yok
                        </h1>

                        <p className="text-sm text-gray-700">
                            <strong>{reason}</strong> yalnızca belirli rollere açıktır.
                        </p>

                        {rule && (
                            <p className="text-sm text-gray-700">
                                Gereken rol(ler):{" "}
                                <span className="font-medium">
                                    {rule.roles.map((r) => ROLE_LABELS[r] ?? r).join(", ")}
                                </span>
                            </p>
                        )}

                        <p className="text-sm text-gray-700">
                            Sizin rolleriniz:{" "}
                            <span className="font-medium">
                                {myRoles.length > 0
                                    ? myRoles.map((r) => ROLE_LABELS[r] ?? r).join(", ")
                                    : "tanımlı rol yok"}
                            </span>
                        </p>

                        <p className="text-xs text-gray-500">
                            Roller aktif siteye göre belirlenir. Başka bir sitede yönetici
                            olsanız bile bu sitede yetkiniz olmayabilir. Yetki değişikliği
                            için site yöneticisine başvurun.
                        </p>

                        <Link
                            href="/dashboard"
                            className="inline-block rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800"
                        >
                            Panele dön
                        </Link>
                    </div>
                </div>
            </div>
        </div>
    );
}

export default function ForbiddenPage() {
    return (
        <Suspense fallback={<div className="p-6 text-sm text-gray-500">Yükleniyor…</div>}>
            <ForbiddenContent />
        </Suspense>
    );
}
