"use client";

import { useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Input, Notice, Page, QueryView, Select, StatusBadge, Table } from "@/components/ui/kit";
import { date, dateTime, kurus } from "@/lib/format";
import { JOB_STATUS, OFFER_STATUS, REQUEST_STATUS } from "@/components/market/labels";
import type { MpJob, MpOffer } from "@/lib/types";

const today = () => new Date().toLocaleDateString("sv-SE", { timeZone: "Europe/Istanbul" });

/** Site talebi: teklif karşılaştırma (kurul ve denetçi okur), seçim, iş, gidere/sözleşmeye çevirme (FAZ M10). */
export default function SiteMarketRequestPage() {
    const { id } = useParams<{ id: string }>();
    const { roles } = useRoles();
    const manager = roles.includes("MANAGER");
    const req = useApi(["mp-site-request", id], () => api.market.buyer.request(id));
    const offers = useApi(["mp-site-offers", id], () => api.market.buyer.offers(id));
    const job = useApi(["mp-site-job", id], () => api.market.buyer.job(id).catch(() => null));
    const act = useAction();
    const [pick, setPick] = useState<MpOffer | null>(null);
    const inv = ["mp-site-request", "mp-site-offers", "mp-site-job", "mp-site-requests"];
    return (
        <QueryView q={req}>
            {(r) => {
                const open = r.status !== "CLOSED" && r.status !== "CANCELLED";
                return (
                    <Page title={r.category_name} description={`Site adına talep · ${dateTime(r.created_at)}`}>
                        <p className="text-sm"><Link href="/dashboard/usta-hizmet" className="text-primary hover:underline">← Usta & Hizmet</Link></p>
                        <ActionFeedback action={act} />
                        <Card title="Talep">
                            <div className="space-y-1 text-sm">
                                <p><StatusBadge value={r.status} map={REQUEST_STATUS} /> kabul {r.accepted_count}/{r.max_accepts} · {r.dispatch_count} işletmeye gönderildi · son {dateTime(r.expires_at)}</p>
                                <p className="whitespace-pre-wrap">{r.description}</p>
                                {r.preferred_time && <p className="text-gray-600">Zaman: {r.preferred_time}</p>}
                            </div>
                        </Card>
                        <Card title="Teklif karşılaştırma" padded={false}>
                            <QueryView q={offers} empty={r.accepted_count ? "Kabul eden işletmelerden teklif bekleniyor" : "Talebi henüz kabul eden işletme yok"}>
                                {(d) => (
                                    <Table rows={d.data} rowKey={(o) => o.id} columns={[
                                        { header: "İşletme", cell: (o) => <span className="font-medium">{o.business_name}</span> },
                                        { header: "Tutar", cell: (o) => <strong>{kurus(o.amount_kurus)}</strong> },
                                        { header: "Kapsam", cell: (o) => <span className="text-sm">{o.description}</span> },
                                        { header: "Geçerlilik", cell: (o) => date(o.valid_until) },
                                        { header: "Puan", cell: (o) => o.rating_count ? `${((o.rating_sum ?? 0) / o.rating_count).toFixed(1)} (${o.rating_count})` : "—" },
                                        { header: "Tamamlanan iş", cell: (o) => o.completed_jobs ?? 0 },
                                        { header: "Telefon", cell: (o) => o.business_phone ?? "—" },
                                        { header: "", cell: (o) => o.status === "ACTIVE" && open && manager
                                            ? <Button size="sm" onClick={() => setPick(o)}>Seç</Button>
                                            : <StatusBadge value={o.status} map={OFFER_STATUS} /> },
                                    ]} />
                                )}
                            </QueryView>
                        </Card>
                        {open && manager && (
                            <div>
                                <Button variant="ghost" disabled={act.pending} onClick={() => {
                                    if (window.confirm("Teklif seçmeden talebi kapatıyorsunuz; yeni teklif gelmez.")) void act.run(() => api.market.buyer.close(id), { invalidate: inv, success: "Talep kapatıldı" });
                                }}>Teklif seçmeden kapat</Button>
                            </div>
                        )}
                        {job.data && <JobCard id={id} job={job.data} manager={manager} category={r.category_name} />}
                        {pick && (
                            <FormModal open title="Teklifi seç" submitLabel="Seç" pending={act.pending} error={act.error} onClose={() => setPick(null)}
                                onSubmit={async () => {
                                    const x = await act.run(() => api.market.buyer.select(id, pick.id), { invalidate: inv, success: "Teklif seçildi; işletmeye bildirildi" });
                                    if (x) setPick(null);
                                }}>
                                <p className="text-sm">{pick.business_name} — {kurus(pick.amount_kurus)}. Diğer teklifler reddedilir ve işletmelere bildirilir.</p>
                                <p className="text-sm text-gray-600">Seçimden sonra işi onay bekleyen gidere ya da sözleşmeye çevirebilirsiniz.</p>
                            </FormModal>
                        )}
                    </Page>
                );
            }}
        </QueryView>
    );
}

