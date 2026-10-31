"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Button, Card, Field, FormModal, Page, QueryView, Select, StatusBadge, Table, Textarea } from "@/components/ui/kit";
import { dateTime, kurus } from "@/lib/format";
import { DISPUTE_REASON, DISPUTE_STATUS } from "@/components/market/labels";
import type { MpDispute } from "@/lib/types";

/** Geçersiz talep bildirimleri (FAZ M7.6, K6): onayda kabul ücreti bakiyeye iade edilir (dahil hakla kabulde hak geri). */
export default function PlatformDisputesPage() {
    const [status, setStatus] = useState("OPEN");
    const q = useApi(["mp-disputes", status], () => api.market.platform.disputes(status));
    const act = useAction();
    const [dec, setDec] = useState<{ x: MpDispute; approve: boolean; note: string } | null>(null);
    return (
        <Page title="Geçersiz talep bildirimleri" description="Tedarikçinin kabul ettiği talebi geçersiz bulduğu bildirimler; iade yalnız onayla">
            <ActionFeedback action={act} />
            <div className="max-w-xs">
                <Field label="Durum">
                    <Select value={status} onChange={(e) => setStatus(e.target.value)} options={[{ value: "OPEN", label: "İncelenecek" },
                        { value: "APPROVED", label: "Onaylanan" }, { value: "REJECTED", label: "Reddedilen" }, { value: "", label: "Hepsi" }]} />
                </Field>
            </div>
            <Card padded={false}>
                <QueryView q={q} empty="Bildirim yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(x) => x.id} columns={[
                            { header: "Tarih", cell: (x) => dateTime(x.created_at) },
                            { header: "Tedarikçi", cell: (x) => x.trade_name },
                            { header: "Talep", cell: (x) => x.category },
                            { header: "Neden", cell: (x) => <div><p>{DISPUTE_REASON[x.reason_code]}</p><p className="text-xs text-gray-500">{x.note}</p></div> },
                            { header: "İade", cell: (x) => x.used_included ? "paket hakkı" : kurus(x.fee_kurus) },
                            { header: "Durum", cell: (x) => <div><StatusBadge value={x.status} map={DISPUTE_STATUS} />{x.decision_note && <p className="text-xs text-gray-500">{x.decision_note}</p>}</div> },
                            { header: "", cell: (x) => x.status === "OPEN" && (
                                <div className="flex gap-1">
                                    <Button size="sm" onClick={() => setDec({ x, approve: true, note: "" })}>Onayla ve iade et</Button>
                                    <Button size="sm" variant="ghost" onClick={() => setDec({ x, approve: false, note: "" })}>Reddet</Button>
                                </div>
                            ) },
                        ]} />
                    )}
                </QueryView>
            </Card>
            {dec && (
                <FormModal open title={dec.approve ? "Bildirimi onayla" : "Bildirimi reddet"} submitLabel={dec.approve ? "Onayla ve iade et" : "Reddet"}
                    pending={act.pending} error={act.error} onClose={() => setDec(null)}
                    onSubmit={async () => {
                        const r = await act.run(() => api.market.platform.decideDispute(dec.x.id, dec.approve, dec.note),
                            { invalidate: ["mp-disputes"], success: dec.approve ? "Onaylandı; iade yapıldı ve tedarikçiye bildirildi" : "Reddedildi; tedarikçiye bildirildi" });
                        if (r) setDec(null);
                    }}>
                    <p className="text-sm">{dec.x.trade_name} — {dec.x.category}. {dec.approve && (dec.x.used_included ? "Paket talep hakkı geri verilir." : `${kurus(dec.x.fee_kurus)} bakiyeye iade edilir.`)}</p>
                    <Field label="Gerekçe (tedarikçiye gösterilir)" required><Textarea value={dec.note} onChange={(e) => setDec({ ...dec, note: e.target.value })} /></Field>
                </FormModal>
            )}
        </Page>
    );
}
