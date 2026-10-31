"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Button, Card, Field, Input, Notice, QueryView, Select, StatusBadge, Textarea } from "@/components/ui/kit";
import { date, dateTime, kurus } from "@/lib/format";
import { DISPUTE_REASON, DISPUTE_STATUS, JOB_STATUS, OFFER_STATUS } from "@/components/market/labels";
import type { MpDeal, MpSupplierRequest } from "@/lib/types";

/** Kabul edilmiş talepte tedarikçinin teklifi, işi, yazışması ve geçersiz talep bildirimi (FAZ M7). */
export function DealPanel({ r }: { r: MpSupplierRequest }) {
    const deal = useApi(["market-deal", r.id], () => api.market.deal(r.id));
    return (
        <QueryView q={deal} isEmpty={() => false}>
            {(d) => (
                <>
                    <OfferCard r={r} d={d} />
                    {d.job && <JobCard d={d} />}
                    <Messages id={r.id} />
                    <DisputeCard r={r} d={d} />
                </>
            )}
        </QueryView>
    );
}

function OfferCard({ r, d }: { r: MpSupplierRequest; d: MpDeal }) {
    const act = useAction();
    const active = d.offers.find((o) => o.status === "ACTIVE");
    const [f, setF] = useState({ amount: active ? String(active.amount_kurus / 100) : "", description: active?.description ?? "", valid_until: active?.valid_until ?? "" });
    const open = r.status !== "CLOSED" && r.status !== "CANCELLED";
    const save = () => act.run(() => api.market.saveOffer(r.id, {
        amount_kurus: Math.round(Number(f.amount.replace(",", ".")) * 100), description: f.description, valid_until: f.valid_until,
    }), { invalidate: ["market-deal", "market-requests"], success: active ? "Teklif güncellendi" : "Teklif gönderildi" });
    return (
        <Card title="Teklifiniz">
            <ActionFeedback action={act} />
            <div className="space-y-3 text-sm">
                {d.offers.map((o) => (
                    <div key={o.id} className="flex flex-wrap items-center gap-2">
                        <StatusBadge value={o.status} map={OFFER_STATUS} />
                        <strong>{kurus(o.amount_kurus)}</strong>
                        <span className="text-gray-500">geçerli {date(o.valid_until)} · {dateTime(o.updated_at)}</span>
                        {o.status === "ACTIVE" && (
                            <Button size="sm" variant="ghost" disabled={act.pending}
                                onClick={() => act.run(() => api.market.withdrawOffer(o.id), { invalidate: ["market-deal", "market-requests"], success: "Teklif geri çekildi" })}>
                                Geri çek
                            </Button>
                        )}
                    </div>
                ))}
                {open ? (
                    <div className="grid gap-3 sm:grid-cols-3">
                        <Field label="Tutar (TL)" required><Input inputMode="decimal" value={f.amount} onChange={(e) => setF({ ...f, amount: e.target.value })} /></Field>
                        <Field label="Geçerlilik" required><Input type="date" value={f.valid_until} onChange={(e) => setF({ ...f, valid_until: e.target.value })} /></Field>
                        <div className="sm:col-span-3">
                            <Field label="Açıklama (işin kapsamı, malzeme, süre)" required>
                                <Textarea value={f.description} onChange={(e) => setF({ ...f, description: e.target.value })} />
                            </Field>
                        </div>
                        <div><Button disabled={act.pending || !(Number(f.amount.replace(",", ".")) > 0) || !f.description.trim() || !f.valid_until} onClick={() => void save()}>
                            {active ? "Teklifi güncelle" : "Teklif gönder"}
                        </Button></div>
                    </div>
                ) : (
                    <p className="text-gray-500">Talep kapandı; yeni teklif verilemez.</p>
                )}
            </div>
        </Card>
    );
}

