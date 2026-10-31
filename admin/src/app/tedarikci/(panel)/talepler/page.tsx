"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, FormModal, Notice, Page, QueryView, Stats, StatusBadge } from "@/components/ui/kit";
import { dateTime, kurus } from "@/lib/format";
import { BUYER_TYPE, JOB_STATUS, OFFER_STATUS, REQUEST_STATUS } from "@/components/market/labels";
import { distance, feeText } from "@/components/market/request-text";
import type { MpSupplierRequest } from "@/lib/types";

/** Gelen talepler (FAZ M6, K9/K10): maskeli önizleme; kabulde ücret düşer ve alıcının iletişim bilgisi açılır. */
export default function SupplierRequestsPage() {
    const q = useApi(["market-requests"], api.market.requests);
    const act = useAction();
    const router = useRouter();
    const [pick, setPick] = useState<MpSupplierRequest | null>(null);
    return (
        <Page title="Talepler" description="Hizmet alanınızdaki sakin ve site taleplerinin önizlemesi; kabul ettiğinizde alıcının iletişim bilgisi açılır">
            <ActionFeedback action={act} />
            <QueryView q={q} isEmpty={() => false}>
                {(d) => (
                    <>
                        <Stats items={[
                            { label: "Bakiye", value: kurus(d.balance_kurus), tone: "blue" },
                            { label: "Bu dönem kalan dahil talep", value: d.period_included_left },
                            { label: "Bekleyen talep", value: d.data.filter((r) => !r.accepted_at && r.status === "OPEN").length },
                        ]} />
                        {d.account_status !== "APPROVED" && (
                            <Notice tone="amber">Hesabınız onaylanmadan talep kabul edemezsiniz.</Notice>
                        )}
                        {d.data.length === 0 && (
                            <Card title="Henüz talep yok">
                                <p className="text-sm text-gray-600">
                                    Yayındaki işletmelerinizin kategorisinde ve hizmet alanında yeni bir talep açıldığında burada görünür ve size bildirilir.
                                </p>
                            </Card>
                        )}
                        <div className="grid gap-3 lg:grid-cols-2">
                            {d.data.map((r) => (
                                <div key={r.id} className="rounded-xl border border-gray-200 bg-white p-4 text-sm shadow-sm dark:border-gray-700 dark:bg-gray-800">
                                    <div className="flex flex-wrap items-center gap-2">
                                        <span className="font-semibold">{r.category_name}</span>
                                        <StatusBadge value={r.status} map={REQUEST_STATUS} />
                                        {r.direct && <Badge tone="purple">Size özel</Badge>}
                                        {r.accepted_at && <Badge tone="green">Kabul ettiniz</Badge>}
                                        {r.offer_status && <StatusBadge value={r.offer_status} map={OFFER_STATUS} />}
                                        {r.job_status && <StatusBadge value={r.job_status} map={JOB_STATUS} />}
                                    </div>
                                    <p className="mt-1 text-gray-500">
                                        {r.district} / {r.city}{distance(r.distance_m) && <> · {distance(r.distance_m)}</>} · {BUYER_TYPE[r.buyer_type]} · şubeniz: {r.business_name}
                                    </p>
                                    <p className="mt-2 whitespace-pre-wrap">{r.description}</p>
                                    <p className="mt-2 text-xs text-gray-500">
                                        {r.preferred_time && <>Zaman: {r.preferred_time} · </>}
                                        {r.photo_count > 0 && <>{r.photo_count} fotoğraf · </>}
                                        {r.phone_hidden && <>telefonunu gizledi (mesajla ulaşılır) · </>}
                                        kabul {r.accepted_count}/{r.max_accepts} · son {dateTime(r.expires_at)}
                                    </p>
                                    <div className="mt-3 flex flex-wrap items-center gap-2">
                                        <span className="text-sm font-medium">{feeText(r)}</span>
                                        {r.accepted_at ? (
                                            <Link href={`/tedarikci/talepler/${r.id}`} className="text-sm text-primary hover:underline">Teklif, yazışma ve iletişim →</Link>
                                        ) : r.status === "OPEN" ? (
                                            r.can_afford ? (
                                                <Button size="sm" disabled={act.pending || d.account_status !== "APPROVED"} onClick={() => setPick(r)}>Kabul et</Button>
                                            ) : (
                                                <Link href="/tedarikci/bakiye" className="text-sm text-red-600 hover:underline">Bakiye yetersiz — bakiye yükle →</Link>
                                            )
                                        ) : (
                                            <Link href={`/tedarikci/talepler/${r.id}`} className="text-sm text-primary hover:underline">Önizleme →</Link>
                                        )}
                                    </div>
                                </div>
                            ))}
                        </div>
                    </>
                )}
            </QueryView>
            {pick && (
                <FormModal open title="Talebi kabul et" submitLabel="Kabul et" pending={act.pending} error={act.error} onClose={() => setPick(null)}
                    onSubmit={async () => {
                        const r = await act.run(() => api.market.acceptRequest(pick.id), { invalidate: ["market-requests", "market-wallet"] });
                        if (r) router.push(`/tedarikci/talepler/${pick.id}`);
                    }}>
                    <p className="text-sm">
                        {pick.category_name} — {pick.district} / {pick.city}.{" "}
                        {pick.uses_included
                            ? "Kabul, paketinizdeki dönemlik talep hakkından düşer."
                            : <>Kabul ücreti <strong>{kurus(pick.fee_kurus)}</strong> bakiyenizden hemen düşer.</>}
                    </p>
                    <p className="text-sm text-gray-600">
                        Kabul ettiğinizde alıcının adı, (gizlemediyse) telefonu ve site adresi açılır. Ücret, alıcıyla anlaşıp anlaşmamanızdan
                        bağımsızdır.
                    </p>
                </FormModal>
            )}
        </Page>
    );
}
