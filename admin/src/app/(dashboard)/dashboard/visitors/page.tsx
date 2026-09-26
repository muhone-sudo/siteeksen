"use client";

import { useState } from "react";
import { Plus } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Button, Card, Field, FormModal, Grid, Input, Page, QueryView, Select, Stats, StatusBadge, Table } from "@/components/ui/kit";
import { dateTime, localToRFC3339, num } from "@/lib/format";
import { opts, VISITOR_STATUS } from "@/lib/labels";

export default function VisitorsPage() {
    const [status, setStatus] = useState("");
    const list = useApi(["visitors", status], () => api.visitors.list({ status }));
    const summary = useApi(["visitors", "summary"], api.visitors.summary);
    const units = useApi(["units"], api.identity.units);
    const act = useAction();
    const [open, setOpen] = useState(false);
    const blank = { visitor_name: "", visitor_phone: "", unit_id: "", visitor_company: "", vehicle_plate: "", purpose: "", expected_at: "", notes: "" };
    const [form, setForm] = useState(blank);
    const s = summary.data;

    return (
        <Page title="Ziyaretçi" description="Ziyaretçi ön kaydı, giriş ve çıkış. Girişte ilgili dairenin sakinlerine bildirim düşer."
            actions={<Button onClick={() => { setForm(blank); setOpen(true); }}><Plus className="h-4 w-4" /> Ziyaretçi kaydı</Button>}>
            <ActionFeedback action={act} />
            <Stats items={[
                { label: "Şu an içeride", value: num(s?.currently_inside), tone: "blue" },
                { label: "Bugün beklenen", value: num(s?.today_expected) },
                { label: "Bugün giriş", value: num(s?.today_checked_in), tone: "green" },
                { label: "Bugün çıkış", value: num(s?.today_checked_out) },
            ]} />
            <Card padded={false} title="Ziyaretçiler" actions={<Select value={status} onChange={(e) => setStatus(e.target.value)} options={opts(VISITOR_STATUS)} placeholder="Tüm durumlar" />}>
                <QueryView q={list} empty="Ziyaretçi kaydı yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(v) => v.id} columns={[
                            { header: "Ziyaretçi", cell: (v) => <div><p className="font-medium">{v.visitor_name}</p><p className="text-xs text-gray-500">{[v.visitor_company, v.vehicle_plate].filter(Boolean).join(" · ")}</p></div> },
                            { header: "Daire", cell: (v) => v.unit_name ?? "—" },
                            { header: "Beklenen", cell: (v) => dateTime(v.expected_at) },
                            { header: "Giriş / Çıkış", cell: (v) => `${dateTime(v.checked_in_at)} / ${dateTime(v.checked_out_at)}` },
                            { header: "Durum", cell: (v) => <StatusBadge value={v.status} map={VISITOR_STATUS} /> },
                            { header: "", cell: (v) => (
                                <div className="flex gap-1">
                                    {v.status === "EXPECTED" && (
                                        <>
                                            <Button size="sm" disabled={act.pending} onClick={() => act.run(() => api.visitors.checkIn(v.id), {
                                                invalidate: ["visitors"],
                                                success: (r) => `Giriş kaydedildi${r.notification ? ` — sakinlere bildirim: ${r.notification.sent} gönderildi` : ""}`,
                                            })}>Giriş</Button>
                                            <Button size="sm" variant="ghost" disabled={act.pending} onClick={() => act.run(() => api.visitors.cancel(v.id), { invalidate: ["visitors"], success: "Kayıt iptal edildi" })}>İptal</Button>
                                        </>
                                    )}
                                    {v.status === "CHECKED_IN" && (
                                        <Button size="sm" disabled={act.pending} onClick={() => act.run(() => api.visitors.checkOut(v.id), { invalidate: ["visitors"], success: "Çıkış kaydedildi" })}>Çıkış</Button>
                                    )}
                                </div>
                            ) },
                        ]} />
                    )}
                </QueryView>
            </Card>

            <FormModal open={open} onClose={() => setOpen(false)} title="Ziyaretçi kaydı" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    const body = { ...form, expected_at: form.expected_at ? localToRFC3339(form.expected_at) : undefined, unit_id: form.unit_id || undefined };
                    const r = await act.run(() => api.visitors.create(body), { invalidate: ["visitors"], success: "Ziyaretçi kaydedildi" });
                    if (r) setOpen(false);
                }}>
                <Grid>
                    <Field label="Ad soyad" required><Input required value={form.visitor_name} onChange={(e) => setForm({ ...form, visitor_name: e.target.value })} /></Field>
                    <Field label="Telefon"><Input value={form.visitor_phone} onChange={(e) => setForm({ ...form, visitor_phone: e.target.value })} /></Field>
                    <Field label="Ziyaret edilen daire">
                        <Select value={form.unit_id} onChange={(e) => setForm({ ...form, unit_id: e.target.value })}
                            options={(units.data?.data ?? []).map((u) => ({ value: u.id, label: `${u.block}-${u.door_number}` }))} placeholder="Yönetim / genel" />
                    </Field>
                    <Field label="Firma"><Input value={form.visitor_company} onChange={(e) => setForm({ ...form, visitor_company: e.target.value })} /></Field>
                    <Field label="Araç plakası"><Input value={form.vehicle_plate} onChange={(e) => setForm({ ...form, vehicle_plate: e.target.value.toUpperCase() })} /></Field>
                    <Field label="Beklenen zaman"><Input type="datetime-local" value={form.expected_at} onChange={(e) => setForm({ ...form, expected_at: e.target.value })} /></Field>
                </Grid>
                <Field label="Amaç"><Input value={form.purpose} onChange={(e) => setForm({ ...form, purpose: e.target.value })} /></Field>
            </FormModal>
        </Page>
    );
}
