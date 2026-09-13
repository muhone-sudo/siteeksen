"use client";

/**
 * Yönetim Paneli Ana Sayfası
 *
 * NEDEN YENİDEN YAZILDI (2026-09-13):
 * Sayfanın TAMAMI uydurmaydı ve yöneticinin ilk gördüğü ekran olduğu için en
 * yanıltıcı yerdi:
 *   - "124 sakin", "₺45.600 tahsilat", "%87 tahsilat oranı", "7 açık talep"
 *     koda gömülüydü; hangi siteye girilirse girilsin aynı rakamlar çıkıyordu.
 *   - 12 aylık tahsilat grafiği ve tüketim dağılımı pastası tamamen uyduruktu.
 *   - "Son Ödemeler" bölümünde var olmayan kişiler ve tutarlar listeleniyordu.
 *   - Trend okları ("+12%", "-2%") hiçbir hesaba dayanmıyordu.
 *
 * Artık tüm veriler gateway'in toplu uçlarından gelir. Ulaşılamayan kaynak için
 * UYDURMA DEĞER GÖSTERİLMEZ: kart "—" gösterir ve hangi kaynağa ulaşılamadığı
 * ayrıca bildirilir. Trend/karşılaştırma verisi sunucu üretmediği için tamamen
 * kaldırılmıştır — uydurmak yerine göstermemek doğrudur.
 */

import { useCallback, useEffect, useState } from "react";
import { useSession } from "next-auth/react";
import { Users, Receipt, TrendingUp, AlertCircle, Home } from "lucide-react";
import { apiClient } from "@/lib/api-client";
import { ErrorState, LoadingState, toUserMessage } from "@/components/ui/data-state";

interface DashboardStats {
    totalResidents?: number;
    totalUnits?: number;
    pendingRequests?: number;
    monthlyIncome?: number;
    collectionRate?: number;
}

interface Unavailable {
    source: string;
    reason: string;
}

interface PaymentRow {
    id?: string;
    name?: string;
    unit?: string;
    amount?: number;
    created_at?: string;
    status?: string;
}

interface RequestRow {
    id?: string;
    title?: string;
    ticket_number?: string;
    unit?: string;
    status?: string;
    created_at?: string;
}

const TRY = new Intl.NumberFormat("tr-TR", {
    style: "currency",
    currency: "TRY",
    maximumFractionDigits: 0,
});

