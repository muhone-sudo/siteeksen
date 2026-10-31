"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Notice, Page, QueryView, StatusBadge } from "@/components/ui/kit";
import { dateTime } from "@/lib/format";
import { BUYER_TYPE, REQUEST_STATUS } from "@/components/market/labels";
import { distance, feeText } from "@/components/market/request-text";
import { AuthPhoto } from "@/components/market/service-photo";
import { DealPanel } from "@/components/market/deal-panel";

/** Tek talep (FAZ M6): önizleme, fotoğraflar; kabul ettiyse alıcının iletişim bilgisi. */
export default function SupplierRequestPage() {
    const { id } = useParams<{ id: string }>();
    const q = useApi(["market-request", id], () => api.market.request(id));
    const act = useAction();
    return (
        <QueryView q={q}>
            {(r) => (
                <Page title={r.category_name} description={`${r.district} / ${r.city} · ${BUYER_TYPE[r.buyer_type]}`}>
                    <p className="text-sm"><Link href="/tedarikci/talepler" className="text-primary hover:underline">← Talepler</Link></p>
                    <ActionFeedback action={act} />
                    <Card title="Talep">
                        <div className="space-y-2 text-sm">
                            <p className="flex flex-wrap items-center gap-2">
                                <StatusBadge value={r.status} map={REQUEST_STATUS} />
                                {r.direct && <Badge tone="purple">Size özel</Badge>}
                                <span className="text-gray-500">kabul {r.accepted_count}/{r.max_accepts} · son {dateTime(r.expires_at)}</span>
                            </p>
                            <p className="whitespace-pre-wrap">{r.description}</p>
                            {r.preferred_time && <p className="text-gray-600">Zaman tercihi: {r.preferred_time}</p>}
                            <p className="text-gray-600">Şubeniz: {r.business_name}{distance(r.distance_m) && <> · uzaklık {distance(r.distance_m)}</>}</p>
                            <p className="font-medium">{feeText(r)}</p>
                        </div>
                        {r.photo_count > 0 && (
                            <div className="mt-3 flex flex-wrap gap-2">
                                {Array.from({ length: r.photo_count }, (_, n) => (
                                    <AuthPhoto key={n} path={`/market/supplier/requests/${r.id}/photos/${n}`} className="h-32 w-32 rounded object-cover" />
                                ))}
                            </div>
                        )}
                    </Card>
                    {r.contact ? (
                        <Card title="Alıcının iletişim bilgisi">
                            <dl className="grid gap-2 text-sm sm:grid-cols-2">
                                <div><dt className="text-gray-500">Ad</dt><dd className="font-medium">{r.contact.name}</dd></div>
                                <div><dt className="text-gray-500">Telefon</dt>
                                    <dd className="font-medium">{r.contact.phone ? <a href={`tel:${r.contact.phone}`} className="text-primary">{r.contact.phone}</a> : "Gizli — alıcıya mesajla ulaşın"}</dd></div>
                                <div><dt className="text-gray-500">Site</dt><dd>{r.contact.site_name}</dd></div>
                                <div><dt className="text-gray-500">Adres</dt><dd>{r.contact.site_address}</dd></div>
                            </dl>
                            <p className="mt-3 text-xs text-gray-500">Daire numarası alıcıyla yazışmada paylaşılır. Bu bilgiyi yalnız bu talep için kullanın.</p>
                        </Card>
                    ) : null}
                    {r.accepted_at ? <DealPanel r={r} /> : (
                        <Notice tone="blue">
                            Alıcının adı, telefonu ve adresi talebi kabul ettiğinizde açılır.{" "}
                            {r.status === "OPEN" && (
                                <Button size="sm" className="ml-2" disabled={act.pending || !r.can_afford}
                                    onClick={() => act.run(() => api.market.acceptRequest(r.id), { invalidate: ["market-request", "market-requests", "market-wallet"], success: (x) => x.message })}>
                                    Kabul et
                                </Button>
                            )}
                            {r.status === "OPEN" && !r.can_afford && <Link href="/tedarikci/bakiye" className="ml-2 text-red-600 hover:underline">Bakiye yetersiz — bakiye yükle</Link>}
                        </Notice>
                    )}
                </Page>
            )}
        </QueryView>
    );
}
