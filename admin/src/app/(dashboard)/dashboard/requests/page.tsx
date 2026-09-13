"use client";

/**
 * Talep Yönetimi
 *
 * NEDEN YENİDEN YAZILDI (2026-09-13):
 * Sayfanın tamamı yerel duruma (useState) dayanıyordu:
 *   - 4 talep koda gömülüydü ("Ahmet Yılmaz", "TLP-2026-0142" …).
 *   - Durum değiştirme, düzenleme ve silme yalnızca ekranda görünüyor, hiçbir
 *     yere kaydedilmiyordu. Sayfa yenilendiğinde her şey eski hâline dönüyordu.
 *     Yönetici "talebi çözüldü işaretledim" sanıyor, sakin hâlâ bekliyordu.
 *   - CSV içe aktarma satırları yalnızca listeye ekliyordu; sunucuya gitmiyordu.
 *     Bu yüzden kaldırıldı (gerçek toplu içe aktarma ucu yok).
 *
 * Talepler modülü gerçek veritabanına bağlı olan üç servisten biridir
 * (community-service), bu yüzden burada tam işlevsel bağlantı kurulabilmiştir.
 */

import { useCallback, useEffect, useMemo, useState } from "react";
import { useSession } from "next-auth/react";
import { Search, MessageSquare, Clock, ChevronDown } from "lucide-react";
import { apiClient } from "@/lib/api-client";
import { ErrorState, LoadingState, EmptyState, toUserMessage } from "@/components/ui/data-state";

interface RequestRow {
    id: string;
    ticket_number?: string;
    title: string;
    description?: string;
    category_name?: string;
    unit_name?: string;
    status: string;
    priority?: string;
    created_at?: string;
    resolved_at?: string;
    user_confirmed_at?: string;
}

const statusConfig: Record<string, { label: string; color: string }> = {
    OPEN: { label: "Açık", color: "bg-yellow-100 text-yellow-700" },
    IN_PROGRESS: { label: "İşlemde", color: "bg-blue-100 text-blue-700" },
    RESOLVED: { label: "Çözüldü", color: "bg-green-100 text-green-700" },
    CLOSED: { label: "Kapatıldı", color: "bg-gray-100 text-gray-700" },
};

const priorityConfig: Record<string, { label: string; color: string }> = {
    LOW: { label: "Düşük", color: "text-gray-500" },
    NORMAL: { label: "Normal", color: "text-blue-500" },
    HIGH: { label: "Yüksek", color: "text-orange-500" },
    URGENT: { label: "Acil", color: "text-red-500" },
};

/** Yöneticinin bir talebi taşıyabileceği sonraki durumlar. */
const NEXT_STATUS: Record<string, string[]> = {
    OPEN: ["IN_PROGRESS", "RESOLVED"],
    IN_PROGRESS: ["RESOLVED"],
    // RESOLVED → CLOSED geçişini SAKİN yapar (onay akışı, migration 010).
    RESOLVED: [],
    CLOSED: [],
};

