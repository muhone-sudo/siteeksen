"use client";

import { Suspense, useState } from "react";
import { useSearchParams } from "next/navigation";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, Input, Notice, Page, QueryView, Stats, Table } from "@/components/ui/kit";
import { date, dateTime, kurus } from "@/lib/format";
import type { MpPackage } from "@/lib/types";

const KIND: Record<string, string> = {
    TOPUP: "Bakiye yükleme", PACKAGE_FEE: "Paket aidatı", REQUEST_FEE: "Talep kabul ücreti", INCLUDED_REQUEST: "Paketten talep hakkı",
    REFUND: "İade", CLOSURE_REFUND: "Kapanış iadesi",
};

/** Bakiye ve paket (FAZ M5, K5/K6): kartla yükleme (iyzico), hareketler, paket seçimi. */
export default function SupplierWalletPage() {
    return <Suspense fallback={null}><Wallet /></Suspense>;
}

function Wallet() {
    const params = useSearchParams();
    const [offset, setOffset] = useState(0);
    const w = useApi(["market-wallet", offset], () => api.market.wallet(offset));
    const meta = useApi(["market-meta"], api.market.meta);
    const me = useApi(["market-me"], api.market.supplierMe);
    const closed = me.data?.status === "CLOSED";
    const frozen = closed || me.data?.status === "SUSPENDED";
    const act = useAction();
    const [amount, setAmount] = useState("");
    const returned = params.get("status");
    const pay = async () => {
        const k = Math.round(Number(amount.replace(",", ".")) * 100);
        const r = await act.run(() => api.market.startTopup(k, crypto.randomUUID()));
        if (r?.checkout_url) window.location.href = r.checkout_url;
    };
    const choose = (p: MpPackage) => act.run(() => api.market.changePackage(p.id), { invalidate: ["market-wallet", "market-me"], success: (r) => r.message });
    return (
        <Page title="Bakiye ve paket" description="Talep kabul ücretleri ve paket aidatı bakiyeden düşer; borç oluşmaz">
            {returned && (
                <Notice tone={returned === "SUCCEEDED" ? "green" : returned === "FAILED" ? "red" : "amber"} title="Ödeme sonucu">
                    {params.get("message")}
                </Notice>
            )}
            <ActionFeedback action={act} />
            <QueryView q={w} isEmpty={() => false}>
                {(d) => (
                    <>
                        <Stats items={[
                            { label: "Bakiye", value: kurus(d.balance_kurus), tone: "blue" },
                            { label: "Paket", value: d.package.name, hint: d.package_renews_at ? `yenileme ${date(d.package_renews_at)}` : undefined },
                            { label: "Bu dönem kalan dahil talep", value: d.period_included_left },
                            { label: "Bu dönem kalan SMS", value: d.period_sms_left },
                        ]} />
                        {closed && <Notice tone="amber">Üyeliğiniz kapatıldı; bakiye yüklenemez ve paket değiştirilemez.</Notice>}
                        {!closed && <Card title="Bakiye yükle">
                            {d.card_ready ? (
                                <div className="flex flex-wrap items-end gap-2">
                                    <Field label="Tutar (TL)"><Input inputMode="decimal" value={amount} onChange={(e) => setAmount(e.target.value)} placeholder="500" /></Field>
                                    <Button disabled={act.pending || !(Number(amount.replace(",", ".")) > 0)} onClick={() => void pay()}>Kartla öde</Button>
                                    <p className="w-full text-xs text-gray-500">Kart bilgileriniz SiteEksen&apos;e gelmez; ödeme iyzico sayfasında 3D Secure ile alınır. Bakiye çekilemez; üyelik kapanırsa kalan bakiye iade edilir.</p>
                                </div>
                            ) : <Notice tone="amber">Kartla ödeme bu kurulumda yapılandırılmamış.</Notice>}
                        </Card>}
                        <Card title="Paket">
                            <QueryView q={meta}>
                                {(m) => (
                                    <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                                        {m.packages.map((p) => {
                                            const current = p.id === d.package.id;
                                            const next = p.id === d.next_package_id;
                                            return (
                                                <div key={p.id} className={`rounded-lg border p-4 text-sm ${current ? "border-primary bg-primary/5" : ""}`}>
                                                    <p className="font-semibold">{p.name} {current && <Badge tone="blue">Mevcut</Badge>} {next && <Badge tone="amber">Dönem sonunda</Badge>}</p>
                                                    <p className="text-lg">{p.monthly_fee_kurus ? `${kurus(p.monthly_fee_kurus)} / ay` : "Ücretsiz"}</p>
                                                    <ul className="mt-2 list-inside list-disc text-gray-600">
                                                        <li>Talep ücretinde %{p.fee_discount_pct} indirim</li>
                                                        <li>Ayda {p.included_requests} talep dahil, {p.monthly_sms} SMS</li>
                                                        <li>{p.priority_access ? "Yeni talepleri önce görür" : "Öncelik penceresi yok"}</li>
                                                        <li>{p.phone_in_showcase ? "Telefon vitrinde görünür" : "Telefon vitrinde gizli"}</li>
                                                    </ul>
                                                    {!current && !frozen && <Button className="mt-3" size="sm" disabled={act.pending} onClick={() => void choose(p)}>Bu pakete geç</Button>}
                                                    {current && d.next_package_id && !frozen && <Button className="mt-3" size="sm" variant="secondary" disabled={act.pending} onClick={() => void choose(p)}>Değişikliği iptal et</Button>}
                                                </div>
                                            );
                                        })}
                                    </div>
                                )}
                            </QueryView>
                        </Card>
                        <Card title="Hareketler" padded={false}>
                            {d.total === 0 && <p className="p-4 text-sm text-gray-500">Henüz hareket yok. Bakiye yüklediğinizde burada görünür.</p>}
                            <Table rows={d.data} rowKey={(x) => x.id} columns={[
                                { header: "Tarih", cell: (x) => dateTime(x.created_at) },
                                { header: "Tür", cell: (x) => KIND[x.kind] ?? x.kind },
                                { header: "Açıklama", cell: (x) => <span className="text-xs">{x.note}</span> },
                                { header: "Tutar", cell: (x) => <span className={x.amount_kurus < 0 ? "text-red-600" : "text-green-700"}>{kurus(x.amount_kurus)}</span> },
                                { header: "Sonraki bakiye", cell: (x) => kurus(x.balance_after) },
                            ]} />
                            {d.total > d.limit && (
                                <div className="flex justify-between p-3 text-sm">
                                    <Button size="sm" variant="ghost" disabled={offset === 0} onClick={() => setOffset(Math.max(0, offset - d.limit))}>Önceki</Button>
                                    <span>{offset + 1}–{Math.min(offset + d.limit, d.total)} / {d.total}</span>
                                    <Button size="sm" variant="ghost" disabled={offset + d.limit >= d.total} onClick={() => setOffset(offset + d.limit)}>Sonraki</Button>
                                </div>
                            )}
                        </Card>
                    </>
                )}
            </QueryView>
        </Page>
    );
}
