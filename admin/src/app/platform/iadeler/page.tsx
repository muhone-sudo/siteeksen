"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Button, Card, Field, FormModal, Input, Notice, Page, QueryView, Select, StatusBadge, Table } from "@/components/ui/kit";
import { date, dateTime, kurus } from "@/lib/format";
import { CARD_REFUND_REASON, CARD_REFUND_STATUS } from "@/components/market/labels";
import type { MpCardRefund } from "@/lib/types";

const today = () => new Date().toLocaleDateString("sv-SE", { timeZone: "Europe/Istanbul" });

/** Karta iadeler (FAZ M13.3): kapanışta ve kapanış sonrası yüklemede kalan bakiye karta iade edilir. Başarısız iade burada
 *  yeniden denenir ya da havaleyle ödenip dekontla kapatılır. */
export default function PlatformCardRefundsPage() {
    const [status, setStatus] = useState("FAILED");
    const q = useApi(["mp-card-refunds", status], () => api.market.platform.cardRefunds(status));
    const act = useAction();
    const [manual, setManual] = useState<{ x: MpCardRefund; reference: string; date: string } | null>(null);
    return (
        <Page title="Karta iadeler" description="Üyelik kapanışında kalan bakiyenin karta iadesi; başarısız olanlar elle tamamlanır">
            <ActionFeedback action={act} />
            <Notice tone="blue">Sonucu bilinmeyen iadeler (sağlayıcıya ulaşılamadı) çift iade olmasın diye kendiliğinden yeniden denenmez:
                önce iyzico panelinde ödemenin iade durumuna bakın; iade yapılmamışsa &quot;Yeniden dene&quot;, havaleyle ödediyseniz dekontla kapatın.</Notice>
            <div className="max-w-xs">
                <Field label="Durum">
                    <Select value={status} onChange={(e) => setStatus(e.target.value)} options={[{ value: "FAILED", label: "Başarısız (işlem bekliyor)" },
                        { value: "PENDING", label: "İşleniyor" }, { value: "SUCCEEDED", label: "Karta iletildi" }, { value: "MANUAL", label: "Havaleyle ödendi" },
                        { value: "", label: "Hepsi" }]} />
                </Field>
            </div>
            <Card padded={false}>
                <QueryView q={q} empty="Kayıt yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(x) => x.id} columns={[
                            { header: "Tarih", cell: (x) => dateTime(x.created_at) },
                            { header: "Tedarikçi", cell: (x) => x.trade_name },
                            { header: "Tutar", cell: (x) => <strong>{kurus(x.amount_kurus)}</strong> },
                            { header: "Neden", cell: (x) => <div><p>{CARD_REFUND_REASON[x.reason] ?? x.reason}</p><p className="text-xs text-gray-500">yükleme {date(x.topup_at)}</p></div> },
                            { header: "Durum", cell: (x) => (
                                <div>
                                    <StatusBadge value={x.status} map={CARD_REFUND_STATUS} />
                                    {x.last_error && x.status !== "SUCCEEDED" && <p className="text-xs text-red-600">{x.last_error}</p>}
                                    {x.gateway_reference && <p className="text-xs text-gray-500">iyzico {x.gateway_reference}</p>}
                                    {x.manual_reference && <p className="text-xs text-gray-500">dekont {x.manual_reference} · {date(x.manual_date)}</p>}
                                </div>
                            ) },
                            { header: "", cell: (x) => x.status === "FAILED" && (
                                <div className="flex gap-1">
                                    <Button size="sm" variant="secondary" disabled={act.pending}
                                        onClick={() => act.run(() => api.market.platform.retryCardRefund(x.id), { invalidate: ["mp-card-refunds"], success: "Yeniden denemeye alındı" })}>Yeniden dene</Button>
                                    <Button size="sm" onClick={() => setManual({ x, reference: "", date: today() })}>Havaleyle ödendi</Button>
                                </div>
                            ) },
                        ]} />
                    )}
                </QueryView>
            </Card>
            {manual && (
                <FormModal open title="Havaleyle ödendi" submitLabel="Kaydet" pending={act.pending} error={act.error} onClose={() => setManual(null)}
                    onSubmit={async () => {
                        const r = await act.run(() => api.market.platform.resolveCardRefund(manual.x.id, { reference: manual.reference, date: manual.date }),
                            { invalidate: ["mp-card-refunds"], success: "İade havaleyle kapatıldı; tedarikçiye bildirildi" });
                        if (r) setManual(null);
                    }}>
                    <p className="text-sm">{manual.x.trade_name} — {kurus(manual.x.amount_kurus)}. Tutarı tedarikçinin kendi adına kayıtlı banka hesabına gönderin.</p>
                    <Field label="Havale dekont no" required><Input value={manual.reference} onChange={(e) => setManual({ ...manual, reference: e.target.value })} /></Field>
                    <Field label="Havale tarihi" required><Input type="date" value={manual.date} onChange={(e) => setManual({ ...manual, date: e.target.value })} /></Field>
                </FormModal>
            )}
        </Page>
    );
}
