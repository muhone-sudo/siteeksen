"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Button, Card, Field, FormModal, Input, Notice, Page, QueryView, StatusBadge, Table, Tabs, Textarea } from "@/components/ui/kit";
import { date, dateTime, tl } from "@/lib/format";
import { PAYMENT_STATUS } from "@/lib/labels";
import type { LedgerEntry, Payment } from "@/lib/types";

/**
 * Tahsilat ve borçlar.
 *
 * Ödeme sağlayıcısı entegrasyonu YOKTUR: sakinin başlattığı ödeme "onay
 * bekliyor" olarak kaydedilir; havale/EFT'yi gören yönetici dekont
 * numarasıyla onaylar. Onay, borcu tahakkuktan düşer.
 */
export default function AccountingPage() {
    const [tab, setTab] = useState<"pending" | "all" | "debtors" | "ledger">("pending");
    const ledger = useApi(["ledger"], api.finance.ledger, tab === "ledger");
    const [reversing, setReversing] = useState<Payment | null>(null);
    const [reverseReason, setReverseReason] = useState("");
    const pending = useApi(["payments", "pending"], api.finance.pendingPayments, tab === "pending");
    const [allLimit, setAllLimit] = useState(50);
    const all = useApi(["payments", "all", allLimit], () => api.finance.payments(allLimit), tab === "all");
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
        { header: "Tarih", cell: (p: Payment) => <>{dateTime(p.created_at)}{p.value_date && <div className="text-xs text-gray-500">Havale günü: {date(p.value_date)}</div>}{p.payer_reference && <div className="text-xs text-gray-500">Açıklama: {p.payer_reference}</div>}</> },
        ...(withActions && canWrite
            ? [{
                header: "",
                cell: (p: Payment) => (
                    <div className="flex gap-1">
                        {p.status === "COMPLETED" && <Button size="sm" variant="ghost" onClick={() => { setReverseReason(""); setReversing(p); }}>Ters kayıt</Button>}
                        {p.status === "PENDING" && <Button size="sm" onClick={() => { setReference(""); setConfirming(p); }}>Onayla</Button>}
                        {p.status === "PENDING" && <Button size="sm" variant="danger" disabled={act.pending}
                            onClick={() => act.run(() => api.finance.rejectPayment(p.id), { invalidate: ["payments", "debtors", "dashboard"], success: "Ödeme reddedildi; borç değişmedi" })}>
                            Reddet
                        </Button>}
                    </div>
                ),
            }]
            : []),
    ];

    return (
        <Page title="Tahsilat ve borçlar" description="Onay bekleyen ödemeler, ödeme geçmişi ve borçlu listesi.">
            <Notice tone="amber">
                Havale/EFT ödemesi, yönetici banka hareketini gördükten sonra onayladığında borçtan düşer; gecikme tazminatı sakinin bildirdiği havale gününde durur. Tahsilat kayıtları silinemez, düzeltme ters kayıtla yapılır.
            </Notice>
            <ActionFeedback action={act} />
            <Tabs tabs={[{ id: "pending", label: "Onay bekleyen" }, { id: "all", label: "Tüm ödemeler" }, { id: "debtors", label: "Borçlular" }, { id: "ledger", label: "Tahsilat defteri" }]} value={tab} onChange={setTab} />
            <Card padded={false}>
                {tab === "pending" && (
                    <QueryView q={pending} empty="Onay bekleyen ödeme yok">
                        {(d) => <Table rows={d.data} rowKey={(p) => p.id} columns={paymentColumns(true)} />}
                    </QueryView>
                )}
                {tab === "all" && (
                    <QueryView q={all} empty="Ödeme kaydı yok">
                        {(d) => (
                            <>
                                <Table rows={d.data} rowKey={(p) => p.id} columns={paymentColumns(true)} />
                                {d.total > d.data.length && (
                                    <div className="flex items-center justify-between gap-3 border-t p-3 text-sm text-gray-600">
                                        <span>Toplam {d.total} ödemenin en yeni {d.data.length} tanesi gösteriliyor.</span>
                                        {allLimit < 500 ? (
                                            <Button size="sm" variant="secondary" onClick={() => setAllLimit(Math.min(allLimit + 100, 500))}>Daha eskileri göster</Button>
                                        ) : (
                                            <span>Tek seferde en çok 500 kayıt gösterilir.</span>
                                        )}
                                    </div>
                                )}
                            </>
                        )}
                    </QueryView>
                )}
                {tab === "ledger" && (
                    <>
                        <div className="flex flex-wrap items-center justify-between gap-2 border-b p-3 text-sm text-gray-600">
                            <span>Her onay ve ters kayıt, bir öncekinin SHA-256 özetine bağlı olarak yazılır; kayıt silinemez ve değiştirilemez.</span>
                            <Button size="sm" variant="secondary" disabled={act.pending} onClick={() => act.run(api.finance.verifyLedger, {
                                success: (v) => (v.valid ? `Zincir geçerli: ${v.entries} kayıt, değiştirilmemiş` : `UYARI: zincir bozuk (sıra ${v.first_invalid_seq}): ${v.reason}`),
                            })}>Zinciri doğrula</Button>
                        </div>
                        <QueryView q={ledger} empty="Defter kaydı yok">
                            {(d) => (
                                <Table rows={d.data} rowKey={(x) => String(x.seq)} columns={[
                                    { header: "Sıra", cell: (x: LedgerEntry) => x.seq },
                                    { header: "İşlem", cell: (x: LedgerEntry) => (x.entry_type === "PAYMENT_CONFIRMED" ? "Tahsilat onayı" : x.entry_type === "PAYMENT_REVERSED" ? "Ters kayıt" : "Alacak dekontu") },
                                    { header: "Tutar", cell: (x: LedgerEntry) => <span className={x.amount_kurus < 0 ? "text-red-600" : ""}>{tl(x.amount_kurus / 100)}</span> },
                                    { header: "Açıklama", cell: (x: LedgerEntry) => String((x.detail.reason ?? x.detail.reference ?? "") || "—") },
                                    { header: "Kaydeden / zaman", cell: (x: LedgerEntry) => <>{x.created_by_name || "—"}<div className="text-xs text-gray-500">{dateTime(x.created_at)}</div></> },
                                    { header: "Özet", cell: (x: LedgerEntry) => <span className="font-mono text-xs">{x.entry_hash.slice(0, 12)}…</span> },
                                ]} />
                            )}
                        </QueryView>
                    </>
                )}
                {tab === "debtors" && (
                    <QueryView q={debtors} empty="Borçlu yok">
                        {(d) => (
                            <Table
                                rows={d.data}
                                rowKey={(x) => x.unit_id}
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
            <FormModal open={!!reversing} onClose={() => setReversing(null)} title="Ödemenin ters kaydı" submitLabel="Ters kaydı yap" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!reversing) return;
                    const r = await act.run(() => api.finance.reversePayment(reversing.id, reverseReason), { invalidate: ["payments", "debtors", "assessments", "dashboard", "ledger"], success: (x) => x.message ?? "Ters kayıt yapıldı" });
                    if (r) setReversing(null);
                }}>
                <p className="text-sm">{reversing?.name} — {reversing?.unit} — <b>{tl(reversing?.amount)}</b></p>
                <Notice tone="amber">Ödeme SİLİNMEZ: durumu &quot;ters kayıt&quot; olur, borç yeniden açılır ve işlem gerekçesiyle tahsilat defterine yazılır. Sakinler zinciri doğrulayabilir.</Notice>
                <Field label="Gerekçe" required><Textarea required minLength={5} value={reverseReason} onChange={(e) => setReverseReason(e.target.value)} /></Field>
            </FormModal>
        </Page>
    );
}