export default function DashboardPage() {
    const { data: session, status } = useSession();

    const [stats, setStats] = useState<DashboardStats | null>(null);
    const [unavailable, setUnavailable] = useState<Unavailable[]>([]);
    const [payments, setPayments] = useState<PaymentRow[] | null>(null);
    const [paymentsError, setPaymentsError] = useState<string | null>(null);
    const [requests, setRequests] = useState<RequestRow[] | null>(null);
    const [requestsError, setRequestsError] = useState<string | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        setPaymentsError(null);
        setRequestsError(null);

        try {
            const res = await apiClient.getDashboardStats();
            setStats(res?.data ?? null);
            setUnavailable(Array.isArray(res?.unavailable) ? res.unavailable : []);
        } catch (e) {
            setError(toUserMessage(e, "Özet veriler alınamadı"));
            setLoading(false);
            return;
        }

        // Bu iki bölüm bağımsız yüklenir; biri başarısız olursa diğeri görünmeye devam eder.
        try {
            const p = await apiClient.getRecentPayments();
            setPayments(Array.isArray(p?.data) ? p.data : []);
        } catch (e) {
            setPaymentsError(toUserMessage(e, "Son ödemeler alınamadı"));
        }
        try {
            const r = await apiClient.getRecentRequests();
            setRequests(Array.isArray(r?.data) ? r.data : []);
        } catch (e) {
            setRequestsError(toUserMessage(e, "Son talepler alınamadı"));
        }

        setLoading(false);
    }, []);

    useEffect(() => {
        if (status !== "authenticated") return;
        if (session?.accessToken) {
            apiClient.setToken(session.accessToken, session.refreshToken);
        }
        void load();
    }, [status, session, load]);

    if (loading) return <LoadingState />;
    if (error) return <ErrorState message={error} onRetry={load} />;

    // Değer yoksa "0" değil "—": bilinmeyen ile sıfır aynı şey değildir.
    const num = (v: number | undefined) => (v === undefined || v === null ? "—" : String(v));
    const money = (v: number | undefined) => (v === undefined || v === null ? "—" : TRY.format(v));
    const pct = (v: number | undefined) => (v === undefined || v === null ? "—" : `%${Math.round(v)}`);

    return (
        <div className="space-y-6">
            <div>
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Panel</h1>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                    Aktif sitenin genel durumu
                </p>
            </div>

            {unavailable.length > 0 && (
                <div className="rounded-lg border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900">
                    <p className="font-medium">Bazı özet veriler alınamadı</p>
                    <ul className="mt-1 list-inside list-disc">
                        {unavailable.map((u) => (
                            <li key={u.source}>
                                {u.source}: {u.reason}
                            </li>
                        ))}
                    </ul>
                    <p className="mt-2 text-xs">
                        Eksik kalan kartlarda uydurma değer gösterilmez; “—” işareti görürsünüz.
                    </p>
                </div>
            )}

            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                <StatCard title="Toplam Sakin" value={num(stats?.totalResidents)} icon={Users} />
                <StatCard title="Bağımsız Bölüm" value={num(stats?.totalUnits)} icon={Home} />
                <StatCard title="Tahsilat Oranı" value={pct(stats?.collectionRate)} icon={TrendingUp} />
                <StatCard title="Açık Talepler" value={num(stats?.pendingRequests)} icon={AlertCircle} />
            </div>

            <div className="grid gap-4 md:grid-cols-2">
                <StatCard title="Dönem Tahsilatı" value={money(stats?.monthlyIncome)} icon={Receipt} />
            </div>

            <div className="grid gap-6 lg:grid-cols-2">
                <Panel title="Son Ödemeler" href="/dashboard/accounting">
                    {paymentsError ? (
                        <ErrorState message={paymentsError} onRetry={load} />
                    ) : payments === null ? (
                        <LoadingState />
                    ) : payments.length === 0 ? (
                        <p className="text-sm text-gray-500">Kayıtlı ödeme yok.</p>
                    ) : (
                        <div className="space-y-4">
                            {payments.slice(0, 5).map((p, i) => (
                                <div key={p.id ?? i} className="flex items-center justify-between">
                                    <div className="flex items-center gap-3">
                                        <div className="flex h-10 w-10 items-center justify-center rounded-full bg-green-100 text-green-600 dark:bg-green-900/20">
                                            ₺
                                        </div>
                                        <div>
                                            {/* Sunucu isim döndürmezse UYDURULMAZ; kimlik gösterilir. */}
                                            <p className="font-medium text-gray-900 dark:text-white">
                                                {p.name || p.unit || p.id || "—"}
                                            </p>
                                            <p className="text-sm text-gray-500">{p.unit ?? ""}</p>
                                        </div>
                                    </div>
                                    <div className="text-right">
                                        <p className="font-medium text-gray-900 dark:text-white">
                                            {p.amount === undefined ? "—" : TRY.format(p.amount)}
                                        </p>
                                        <p className="text-sm text-gray-500">{formatDate(p.created_at)}</p>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </Panel>

                <Panel title="Son Talepler" href="/dashboard/requests">
                    {requestsError ? (
                        <ErrorState message={requestsError} onRetry={load} />
                    ) : requests === null ? (
                        <LoadingState />
                    ) : requests.length === 0 ? (
                        <p className="text-sm text-gray-500">Açık talep yok.</p>
                    ) : (
                        <div className="space-y-4">
                            {requests.slice(0, 5).map((r, i) => (
                                <div key={r.id ?? i} className="flex items-center justify-between">
                                    <div>
                                        <p className="font-medium text-gray-900 dark:text-white">
                                            {r.title || r.ticket_number || "Talep"}
                                        </p>
                                        <p className="text-sm text-gray-500">
                                            {[r.unit, formatDate(r.created_at)].filter(Boolean).join(" • ")}
                                        </p>
                                    </div>
                                    <StatusBadge status={r.status} />
                                </div>
                            ))}
                        </div>
                    )}
                </Panel>
            </div>
        </div>
    );
}

function formatDate(value?: string) {
    if (!value) return "";
    const d = new Date(value);
    if (Number.isNaN(d.getTime())) return "";
    return d.toLocaleDateString("tr-TR", { day: "numeric", month: "long", year: "numeric" });
}

function StatCard({
    title,
    value,
    icon: Icon,
}: {
    title: string;
    value: string;
    icon: React.ElementType;
}) {
    return (
        <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
            <div className="rounded-lg bg-primary/10 p-3 w-fit">
                <Icon className="h-6 w-6 text-primary" />
            </div>
            <div className="mt-4">
                <p className="text-2xl font-bold text-gray-900 dark:text-white">{value}</p>
                <p className="text-sm text-gray-500 dark:text-gray-400">{title}</p>
            </div>
        </div>
    );
}

function Panel({
    title,
    href,
    children,
}: {
    title: string;
    href: string;
    children: React.ReactNode;
}) {
    return (
        <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
            <div className="mb-4 flex items-center justify-between">
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white">{title}</h3>
                <a href={href} className="text-sm text-primary hover:underline">
                    Tümünü Gör
                </a>
            </div>
            {children}
        </div>
    );
}

function StatusBadge({ status }: { status?: string }) {
    const map: Record<string, { label: string; color: string }> = {
        OPEN: { label: "Açık", color: "bg-yellow-100 text-yellow-700" },
        IN_PROGRESS: { label: "İşlemde", color: "bg-blue-100 text-blue-700" },
        RESOLVED: { label: "Çözüldü", color: "bg-green-100 text-green-700" },
        CLOSED: { label: "Kapandı", color: "bg-gray-100 text-gray-700" },
    };
    const cfg = map[status ?? ""] ?? { label: status ?? "—", color: "bg-gray-100 text-gray-700" };
    return (
        <span className={`rounded-full px-3 py-1 text-xs font-medium ${cfg.color}`}>{cfg.label}</span>
    );
}
