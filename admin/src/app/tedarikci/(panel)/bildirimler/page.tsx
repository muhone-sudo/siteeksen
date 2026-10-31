"use client";

import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Page, QueryView } from "@/components/ui/kit";
import { dateTime } from "@/lib/format";

/** Tedarikçinin uygulama içi bildirimleri (077 sitesiz bildirim): hesap/işletme onayı, talepler, teklifler. */
export default function SupplierNotificationsPage() {
    const list = useApi(["market-notifications"], api.market.notifications);
    const act = useAction();
    return (
        <Page title="Bildirimler" description="Hesabınız, işletmeleriniz ve talepler hakkında"
            actions={list.data && list.data.unread > 0 && (
                <Button variant="secondary" disabled={act.pending} onClick={() => act.run(() => api.market.readNotifications(), { invalidate: ["market-notifications"] })}>
                    Tümünü okundu say
                </Button>
            )}>
            <ActionFeedback action={act} />
            <Card padded={false}>
                <QueryView q={list} empty="Bildirim yok">
                    {(d) => (
                        <ul className="divide-y dark:divide-gray-700">
                            {d.data.map((n) => (
                                <li key={n.id} className={`flex items-start justify-between gap-3 px-5 py-3 ${n.read_at ? "" : "bg-blue-50/60 dark:bg-blue-900/10"}`}>
                                    <div>
                                        <p className="text-sm font-medium">{n.subject ?? n.topic} {!n.read_at && <Badge tone="blue">Yeni</Badge>}</p>
                                        <p className="text-sm text-gray-700 dark:text-gray-300">{n.body}</p>
                                        <p className="text-xs text-gray-500">{dateTime(n.created_at)}</p>
                                    </div>
                                    {!n.read_at && (
                                        <Button size="sm" variant="ghost" onClick={() => act.run(() => api.market.readNotifications([n.id]), { invalidate: ["market-notifications"] })}>Okundu</Button>
                                    )}
                                </li>
                            ))}
                        </ul>
                    )}
                </QueryView>
            </Card>
        </Page>
    );
}
