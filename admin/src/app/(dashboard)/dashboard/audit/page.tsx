"use client";

import { useState } from "react";
import Link from "next/link";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, Grid, Input, Modal, Notice, Page, QueryView, Select, Table } from "@/components/ui/kit";
import { dateTime } from "@/lib/format";
import type { AuditLog, AuditQuery } from "@/lib/types";

const LEVEL: Record<string, string> = { OFF: "Kapalı (yalnız zorunlu kayıtlar)", STANDARD: "Standart", FULL: "Tam (uygulama içi etkinlik dahil)" };
const ACTION: Record<string, string> = { VIEW: "Görüntüleme", CREATE: "Oluşturma", UPDATE: "Güncelleme", DELETE: "Silme", DENIED: "Yetki reddi", CLIENT: "Uygulama etkinliği", PII_REVEAL: "Kişisel veri açma" };
const SOURCE: Record<string, string> = { API: "Sunucu", CLIENT: "Uygulama", SYSTEM: "Sistem" };
const PAGE = 100;

/**
 * İşlem kayıtları (073, FAZ H.3): sitedeki bütün işlemler tek yerde. Görüntüleme ve dışa aktarma
 * da kayda geçer. Yönetici ve denetçi görür (KMK m.41).
 */
export default function AuditPage() {
    const [form, setForm] = useState<AuditQuery>({ from: "", to: "", action: "", source: "", entity: "", q: "" });
    const [query, setQuery] = useState<AuditQuery>({});
    const [offset, setOffset] = useState(0);
    const [selected, setSelected] = useState<AuditLog | null>(null);
    const act = useAction();
    const clean = (q: AuditQuery) => Object.fromEntries(Object.entries(q).filter(([, v]) => v !== "" && v !== undefined)) as AuditQuery;
    const list = useApi(["audit", query, offset], () => api.audit.list({ ...clean(query), limit: PAGE, offset }));
    const stats = useApi(["audit", "stats"], api.audit.stats);
    return (
        <Page title="İşlem kayıtları" description="Sitede yapılan bütün işlemler: giriş/çıkış, kayıt değişiklikleri, görüntülemeler ve (TAM düzeyde) uygulama içi etkinlik"
            actions={<Button variant="secondary" disabled={act.pending} onClick={() => act.run(() => api.audit.exportCsv(clean(query)), { success: "Dışa aktarıldı" })}>CSV indir</Button>}>
            <ActionFeedback action={act} />
            <Notice tone="blue">
                Kayıt düzeyi: <b>{list.data ? LEVEL[list.data.level] ?? list.data.level : "…"}</b>. Düzey <Link className="underline" href="/dashboard/settings">Ayarlar</Link>&apos;dan
                (yalnız site yöneticisi) değiştirilir. Yazma işlemleri, yetki reddi, kişisel veri okumaları ve giriş/çıkış her düzeyde kaydedilir.
            </Notice>
            <QueryView q={stats} empty="Son 30 günde kayıt yok">
                {(d) => (
                    <Card title={`Son ${d.period_days} gün`}>
                        <div className="flex flex-wrap gap-2 text-sm">
                            {d.data.map((s) => <Badge key={`${s.source}-${s.action}`}>{SOURCE[s.source] ?? s.source} · {ACTION[s.action] ?? s.action}: {s.total}</Badge>)}
                        </div>
                    </Card>
                )}
            </QueryView>
            <Card title="Süzgeç">
                <form onSubmit={(e) => { e.preventDefault(); setOffset(0); setQuery({ ...form }); }}>
                    <Grid cols={3}>
                        <Field label="Başlangıç"><Input type="date" value={form.from} onChange={(e) => setForm({ ...form, from: e.target.value })} /></Field>
                        <Field label="Bitiş"><Input type="date" value={form.to} onChange={(e) => setForm({ ...form, to: e.target.value })} /></Field>
                        <Field label="İşlem"><Select value={form.action} onChange={(e) => setForm({ ...form, action: e.target.value })}
                            options={[{ value: "", label: "Tümü" }, ...Object.entries(ACTION).map(([value, label]) => ({ value, label }))]} /></Field>
                        <Field label="Kaynak"><Select value={form.source} onChange={(e) => setForm({ ...form, source: e.target.value })}
                            options={[{ value: "", label: "Tümü" }, ...Object.entries(SOURCE).map(([value, label]) => ({ value, label }))]} /></Field>
                        <Field label="Modül"><Input value={form.entity} placeholder="ör. finance, resident, auth" onChange={(e) => setForm({ ...form, entity: e.target.value })} /></Field>
                        <Field label="Olay / ekran ara"><Input value={form.q} placeholder="ör. auth.login, /finance" onChange={(e) => setForm({ ...form, q: e.target.value })} /></Field>
                    </Grid>
                    <div className="mt-3 flex gap-2">
                        <Button type="submit">Uygula</Button>
                        <Button type="button" variant="ghost" onClick={() => { setForm({ from: "", to: "", action: "", source: "", entity: "", q: "" }); setQuery({}); setOffset(0); }}>Temizle</Button>
                    </div>
                </form>
            </Card>
            <Card padded={false}>
                <QueryView q={list} empty="Kayıt yok">
                    {(d) => (
                        <>
                            <Table rows={d.data} rowKey={(r) => r.id} columns={[
                                { header: "Zaman", cell: (r) => dateTime(r.created_at) },
                                { header: "Kullanıcı", cell: (r) => r.user_name || "—" },
                                { header: "Kaynak", cell: (r) => SOURCE[r.source] ?? r.source },
                                { header: "İşlem", cell: (r) => <Badge tone={r.action === "DENIED" ? "red" : r.action === "VIEW" ? undefined : "blue"}>{ACTION[r.action] ?? r.action}</Badge> },
                                { header: "Olay", cell: (r) => r.event || "—" },
                                { header: "Modül", cell: (r) => r.entity_type },
                                { header: "Ekran / yol", cell: (r) => <span className="font-mono text-xs">{r.screen || "—"}</span> },
                                { header: "Kod", cell: (r) => r.status_code || "—" },
                                { header: "", cell: (r) => <Button size="sm" variant="ghost" onClick={() => setSelected(r)}>Ayrıntı</Button> },
                            ]} />
                            <div className="flex items-center justify-between p-3 text-sm">
                                <Button size="sm" variant="ghost" disabled={offset === 0} onClick={() => setOffset(Math.max(0, offset - PAGE))}>Önceki</Button>
                                <span className="text-gray-500">{offset + 1}–{offset + d.data.length}</span>
                                <Button size="sm" variant="ghost" disabled={d.data.length < PAGE} onClick={() => setOffset(offset + PAGE)}>Sonraki</Button>
                            </div>
                        </>
                    )}
                </QueryView>
            </Card>
            <Modal open={!!selected} onClose={() => setSelected(null)} title="Kayıt ayrıntısı">
                {selected && (
                    <dl className="grid gap-2 text-sm sm:grid-cols-2">
                        {Object.entries({ Zaman: dateTime(selected.created_at), Kullanıcı: selected.user_name, IP: selected.ip, Kaynak: SOURCE[selected.source] ?? selected.source,
                            İşlem: ACTION[selected.action] ?? selected.action, Olay: selected.event, Modül: selected.entity_type, Kayıt: selected.entity_id,
                            "Ekran / yol": selected.screen, "Durum kodu": selected.status_code, "İstek kimliği": selected.request_id }).map(([k, v]) => (
                            <div key={k}><dt className="text-gray-500">{k}</dt><dd className="break-all">{v === undefined || v === "" ? "—" : String(v)}</dd></div>
                        ))}
                        {selected.details && (
                            <div className="sm:col-span-2"><dt className="text-gray-500">Ayrıntı</dt>
                                <dd><pre className="overflow-x-auto rounded bg-gray-50 p-2 text-xs dark:bg-gray-900">{JSON.stringify(selected.details, null, 2)}</pre></dd></div>
                        )}
                    </dl>
                )}
            </Modal>
        </Page>
    );
}
