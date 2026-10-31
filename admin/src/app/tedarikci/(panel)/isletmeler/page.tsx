"use client";

import Link from "next/link";
import { api } from "@/lib/api";
import { useApi } from "@/lib/use-api";
import { Card, Notice, Page, QueryView, StatusBadge, Table } from "@/components/ui/kit";
import { BUSINESS_STATUS, SERVICE_AREA } from "@/components/market/labels";

/** Tedarikçinin işletmeleri/şubeleri (FAZ M3, K16). */
export default function SupplierBusinessesPage() {
    const list = useApi(["market-businesses"], api.market.businesses);
    const me = useApi(["market-me"], api.market.supplierMe);
    return (
        <Page title="İşletmelerim" description="Dükkânlarınız, şubeleriniz ve hizmet verdiğiniz alan"
            actions={me.data ? <Link href="/tedarikci/isletmeler/yeni" className="rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white">Yeni işletme</Link> : undefined}>
            {me.isError && <Notice tone="amber">Önce Hesabım sayfasından tedarikçi hesabınızı oluşturun.</Notice>}
            {me.data && me.data.status !== "APPROVED" && (
                <Notice tone="blue">İşletmeleriniz, hesabınız ve işletme bilgileri SiteEksen tarafından onaylandıktan sonra havuzda görünür.</Notice>
            )}
            {me.data && (
                <Card padded={false}>
                    <QueryView q={list} empty="Henüz işletme eklemediniz">
                        {(d) => (
                            <Table rows={d.data} rowKey={(b) => b.id} columns={[
                                { header: "İşletme", cell: (b) => <Link href={`/tedarikci/isletmeler/${b.id}`} className="font-medium text-primary hover:underline">{b.name}</Link> },
                                { header: "Yer", cell: (b) => `${b.district} / ${b.city}` },
                                { header: "Hizmet alanı", cell: (b) => (b.service_area === "KM" ? `${b.radius_km} km` : SERVICE_AREA[b.service_area]) },
                                { header: "Durum", cell: (b) => <StatusBadge value={b.status} map={BUSINESS_STATUS} /> },
                                { header: "Puan", cell: (b) => (b.rating_count ? `${(b.rating_sum / b.rating_count).toFixed(1)} (${b.rating_count})` : "—") },
                            ]} />
                        )}
                    </QueryView>
                </Card>
            )}
        </Page>
    );
}
