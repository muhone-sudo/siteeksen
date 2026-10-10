"use client";

// Banka ekstresi mutabakatı (059, Apsiyon BUG-12): bankadan indirilen CSV/Excel yüklenir,
// gelen hareketler onay bekleyen ödeme bildirimleriyle eşleştirilir; yönetici satır satır onaylar.

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Input, Notice, QueryView, Select, Table } from "@/components/ui/kit";
import { date, dateTime, kurus } from "@/lib/format";
import type { BankLine } from "@/lib/types";

const STATUS: Record<BankLine["status"], { label: string; tone: "green" | "amber" | "red" | "blue" | undefined }> = {
    SUGGESTED: { label: "Önerildi", tone: "blue" },
    AMBIGUOUS: { label: "Birden çok aday", tone: "amber" },
    UNMATCHED: { label: "Eşleşmedi", tone: "amber" },
    OUTGOING: { label: "Giden", tone: undefined },
    DUPLICATE: { label: "Mükerrer", tone: undefined },
    CONFIRMED: { label: "Onaylandı", tone: "green" },
    IGNORED: { label: "Yok sayıldı", tone: undefined },
};

export function BankStatementCard() {
    const imports = useApi(["bank-imports"], api.finance.bankImports);
    const [selected, setSelected] = useState<string>("");
    const detail = useApi(["bank-imports", selected], () => api.finance.bankImport(selected), !!selected);
    const pending = useApi(["payments", "pending"], api.finance.pendingPayments);
    const act = useAction();
    const { canWrite } = useRoles();
    const [file, setFile] = useState<File | null>(null);
    const [pick, setPick] = useState<null | { line: BankLine; payment_id: string }>(null);
    const [ignore, setIgnore] = useState<null | { line: BankLine; note: string }>(null);

    return (
        <>
            <ActionFeedback action={act} />
            {canWrite && (
                <Card title="Ekstre yükle">
                    <p className="mb-2 text-sm text-gray-600">Bankanın internet şubesinden indirdiğiniz hesap hareketlerini CSV ya da Excel (.xlsx) olarak yükleyin. Tarih ve tutar (ya da borç/alacak) sütunları tanınır; hiçbir ödeme kendiliğinden onaylanmaz.</p>
                    <div className="flex flex-wrap items-center gap-2">
                        <input type="file" accept=".csv,.xlsx,.txt" onChange={(e) => setFile(e.target.files?.[0] ?? null)} className="text-sm" />
                        <Button disabled={!file || act.pending} onClick={async () => {
                            if (!file) return;
                            const fd = new FormData();
                            fd.append("file", file);
                            const r = await act.run(() => api.finance.uploadBankStatement(fd), { invalidate: ["bank-imports"], success: "Ekstre yüklendi" });
                            if (r) setSelected(r.import.id);
                        }}>Yükle</Button>
                    </div>
                </Card>
            )}
            <Card padded={false} title="Yüklenen ekstreler">
                <QueryView q={imports} empty="Henüz ekstre yüklenmedi">
                    {(d) => (
                        <Table rows={d.data} rowKey={(x) => x.id} columns={[
                            { header: "Dosya", cell: (x) => x.file_name },
                            { header: "Yükleme", cell: (x) => dateTime(x.created_at) },
                            { header: "Hareket", cell: (x) => x.row_count },
                            { header: "Durum", cell: (x) => Object.entries(x.counts).map(([k, n]) => `${STATUS[k as BankLine["status"]]?.label ?? k}: ${n}`).join(" · ") },
                            { header: "", cell: (x) => <Button size="sm" variant={selected === x.id ? "primary" : "secondary"} onClick={() => setSelected(x.id)}>Aç</Button> },
                        ]} />
                    )}
                </QueryView>
            </Card>
            {selected && (
                <Card padded={false} title="Hareketler">
                    <QueryView q={detail}>
                        {(d) => (
                            <Table rows={d.lines ?? []} rowKey={(l) => l.id} columns={[
                                { header: "Satır", cell: (l) => l.line_no },
                                { header: "Tarih", cell: (l) => date(l.date) },
                                { header: "Tutar", cell: (l) => <b className={l.amount_kurus < 0 ? "text-red-600" : ""}>{kurus(l.amount_kurus)}</b> },
                                { header: "Açıklama", cell: (l) => <>{l.description}{l.reference && <div className="font-mono text-xs text-gray-500">{l.reference}</div>}</> },
                                { header: "Durum", cell: (l) => <><Badge tone={STATUS[l.status].tone}>{STATUS[l.status].label}</Badge>{l.note && <div className="text-xs text-gray-500">{l.note}</div>}</> },
                                { header: "Ödeyen", cell: (l) => (l.payer ? `${l.payer}${l.unit ? ` · ${l.unit}` : ""}` : "—") },
                                { header: "", cell: (l) => canWrite && ["SUGGESTED", "AMBIGUOUS", "UNMATCHED"].includes(l.status) ? (
                                    <div className="flex gap-1">
                                        {l.status === "SUGGESTED"
                                            ? <Button size="sm" disabled={act.pending} onClick={() => act.run(() => api.finance.confirmBankLine(l.id), { invalidate: ["bank-imports", "payments", "ledger", "debtors"], success: "Ödeme onaylandı ve borçtan düşüldü" })}>Onayla</Button>
                                            : <Button size="sm" variant="secondary" onClick={() => setPick({ line: l, payment_id: "" })}>Ödeme seç</Button>}
                                        <Button size="sm" variant="ghost" onClick={() => setIgnore({ line: l, note: "" })}>Yok say</Button>
                                    </div>
                                ) : null },
                            ]} />
                        )}
                    </QueryView>
                </Card>
            )}

            <FormModal open={!!pick} onClose={() => setPick(null)} title="Ödeme bildirimiyle eşleştir" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!pick) return;
                    const r = await act.run(() => api.finance.confirmBankLine(pick.line.id, pick.payment_id), { invalidate: ["bank-imports", "payments", "ledger", "debtors"], success: "Ödeme onaylandı ve borçtan düşüldü" });
                    if (r) setPick(null);
                }}>
                {pick && (
                    <>
                        <Notice tone="blue">Hareket: {date(pick.line.date)} · {kurus(pick.line.amount_kurus)} · {pick.line.description}. Yalnızca aynı tutardaki ödeme onaylanabilir.</Notice>
                        <Field label="Onay bekleyen ödeme" required>
                            <Select required value={pick.payment_id} onChange={(e) => setPick({ ...pick, payment_id: e.target.value })}
                                options={(pending.data?.data ?? []).filter((p) => Math.round(p.amount * 100) === pick.line.amount_kurus)
                                    .map((p) => ({ value: p.id, label: `${p.name} · ${p.unit} · ${p.value_date ? date(p.value_date) : ""} · ${p.payer_reference ?? ""}` }))}
                                placeholder="Seçin" />
                        </Field>
                    </>
                )}
            </FormModal>
            <FormModal open={!!ignore} onClose={() => setIgnore(null)} title="Hareketi yok say" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!ignore) return;
                    const r = await act.run(() => api.finance.ignoreBankLine(ignore.line.id, ignore.note), { invalidate: ["bank-imports"], success: "Satır yok sayıldı" });
                    if (r) setIgnore(null);
                }}>
                {ignore && <Field label="Gerekçe" required hint="Ör. kira geliri; ayrıca gelir olarak kaydedildi"><Input required value={ignore.note} onChange={(e) => setIgnore({ ...ignore, note: e.target.value })} /></Field>}
            </FormModal>
        </>
    );
}
