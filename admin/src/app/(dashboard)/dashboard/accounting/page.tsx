"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Button, Card, Field, FormModal, Input, Notice, Page, QueryView, StatusBadge, Table, Tabs } from "@/components/ui/kit";
import { dateTime, tl } from "@/lib/format";
import { PAYMENT_STATUS } from "@/lib/labels";
import type { Payment } from "@/lib/types";

/**
 * Tahsilat ve borçlar.
 *
 * Ödeme sağlayıcısı entegrasyonu YOKTUR: sakinin başlattığı ödeme "onay
 * bekliyor" olarak kaydedilir; havale/EFT'yi gören yönetici dekont
 * numarasıyla onaylar. Onay, borcu tahakkuktan düşer.
 */
export default function AccountingPage() {
    const [tab, setTab] = useState<"pending" | "all" | "debtors">("pending");
    const pending = useApi(["payments", "pending"], api.finance.pendingPayments, tab === "pending");
    const all = useApi(["payments", "all"], api.finance.payments, tab === "all");
    const debtors = useApi(["debtors"], api.finance.debtors, tab === "debtors");
    const act = useAction();
    const { canWrite } = useRoles();
    const [confirming, setConfirming] = useState<Payment | null>(null);
    const [reference, setReference] = useState("");

    const paymentColumns = (withActions: boolean) => [
        { header: "Kişi", cell: (p: Payment) => p.name || "—" },
        { header: "Daire", cell: (p: Payment) => p.unit || "—" },
        { header: "Tutar", cell: (p: Payment) => tl(p.amount) },
        { header: "Yöntem", cell: (p: Payment) => p.payment_method },
        { header: "Durum", cell: (p: Payment) => <StatusBadge value={p.status} map={PAYMENT_STATUS} /> },
        { header: "Tarih", cell: (p: Payment) => dateTime(p.created_at) },
        ...(withActions && canWrite
            ? [{
                header: "",
                cell: (p: Payment) => (
                    <div className="flex gap-1">
                        <Button size="sm" onClick={() => { setReference(""); setConfirming(p); }}>Onayla</Button>
                        <Button size="sm" variant="danger" disabled={act.pending}
                            onClick={() => act.run(() => api.finance.rejectPayment(p.id), { invalidate: ["payments", "debtors", "dashboard"], success: "Ödeme reddedildi; borç değişmedi" })}>
                            Reddet
                        </Button>
                    </div>
                ),
            }]
            : []),
    ];

    return (
        <Page title="Tahsilat ve borçlar" description="Onay bekleyen ödemeler, ödeme geçmişi ve borçlu listesi.">
            <Notice tone="amber">
                Çevrimiçi ödeme sağlayıcısı bağlı değildir; kart ile tahsilat YAPILMAZ. Ödeme, yönetici banka hareketini gördükten sonra onayladığında borçtan düşer.
            </Notice>
            <ActionFeedback action={act} />
            <Tabs tabs={[{ id: "pending", label: "Onay bekleyen" }, { id: "all", label: "Tüm ödemeler" }, { id: "debtors", label: "Borçlular" }]} value={tab} onChange={setTab} />
            <Card padded={false}>
                {tab === "pending" && (
                    <QueryView q={pending} empty="Onay bekleyen ödeme yok">
                        {(d) => <Table rows={d.data} rowKey={(p) => p.id} columns={paymentColumns(true)} />}
                    </QueryView>
                )}
                {tab === "all" && (
                    <QueryView q={all} empty="Ödeme kaydı yok">
                        {(d) => <Table rows={d.data} rowKey={(p) => p.id} columns={paymentColumns(false)} />}
                    </QueryView>
                )}
                {tab === "debtors" && (
                    <QueryView q={debtors} empty="Borçlu yok">
                        {(d) => (
                            <Table
                                rows={d.data}
                                rowKey={(x) => `${x.resident_id}-${x.unit}`}
                                columns={[
                                    { header: "Kişi", cell: (x) => x.name },
                                    { header: "Daire", cell: (x) => x.unit },
                                    { header: "Borç", cell: (x) => <span className="font-medium text-red-600">{tl(x.amount)}</span> },
                                ]}
                            />
                        )}
                    </QueryView>
                )}
            </Card>

            <FormModal
                open={!!confirming}
                onClose={() => setConfirming(null)}
                title="Ödemeyi onayla"
                submitLabel="Onayla ve borçtan düş"
                pending={act.pending}
                error={act.error}
                onSubmit={async () => {
                    if (!confirming) return;
                    const r = await act.run(() => api.finance.confirmPayment(confirming.id, reference), {
                        invalidate: ["payments", "debtors", "assessments", "dashboard"],
                        success: `${tl(confirming.amount)} tahsilat onaylandı`,
                    });
                    if (r) setConfirming(null);
                }}
            >
                <p className="text-sm">{confirming?.name} — {confirming?.unit} — <b>{tl(confirming?.amount)}</b></p>
                <Field label="Dekont / işlem numarası" hint="Banka hareketiyle eşleştirme için saklanır.">
                    <Input value={reference} onChange={(e) => setReference(e.target.value)} />
                </Field>
            </FormModal>
        </Page>
    );
}
