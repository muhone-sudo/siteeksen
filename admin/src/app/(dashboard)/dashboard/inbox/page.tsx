"use client";

import { useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Page, QueryView, Table, Tabs } from "@/components/ui/kit";
import { dateTime } from "@/lib/format";

type Filter = "unread" | "all";

/**
 * Kişisel bildirim kutusu (073, FAZ H.2): bana gelen uygulama içi bildirimler ve okundu bilgisi.
 * Sitenin bütün bildirimleri ve toplu gönderim ayrı sayfadadır (Toplu Bildirim).
 */
export default function InboxPage() {
    const [filter, setFilter] = useState<Filter>("unread");
    const qc = useQueryClient();
    const act = useAction();
    const list = useApi(["inbox", "page", filter], () => api.notifications.inbox({ unread: filter === "unread" ? "1" : undefined, limit: 200 }));
    const refresh = () => void qc.invalidateQueries({ queryKey: ["inbox"] });
    return (
        <Page title="Bildirimlerim" description="Size gelen uygulama içi bildirimler"
            actions={<Button variant="secondary" disabled={act.pending}
                onClick={async () => { const r = await act.run(() => api.notifications.markAllRead(), { success: "Tümü okundu sayıldı" }); if (r) refresh(); }}>
                Tümünü okundu say</Button>}>
            <ActionFeedback action={act} />
            <Tabs tabs={[{ id: "unread", label: "Okunmamış" }, { id: "all", label: "Tümü" }]} value={filter} onChange={setFilter} />
            <Card padded={false}>
                <QueryView q={list} empty={filter === "unread" ? "Okunmamış bildirim yok" : "Bildirim yok"}>
                    {(d) => (
                        <Table rows={d.data} rowKey={(n) => n.id} columns={[
                            { header: "Zaman", cell: (n) => dateTime(n.created_at) },
                            { header: "Konu", cell: (n) => <span className={n.read_at ? "" : "font-semibold"}>{n.subject || n.topic}</span> },
                            { header: "İçerik", cell: (n) => <span className="whitespace-pre-line text-sm">{n.body}</span> },
                            { header: "Durum", cell: (n) => (n.read_at ? <Badge>Okundu {dateTime(n.read_at)}</Badge> : <Badge tone="blue">Okunmadı</Badge>) },
                            { header: "", cell: (n) => !n.read_at && (
                                <Button size="sm" variant="ghost" disabled={act.pending}
                                    onClick={async () => { const r = await act.run(() => api.notifications.markRead(n.id), { success: "Okundu sayıldı" }); if (r) refresh(); }}>
                                    Okundu say</Button>
                            ) },
                        ]} />
                    )}
                </QueryView>
            </Card>
        </Page>
    );
}
