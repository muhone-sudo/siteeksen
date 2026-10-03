"use client";

/**
 * Panel ana sayfası — gateway'in toplu uçlarından GERÇEK veri.
 * Ulaşılamayan kaynak için uydurma değer gösterilmez: kart "—" gösterir ve
 * nedeni ayrıca listelenir. (Önceki sürümde pano toplayıcısı servis
 * yanıtlarını çözemiyor, bütün kartlar "—" kalıyordu — 2026-09-26 düzeltildi.)
 */
import Link from "next/link";
import { api } from "@/lib/api";
import { useApi } from "@/lib/use-api";
import { Card, Notice, Page, QueryView, Stats, StatusBadge, Table } from "@/components/ui/kit";
import { date, num, pct, tl } from "@/lib/format";
import { PAYMENT_STATUS, REQUEST_STATUS } from "@/lib/labels";

export default function DashboardPage() {
    const stats = useApi(["dashboard", "stats"], api.dashboard.stats);
    const payments = useApi(["dashboard", "payments"], api.dashboard.recentPayments);
    const requests = useApi(["dashboard", "requests"], api.dashboard.recentRequests);

    const s = stats.data?.data;
    const missing = stats.data?.unavailable ?? [];

    return (
        <Page title="Panel" description="Aktif sitenin genel durumu">
            {missing.length > 0 && (
                <Notice tone="amber" title="Bazı özet veriler alınamadı">
                    <ul className="list-inside list-disc">
                        {missing.map((u) => (
                            <li key={u.source}>
                                {u.source}: {u.reason}
                            </li>
                        ))}
                    </ul>
                    <p className="mt-1 text-xs">Eksik kartlarda uydurma değer gösterilmez; “—” görürsünüz.</p>
                </Notice>
            )}
            <Stats
                items={[
                    { label: "Sakin", value: num(s?.totalResidents), tone: "blue" },
                    { label: "Bağımsız bölüm", value: num(s?.totalUnits) },
                    { label: "Bekleyen talep", value: num(s?.pendingRequests), tone: "amber" },
                    {
                        label: s?.period ? `Tahsilat oranı (${s.period})` : "Tahsilat oranı",
                        value: pct(s?.collectionRate, 1),
                        tone: "green",
                        hint: s?.period ? `${tl(s.monthlyIncome)} / ${tl(s.monthlyAssessed)}` : undefined,
                    },
                ]}
            />
            <div className="grid gap-6 lg:grid-cols-2">
                <Card title="Son ödemeler" actions={<Link href="/dashboard/accounting" className="text-sm text-primary hover:underline">Tümü</Link>} padded={false}>
                    <QueryView q={payments} empty="Kayıtlı ödeme yok">
                        {(d) => (
                            <Table
                                rows={d.data}
                                rowKey={(p) => p.id}
                                columns={[
                                    { header: "Kişi", cell: (p) => p.name || "—" },
                                    { header: "Daire", cell: (p) => p.unit || "—" },
                                    { header: "Tutar", cell: (p) => tl(p.amount) },
                                    { header: "Durum", cell: (p) => <StatusBadge value={p.status} map={PAYMENT_STATUS} /> },
                                    { header: "Tarih", cell: (p) => date(p.created_at) },
                                ]}
                            />
                        )}
                    </QueryView>
                </Card>
                <Card title="Son talepler" actions={<Link href="/dashboard/requests" className="text-sm text-primary hover:underline">Tümü</Link>} padded={false}>
                    <QueryView q={requests} empty="Talep yok">
                        {(d) => (
                            <Table
                                rows={d.data}
                                rowKey={(r) => r.id}
                                columns={[
                                    { header: "No", cell: (r) => <span className="font-mono text-xs">{r.ticket_number}</span> },
                                    { header: "Başlık", cell: (r) => r.title },
                                    { header: "Durum", cell: (r) => <StatusBadge value={r.status} map={REQUEST_STATUS} /> },
                                    { header: "Tarih", cell: (r) => date(r.created_at) },
                                ]}
                            />
                        )}
                    </QueryView>
                </Card>
            </div>
        </Page>
    );
}
