"use client";

import Link from "next/link";
import { Card, Notice, Page } from "@/components/ui/kit";

/**
 * Raporlar.
 *
 * PDF/Excel rapor üretimi YOKTUR (gateway 501 döner). Önceki sürüm uydurma
 * tutarlarla indirilebilir mali rapor üretiyordu; kaldırıldı. Gerçek verinin
 * görüntülendiği ekranlar aşağıdadır — her biri canlı veritabanı verisidir.
 */
const LINKS: { href: string; title: string; desc: string }[] = [
    { href: "/dashboard/assessments", title: "Tahakkuk dönemleri", desc: "Dönem bazında tahakkuk, tahsilat ve oran" },
    { href: "/dashboard/accounting", title: "Tahsilat ve borçlular", desc: "Ödemeler ve daire bazında borç" },
    { href: "/dashboard/expenses", title: "Gider özeti", desc: "Kalem bazında gider, faturalı/faturasız ayrımı" },
    { href: "/dashboard/governance/budgets", title: "İşletme projesi", desc: "Daire bazında yıllık/aylık pay dökümü" },
    { href: "/dashboard/collection", title: "Tahsilat riski", desc: "Açıklanabilir risk puanı ve önerilen eylem" },
    { href: "/dashboard/energy", title: "Enerji analizi", desc: "Tüketim eğilimi ve olağandışı tüketim" },
    { href: "/dashboard/esg", title: "Karbon ayak izi", desc: "Kullanıcının verdiği katsayılarla CO₂e" },
];

export default function ReportsPage() {
    return (
        <Page title="Raporlar" description="Canlı veriden özet ekranlar">
            <Notice tone="amber" title="PDF / Excel rapor üretimi henüz yok">
                Rapor dosyası üretimi gerçek mali veriye bağlanana kadar kapalıdır. Aşağıdaki ekranlar canlı veriyi gösterir; tarayıcının yazdırma özelliğiyle çıktı alınabilir.
            </Notice>
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                {LINKS.map((l) => (
                    <Link key={l.href} href={l.href}>
                        <Card className="h-full transition hover:ring-2 hover:ring-primary/30">
                            <p className="font-semibold text-gray-900 dark:text-white">{l.title}</p>
                            <p className="mt-1 text-sm text-gray-500">{l.desc}</p>
                        </Card>
                    </Link>
                ))}
            </div>
        </Page>
    );
}
