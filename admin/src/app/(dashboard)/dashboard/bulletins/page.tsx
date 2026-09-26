"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Button, Card, Field, FormModal, Page, QueryView, Select, Stats, StatusBadge, Table, Textarea } from "@/components/ui/kit";
import { dateTime, num, tl } from "@/lib/format";
import { BULLETIN_STATUS, opts } from "@/lib/labels";
import type { BulletinPost } from "@/lib/types";

const CAT: Record<string, string> = {
    SALE: "Satılık", RENT: "Kiralık", LOST_FOUND: "Kayıp / bulundu", HELP: "Yardım", SUGGESTION: "Öneri",
    CARPOOL: "Araç paylaşımı", SERVICE: "Hizmet", EVENT: "Etkinlik", OTHER: "Diğer",
};

/** Sakin ilanları yönetim onayından geçer; reddedilen ilan gerekçesiyle sahibine döner. */
export default function BulletinsPage() {
    const [status, setStatus] = useState("PENDING");
    const list = useApi(["bulletins", status], () => api.bulletins.list({ status }));
    const summary = useApi(["bulletins", "summary"], api.bulletins.summary);
    const act = useAction();
    const [rejecting, setRejecting] = useState<BulletinPost | null>(null);
    const [reason, setReason] = useState("");
    const s = summary.data;

    return (
        <Page title="İlan panosu" description="Sakinlerin ilanları: onay, ret ve süresi dolanlar."
            actions={<Button variant="secondary" disabled={act.pending} onClick={() => act.run(() => api.bulletins.expireDue(), { invalidate: ["bulletins"], success: (r) => `${r.expired_count} ilanın süresi doldu olarak işaretlendi` })}>Süresi dolanları işle</Button>}>
            <ActionFeedback action={act} />
            <Stats items={[
                { label: "Onay bekleyen", value: num(s?.pending_review), tone: "amber" },
                { label: "Yayında", value: num(s?.approved), tone: "green" },
                { label: "Reddedilen", value: num(s?.rejected), tone: "red" },
                { label: "Süresi dolan / kapalı", value: `${num(s?.expired)} / ${num(s?.closed)}` },
            ]} />
            <Card padded={false} title="İlanlar" actions={<Select value={status} onChange={(e) => setStatus(e.target.value)} options={opts(BULLETIN_STATUS)} placeholder="Tüm durumlar" />}>
                <QueryView q={list} empty="İlan yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(p) => p.id} columns={[
                            { header: "İlan", cell: (p) => <div><p className="font-medium">{p.title}</p><p className="line-clamp-2 text-xs text-gray-500">{p.content}</p></div> },
                            { header: "Kategori", cell: (p) => CAT[p.category] ?? p.category },
                            { header: "Fiyat", cell: (p) => (p.price !== undefined && p.price !== null ? tl(p.price) : "—") },
                            { header: "Sahibi", cell: (p) => `${p.author_name ?? "Anonim"}${p.unit_name ? ` (${p.unit_name})` : ""}` },
                            { header: "Tarih", cell: (p) => dateTime(p.created_at) },
                            { header: "Durum", cell: (p) => <StatusBadge value={p.status} map={BULLETIN_STATUS} /> },
                            { header: "", cell: (p) => (
                                <div className="flex gap-1">
                                    {p.status === "PENDING" && (
                                        <>
                                            <Button size="sm" disabled={act.pending} onClick={() => act.run(() => api.bulletins.approve(p.id), { invalidate: ["bulletins"], success: "İlan yayımlandı" })}>Onayla</Button>
                                            <Button size="sm" variant="danger" onClick={() => { setReason(""); setRejecting(p); }}>Reddet</Button>
                                        </>
                                    )}
                                    {p.status === "APPROVED" && <Button size="sm" variant="ghost" disabled={act.pending} onClick={() => act.run(() => api.bulletins.close(p.id), { invalidate: ["bulletins"], success: "İlan kapatıldı" })}>Kapat</Button>}
                                </div>
                            ) },
                        ]} />
                    )}
                </QueryView>
            </Card>
            <FormModal open={!!rejecting} onClose={() => setRejecting(null)} title="İlanı reddet" submitLabel="Reddet" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!rejecting) return;
                    const r = await act.run(() => api.bulletins.reject(rejecting.id, reason), { invalidate: ["bulletins"], success: "İlan reddedildi; gerekçe sahibine gösterilir" });
                    if (r) setRejecting(null);
                }}>
                <Field label="Gerekçe" required hint="Sakin ilanı bu gerekçeye göre düzeltebilir."><Textarea required value={reason} onChange={(e) => setReason(e.target.value)} /></Field>
            </FormModal>
        </Page>
    );
}
