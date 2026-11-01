"use client";

import { useState } from "react";
import { useParams } from "next/navigation";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Notice, Page, QueryView, StatusBadge, Table, Textarea } from "@/components/ui/kit";
import { dateTime, kurus } from "@/lib/format";
import { ACCOUNT_STATUS, BUSINESS_STATUS, DOC_STATUS, DOC_TYPE } from "@/components/market/labels";
import type { MpNotifyResult } from "@/lib/types";
import { FieldGroup } from "@/components/market/field-group";

type Decision = "reject" | "suspend" | "close";

/** Tedarikçi hesabı incelemesi (FAZ M4.1): belgeleri aç, onayla / gerekçeyle reddet / askıya al. */
export default function PlatformAccountPage() {
    const { id } = useParams<{ id: string }>();
    const q = useApi(["mp-account", id], () => api.market.platform.account(id));
    const act = useAction();
    const [dec, setDec] = useState<{ kind: Decision; reason: string; docs: string[] } | null>(null);
    const note = (r: { notification: MpNotifyResult }) => `Tedarikçiye bildirim: uygulama içi ${r.notification.in_app}${r.notification.email ? `, e-posta ${r.notification.email}` : ""}`;
    const run = (action: "approve" | "reject" | "suspend" | "reinstate", b = {}) =>
        act.run(() => api.market.platform.reviewAccount(id, action, b), { invalidate: ["mp-account", "mp-accounts"], success: note });
    return (
        <QueryView q={q}>
            {({ account: a, documents, businesses }) => (
                <Page title={a.trade_name || "(unvan girilmemiş)"} description={`${a.owner_name} · ${a.owner_phone}${a.owner_email ? ` · ${a.owner_email}` : ""}`}
                    actions={<StatusBadge value={a.status} map={ACCOUNT_STATUS} />}>
                    <ActionFeedback action={act} />
                    <Card title="Hesap">
                        <div className="grid gap-2 text-sm sm:grid-cols-3">
                            <p>Vergi no: <span className="font-mono">{a.tax_number || "—"}</span></p>
                            <p>Vergi dairesi: {a.tax_office || "—"}</p>
                            <p>Paket: <Badge tone="blue">{a.package.name}</Badge> · bakiye {kurus(a.balance_kurus)}</p>
                            <p>Sözleşme onayı: {dateTime(a.terms_accepted_at)}</p>
                            <p>Son inceleme: {dateTime(a.reviewed_at)}</p>
                        </div>
                        {a.status_reason && <Notice tone="amber" title="Son gerekçe">{a.status_reason}</Notice>}
                        <div className="mt-4 flex flex-wrap gap-2">
                            {a.status === "REVIEW" && <>
                                <Button disabled={act.pending} onClick={() => run("approve")}>Onayla</Button>
                                <Button variant="danger" disabled={act.pending} onClick={() => setDec({ kind: "reject", reason: "", docs: [] })}>Reddet</Button>
                            </>}
                            {a.status === "APPROVED" && <Button variant="danger" disabled={act.pending} onClick={() => setDec({ kind: "suspend", reason: "", docs: [] })}>Askıya al</Button>}
                            {a.status === "SUSPENDED" && <Button disabled={act.pending} onClick={() => run("reinstate")}>Yeniden etkinleştir</Button>}
                            {a.status !== "CLOSED" && <Button variant="secondary" disabled={act.pending} onClick={() => setDec({ kind: "close", reason: "", docs: [] })}>Üyeliği kapat</Button>}
                        </div>
                    </Card>
                    <Card title="Belgeler" padded={false}>
                        <Table rows={documents} rowKey={(d) => d.id} columns={[
                            { header: "Tür", cell: (d) => DOC_TYPE[d.doc_type] ?? d.doc_type },
                            { header: "Dosya", cell: (d) => <span className="break-all">{d.file_name}</span> },
                            { header: "Durum", cell: (d) => <div><StatusBadge value={d.status} map={DOC_STATUS} />{d.review_note && <p className="text-xs text-gray-500">{d.review_note}</p>}</div> },
                            { header: "Yüklendi", cell: (d) => dateTime(d.uploaded_at) },
                            { header: "", cell: (d) => <Button size="sm" variant="ghost" onClick={() => act.run(() => api.market.platform.downloadDocument(d.id, d.file_name))}>Aç</Button> },
                        ]} />
                    </Card>
                    <Card title="İşletmeler" padded={false}>
                        <Table rows={businesses} rowKey={(b) => b.id} columns={[
                            { header: "İşletme", cell: (b) => b.name },
                            { header: "Yer", cell: (b) => `${b.district} / ${b.city}` },
                            { header: "Durum", cell: (b) => <StatusBadge value={b.status} map={BUSINESS_STATUS} /> },
                        ]} />
                    </Card>
                    {dec && (
                        <FormModal open title={dec.kind === "reject" ? "Hesabı reddet" : dec.kind === "suspend" ? "Hesabı askıya al" : "Üyeliği kapat"}
                            onClose={() => setDec(null)} pending={act.pending} error={act.error}
                            submitLabel={dec.kind === "reject" ? "Reddet" : dec.kind === "suspend" ? "Askıya al" : "Kapat"}
                            onSubmit={async () => {
                                const r = dec.kind === "close"
                                    ? await act.run(() => api.market.platform.closeAccount(id, { reason: dec.reason }),
                                        { invalidate: ["mp-account", "mp-accounts", "mp-card-refunds"], success: (x) => "Üyelik kapatıldı."
                                            + (x.refund.card_refund_kurus ? ` ${kurus(x.refund.card_refund_kurus)} karta iade ediliyor (${x.refund.card_refunds} yükleme).` : "")
                                            + (x.refund.expired_kurus ? ` ${kurus(x.refund.expired_kurus)} 365 günden eski yüklemelerden kaldığı için iade edilmedi.` : "") })
                                    : await run(dec.kind, { reason: dec.reason, reject_document_ids: dec.docs });
                                if (r) setDec(null);
                            }}>
                            {dec.kind === "close" && a.balance_kurus > 0 && (
                                <Notice tone="amber">Kalan bakiye {kurus(a.balance_kurus)}. Son 365 günde kartla yüklenen kısmı en yeni yüklemeden başlanarak
                                    kendiliğinden karta iade edilir; 365 günden eski yüklemelerden kalan kısım bakiye koşullarının 3. maddesi gereği iade edilmez.
                                    İadelerin durumu &quot;Karta iadeler&quot; ekranındadır.</Notice>
                            )}
                            <Field label="Gerekçe (tedarikçiye gösterilir)" required><Textarea value={dec.reason} onChange={(e) => setDec({ ...dec, reason: e.target.value })} /></Field>
                            {dec.kind === "reject" && documents.length > 0 && (
                                <FieldGroup label="Reddedilen belgeler (yeniden yüklenmesi gerekenler)">
                                    <div className="space-y-1">
                                        {documents.filter((d) => d.status !== "REJECTED").map((d) => (
                                            <label key={d.id} className="flex items-center gap-2 text-sm">
                                                <input type="checkbox" checked={dec.docs.includes(d.id)}
                                                    onChange={() => setDec({ ...dec, docs: dec.docs.includes(d.id) ? dec.docs.filter((x) => x !== d.id) : [...dec.docs, d.id] })} />
                                                {DOC_TYPE[d.doc_type]} — {d.file_name}
                                            </label>
                                        ))}
                                    </div>
                                </FieldGroup>
                            )}
                        </FormModal>
                    )}
                </Page>
            )}
        </QueryView>
    );
}