function JobCard({ d }: { d: MpDeal }) {
    const act = useAction();
    const j = d.job!;
    return (
        <Card title="İş">
            <ActionFeedback action={act} />
            <div className="space-y-2 text-sm">
                <p><StatusBadge value={j.status} map={JOB_STATUS} /> {kurus(j.amount_kurus)} · {j.business_name}</p>
                {j.status === "ACTIVE" && (
                    <Button disabled={act.pending} onClick={() => act.run(() => api.market.jobDone(j.id), { invalidate: ["market-deal", "market-requests"], success: "Alıcıya iş tamamlandı bildirildi" })}>
                        İş tamamlandı
                    </Button>
                )}
                {j.status === "DONE_CLAIMED" && <Notice tone="amber">Alıcının onayı bekleniyor; süresinde yanıt vermezse iş tamamlanmış sayılır.</Notice>}
                {j.status === "DISPUTED" && <Notice tone="red" title="Alıcının itirazı">{j.dispute_note}</Notice>}
                {j.review && (
                    <p>Alıcının puanı: <strong>{j.review.rating}/5</strong> {j.review.comment && <>— “{j.review.comment}”</>} (Puanlar sayfasından yanıtlayabilirsiniz)</p>
                )}
            </div>
        </Card>
    );
}

function Messages({ id }: { id: string }) {
    const q = useApi(["market-messages", id], () => api.market.messages(id));
    const act = useAction();
    const [body, setBody] = useState("");
    return (
        <Card title="Alıcıyla yazışma">
            <ActionFeedback action={act} />
            <QueryView q={q} isEmpty={() => false}>
                {(m) => (
                    <div className="space-y-2 text-sm">
                        {m.data.length === 0 && <p className="text-gray-500">Henüz mesaj yok. Daire numarasını ve uygun zamanı yazışarak netleştirin.</p>}
                        {[...m.data].reverse().map((x) => (
                            <div key={x.id} className={`max-w-[80%] rounded-lg px-3 py-2 ${x.sender_side === "SUPPLIER" ? "ml-auto bg-primary/10" : "bg-gray-100 dark:bg-gray-700"}`}>
                                <p className="whitespace-pre-wrap">{x.body}</p>
                                <p className="text-xs text-gray-500">{x.sender_side === "SUPPLIER" ? "Siz" : "Alıcı"} · {dateTime(x.created_at)}</p>
                            </div>
                        ))}
                    </div>
                )}
            </QueryView>
            <div className="mt-3 flex gap-2">
                <Input value={body} placeholder="Mesajınız" onChange={(e) => setBody(e.target.value)} />
                <Button disabled={act.pending || !body.trim()} onClick={() => void act.run(() => api.market.sendMessage(id, body), { invalidate: ["market-messages"] })
                    .then((r) => { if (r) setBody(""); })}>Gönder</Button>
            </div>
        </Card>
    );
}

function DisputeCard({ r, d }: { r: MpSupplierRequest; d: MpDeal }) {
    const act = useAction();
    const [f, setF] = useState({ reason_code: "UNREACHABLE", note: "" });
    if (d.dispute) {
        const x = d.dispute;
        return (
            <Card title="Geçersiz talep bildiriminiz">
                <div className="space-y-1 text-sm">
                    <p><StatusBadge value={x.status} map={DISPUTE_STATUS} /> {DISPUTE_REASON[x.reason_code]} · {dateTime(x.created_at)}</p>
                    <p className="text-gray-600">{x.note}</p>
                    {x.decision_note && <p>Platform kararı: {x.decision_note}</p>}
                </div>
            </Card>
        );
    }
    return (
        <Card title="Talep geçersiz mi?">
            <ActionFeedback action={act} />
            <div className="space-y-3 text-sm">
                <p className="text-gray-600">
                    Talep sahte, yanlış kategoride ya da alıcıya ulaşılamıyorsa bildirin. SiteEksen inceler; onaylarsa kabul ücreti
                    ({r.uses_included ? "paket talep hakkı" : kurus(r.fee_kurus)}) iade edilir.
                </p>
                <div className="grid gap-3 sm:grid-cols-3">
                    <Field label="Neden">
                        <Select value={f.reason_code} onChange={(e) => setF({ ...f, reason_code: e.target.value })}
                            options={Object.entries(DISPUTE_REASON).map(([value, label]) => ({ value, label }))} />
                    </Field>
                    <div className="sm:col-span-2">
                        <Field label="Açıklama (en az 10 karakter)"><Textarea value={f.note} onChange={(e) => setF({ ...f, note: e.target.value })} /></Field>
                    </div>
                </div>
                <Button variant="secondary" disabled={act.pending || f.note.trim().length < 10}
                    onClick={() => act.run(() => api.market.openDispute(r.id, f), { invalidate: ["market-deal"], success: "Bildiriminiz platforma iletildi" })}>
                    Platforma bildir
                </Button>
            </div>
        </Card>
    );
}
