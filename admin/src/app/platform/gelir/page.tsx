"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useApi } from "@/lib/use-api";
import { Card, Field, Input, Notice, Page, QueryView, Stats } from "@/components/ui/kit";
import { kurus } from "@/lib/format";

const today = () => new Date().toLocaleDateString("sv-SE", { timeZone: "Europe/Istanbul" });

/** Gelir raporu (FAZ M7.8): bakiye defterinden — aidat + talep ücreti − iade. Yüklemeler gelir değil, tedarikçi adına tutulan bakiyedir. */
export default function PlatformRevenuePage() {
    const [from, setFrom] = useState(today().slice(0, 8) + "01");
    const [to, setTo] = useState(today());
    const q = useApi(["mp-revenue", from, to], () => api.market.platform.revenue(from, to), Boolean(from && to));
    return (
        <Page title="Gelir raporu" description="Usta & Hizmet gelirleri, bakiye defterinden">
            <div className="flex flex-wrap gap-3">
                <Field label="Başlangıç"><Input type="date" value={from} onChange={(e) => setFrom(e.target.value)} /></Field>
                <Field label="Bitiş"><Input type="date" value={to} onChange={(e) => setTo(e.target.value)} /></Field>
            </div>
            <QueryView q={q} isEmpty={() => false}>
                {(r) => (
                    <>
                        <Stats items={[
                            { label: "Net gelir", value: kurus(r.net_kurus), tone: "green" },
                            { label: "Paket aidatı", value: kurus(r.package_fees_kurus) },
                            { label: "Talep kabul ücreti", value: kurus(r.request_fees_kurus) },
                            { label: "İade (geçersiz talep)", value: kurus(r.refunds_kurus), tone: "red" },
                        ]} />
                        <Card title="Bakiye hareketleri (gelir değil)">
                            <dl className="grid gap-2 text-sm sm:grid-cols-2">
                                <div><dt className="text-gray-500">Kartla yüklenen bakiye</dt><dd>{kurus(r.topups_kurus)}</dd></div>
                                <div><dt className="text-gray-500">Kapanışta havaleyle iade</dt><dd>{kurus(r.closure_refunds_kurus)}</dd></div>
                                <div><dt className="text-gray-500">Paketten kullanılan talep hakkı</dt><dd>{r.included_requests}</dd></div>
                                <div><dt className="text-gray-500">Tedarikçiler adına tutulan toplam bakiye (bugün)</dt><dd>{kurus(r.balance_liability_kurus)}</dd></div>
                            </dl>
                        </Card>
                        <Notice tone="blue">Net gelir = aidat + talep ücreti − iade. Defterdeki dönem toplamı: {kurus(r.ledger_total_kurus)}.</Notice>
                    </>
                )}
            </QueryView>
        </Page>
    );
}