function JobCard({ id, job, manager, category }: { id: string; job: MpJob; manager: boolean; category: string }) {
    const act = useAction();
    const cats = useApi(["expense-categories"], api.expenses.categories, manager);
    const [exp, setExp] = useState<{ category_id: string; date: string } | null>(null);
    const [rev, setRev] = useState({ rating: "5", comment: "" });
    const inv = ["mp-site-job", "mp-site-request"];
    const vendor = job.vendor;
    const contractHref = `/dashboard/contracts?${new URLSearchParams({
        baslik: `Usta & Hizmet: ${category}`, taraf: vendor?.trade_name || job.business_name, tutar: String(job.amount_kurus / 100),
    })}`;
    return (
        <Card title="İş">
            <ActionFeedback action={act} />
            <div className="space-y-3 text-sm">
                <p><StatusBadge value={job.status} map={JOB_STATUS} /> {job.business_name} · {kurus(job.amount_kurus)}</p>
                {vendor && <p className="text-gray-600">Fatura bilgisi: {vendor.trade_name} · VKN/TCKN {vendor.tax_number} · {vendor.tax_office}</p>}
                {manager && (
                    <div className="flex flex-wrap gap-2">
                        <Button size="sm" variant="secondary" onClick={() => setExp({ category_id: "", date: today() })}>Onay bekleyen gider oluştur</Button>
                        <Link href={contractHref}><Button size="sm" variant="ghost">Sözleşme formunu doldur</Button></Link>
                    </div>
                )}
                {manager && (job.status === "DONE_CLAIMED" || job.status === "DISPUTED") && (
                    <div className="flex flex-wrap gap-2">
                        <Button size="sm" disabled={act.pending} onClick={() => act.run(() => api.market.buyer.confirm(id), { invalidate: inv, success: "İş onaylandı" })}>İş tamamlandı, onayla</Button>
                        {job.status === "DONE_CLAIMED" && (
                            <Button size="sm" variant="ghost" disabled={act.pending} onClick={() => {
                                const note = window.prompt("İtiraz gerekçesi");
                                if (note) void act.run(() => api.market.buyer.dispute(id, note), { invalidate: inv, success: "İtiraz iletildi" });
                            }}>İtiraz et</Button>
                        )}
                    </div>
                )}
                {job.status === "DISPUTED" && <Notice tone="red" title="İtiraz">{job.dispute_note}</Notice>}
                {job.review ? <p>Puan: {job.review.rating}/5 {job.review.comment}</p> : manager && job.status === "COMPLETED" && (
                    <div className="flex flex-wrap items-end gap-2">
                        <Field label="Puan"><Select value={rev.rating} onChange={(e) => setRev({ ...rev, rating: e.target.value })} options={["5", "4", "3", "2", "1"].map((v) => ({ value: v, label: v }))} /></Field>
                        <Field label="Yorum"><Input value={rev.comment} onChange={(e) => setRev({ ...rev, comment: e.target.value })} /></Field>
                        <Button size="sm" disabled={act.pending} onClick={() => act.run(() => api.market.buyer.review(id, Number(rev.rating), rev.comment), { invalidate: inv, success: "Puan verildi" })}>Puanı gönder</Button>
                    </div>
                )}
                {!manager && <Badge tone="gray">Salt okuma</Badge>}
            </div>
            {exp && (
                <FormModal open title="Onay bekleyen gider" submitLabel="Gideri oluştur" pending={act.pending} error={act.error} onClose={() => setExp(null)}
                    onSubmit={async () => {
                        const x = await act.run(() => api.expenses.create({
                            category_id: exp.category_id, description: `Usta & Hizmet: ${category} — ${vendor?.trade_name || job.business_name}`,
                            amount: job.amount_kurus / 100, expense_date: exp.date, is_invoiced: false,
                            invoice_reason: "Usta & Hizmet teklifi seçildi; fatura iş sonunda alınacak",
                            vendor_name: vendor?.trade_name || job.business_name, vendor_tax_id: vendor?.tax_number ?? "",
                            notes: `Usta & Hizmet talep ${id}`,
                        }), { invalidate: ["expenses"], success: (r) => r.note ?? "Gider oluşturuldu" });
                        if (x) setExp(null);
                    }}>
                    <Notice tone="blue">Faturasız gider onay bekler; kurul onayından sonra hesap verme belgelerine girer. Fatura gelince gider kaydına işlenir.</Notice>
                    <Field label="Gider kalemi" required>
                        <Select value={exp.category_id} onChange={(e) => setExp({ ...exp, category_id: e.target.value })}
                            options={[{ value: "", label: "Seçin" }, ...(cats.data?.data ?? []).map((c) => ({ value: c.id, label: c.name }))]} />
                    </Field>
                    <Field label="Gider tarihi" required><Input type="date" value={exp.date} onChange={(e) => setExp({ ...exp, date: e.target.value })} /></Field>
                    <p className="text-sm">Tutar {kurus(job.amount_kurus)} · {vendor?.trade_name || job.business_name}{vendor?.tax_number && <> · VKN {vendor.tax_number}</>}</p>
                </FormModal>
            )}
        </Card>
    );
}