export default function RequestsPage() {
    const { data: session, status: authStatus } = useSession();

    const [requests, setRequests] = useState<RequestRow[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [statusFilter, setStatusFilter] = useState("all");
    const [searchQuery, setSearchQuery] = useState("");
    const [busyId, setBusyId] = useState<string | null>(null);
    const [actionError, setActionError] = useState<string | null>(null);
    const [openMenuId, setOpenMenuId] = useState<string | null>(null);

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const res = await apiClient.getRequests(
                statusFilter === "all" ? undefined : { status: statusFilter }
            );
            const rows = Array.isArray(res) ? res : (res?.data ?? []);
            setRequests(rows as RequestRow[]);
        } catch (e) {
            setError(toUserMessage(e, "Talepler alınamadı"));
        } finally {
            setLoading(false);
        }
    }, [statusFilter]);

    useEffect(() => {
        if (authStatus !== "authenticated") return;
        if (session?.accessToken) {
            apiClient.setToken(session.accessToken, session.refreshToken);
        }
        void load();
    }, [authStatus, session, load]);

    const filtered = useMemo(() => {
        const q = searchQuery.trim().toLowerCase();
        if (!q) return requests;
        return requests.filter(
            (r) =>
                r.title?.toLowerCase().includes(q) ||
                r.ticket_number?.toLowerCase().includes(q)
        );
    }, [requests, searchQuery]);

    async function changeStatus(r: RequestRow, newStatus: string) {
        setBusyId(r.id);
        setActionError(null);
        setOpenMenuId(null);
        try {
            await apiClient.updateRequestStatus(r.id, newStatus);
            await load();
        } catch (e) {
            // Sunucu kabul etmediyse ekranda durum DEĞİŞTİRİLMEZ.
            setActionError(toUserMessage(e, "Talep durumu güncellenemedi"));
        } finally {
            setBusyId(null);
        }
    }

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Talepler</h1>
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                        Sakin talepleri ve iş emirleri
                    </p>
                </div>
                <button
                    onClick={load}
                    className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                    Yenile
                </button>
            </div>

            {actionError && (
                <div className="rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-700">
                    {actionError}
                </div>
            )}

            <div className="flex flex-wrap items-center gap-3">
                <div className="relative flex-1 min-w-[220px]">
                    <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                    <input
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        placeholder="Başlık veya talep numarası ara"
                        className="w-full rounded-lg border border-gray-300 py-2 pl-9 pr-3 text-sm"
                    />
                </div>
                <select
                    value={statusFilter}
                    onChange={(e) => setStatusFilter(e.target.value)}
                    className="rounded-lg border border-gray-300 px-3 py-2 text-sm"
                >
                    <option value="all">Tüm durumlar</option>
                    {Object.entries(statusConfig).map(([k, v]) => (
                        <option key={k} value={k}>
                            {v.label}
                        </option>
                    ))}
                </select>
            </div>

            {loading ? (
                <LoadingState />
            ) : error ? (
                <ErrorState message={error} onRetry={load} />
            ) : filtered.length === 0 ? (
                <EmptyState title="Bu filtreye uyan talep yok" />
            ) : (
                <div className="space-y-3">
                    {filtered.map((r) => {
                        const st = statusConfig[r.status] ?? {
                            label: r.status,
                            color: "bg-gray-100 text-gray-700",
                        };
                        const pr = priorityConfig[r.priority ?? "NORMAL"];
                        const next = NEXT_STATUS[r.status] ?? [];

                        return (
                            <div
                                key={r.id}
                                className="rounded-xl bg-white p-5 shadow-sm dark:bg-gray-800"
                            >
                                <div className="flex flex-wrap items-start justify-between gap-3">
                                    <div className="min-w-0 flex-1">
                                        <div className="flex items-center gap-2">
                                            <MessageSquare className="h-4 w-4 text-gray-400" />
                                            <span className="text-xs text-gray-500">
                                                {r.ticket_number ?? r.id}
                                            </span>
                                            {pr && (
                                                <span className={`text-xs font-medium ${pr.color}`}>
                                                    {pr.label}
                                                </span>
                                            )}
                                        </div>
                                        <p className="mt-1 font-medium text-gray-900 dark:text-white">
                                            {r.title}
                                        </p>
                                        {r.description && (
                                            <p className="mt-1 text-sm text-gray-600 dark:text-gray-300">
                                                {r.description}
                                            </p>
                                        )}
                                        <div className="mt-2 flex items-center gap-3 text-xs text-gray-500">
                                            {r.category_name && <span>{r.category_name}</span>}
                                            {r.unit_name && <span>{r.unit_name}</span>}
                                            {r.created_at && (
                                                <span className="flex items-center gap-1">
                                                    <Clock className="h-3 w-3" />
                                                    {new Date(r.created_at).toLocaleString("tr-TR")}
                                                </span>
                                            )}
                                        </div>
                                    </div>

                                    <div className="flex items-center gap-2">
                                        <span
                                            className={`rounded-full px-3 py-1 text-xs font-medium ${st.color}`}
                                        >
                                            {st.label}
                                        </span>

                                        {next.length > 0 && (
                                            <div className="relative">
                                                <button
                                                    disabled={busyId === r.id}
                                                    onClick={() =>
                                                        setOpenMenuId(openMenuId === r.id ? null : r.id)
                                                    }
                                                    className="flex items-center gap-1 rounded-lg border border-gray-300 px-3 py-1.5 text-xs font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-50"
                                                >
                                                    Durum
                                                    <ChevronDown className="h-3 w-3" />
                                                </button>
                                                {openMenuId === r.id && (
                                                    <div className="absolute right-0 z-10 mt-1 w-40 rounded-lg border border-gray-200 bg-white py-1 shadow-lg">
                                                        {next.map((s) => (
                                                            <button
                                                                key={s}
                                                                onClick={() => changeStatus(r, s)}
                                                                className="block w-full px-3 py-2 text-left text-sm hover:bg-gray-50"
                                                            >
                                                                {statusConfig[s]?.label ?? s}
                                                            </button>
                                                        ))}
                                                    </div>
                                                )}
                                            </div>
                                        )}
                                    </div>
                                </div>

                                {r.status === "RESOLVED" && !r.user_confirmed_at && (
                                    <p className="mt-3 rounded-lg bg-amber-50 p-2 text-xs text-amber-800">
                                        Çözüldü olarak işaretlendi; talebin kapanması için sakinin
                                        onayı bekleniyor.
                                    </p>
                                )}
                            </div>
                        );
                    })}
                </div>
            )}
        </div>
    );
}
