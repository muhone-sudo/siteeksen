"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Notice, Page, QueryView, Table } from "@/components/ui/kit";
import { kurus } from "@/lib/format";
import type { MpPackage } from "@/lib/types";

type Form = Omit<MpPackage, "id" | "is_default"> & { id?: string; is_default?: boolean; fee: string };

/** Tedarikçi paketleri (FAZ M4.4, K5): aidat, talep indirimi, dahil talep, SMS hakkı, öncelik penceresi, vitrinde telefon. */
export default function PlatformPackagesPage() {
    const list = useApi(["mp-packages"], api.market.platform.packages);
    const act = useAction();
    const [f, setF] = useState<Form | null>(null);
    const num = (k: keyof Form) => (e: React.ChangeEvent<HTMLInputElement>) => f && setF({ ...f, [k]: Number(e.target.value) });
    const flag = (k: keyof Form) => (e: React.ChangeEvent<HTMLInputElement>) => f && setF({ ...f, [k]: e.target.checked });
    return (
        <Page title="Paketler" description="Tedarikçi abonelik paketleri"
            actions={<Button onClick={() => setF({ name: "", monthly_fee_kurus: 0, fee_discount_pct: 0, included_requests: 0, monthly_sms: 0, priority_access: false,
                phone_in_showcase: false, rank_weight: 0, is_active: true, sort_order: 0, fee: "" })}>Paket ekle</Button>}>
            <ActionFeedback action={act} />
            <Notice tone="blue">Fiyat değişikliği mevcut abonelere bir sonraki yenilemede uygulanır. Varsayılan (ücretsiz) paketin aidatı, önceliği ve vitrinde telefonu olamaz.</Notice>
            <Card padded={false}>
                <QueryView q={list} empty="Paket yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(p) => p.id} columns={[
                            { header: "Paket", cell: (p) => <span className="font-medium">{p.name}{p.is_default && <> <Badge>Varsayılan</Badge></>}</span> },
                            { header: "Aylık", cell: (p) => kurus(p.monthly_fee_kurus) },
                            { header: "Talep indirimi", cell: (p) => `%${p.fee_discount_pct}` },
                            { header: "Dahil talep / SMS", cell: (p) => `${p.included_requests} / ${p.monthly_sms}` },
                            { header: "Öncelik", cell: (p) => (p.priority_access ? "Var" : "—") },
                            { header: "Vitrinde telefon", cell: (p) => (p.phone_in_showcase ? "Var" : "—") },
                            { header: "Ağırlık", cell: (p) => p.rank_weight },
                            { header: "", cell: (p) => (p.is_active ? <Badge tone="green">Etkin</Badge> : <Badge>Pasif</Badge>) },
                            { header: "", cell: (p) => <Button size="sm" variant="ghost" onClick={() => setF({ ...p, fee: String(p.monthly_fee_kurus / 100) })}>Düzenle</Button> },
                        ]} />
                    )}
                </QueryView>
            </Card>
            {f && (
                <FormModal open title={f.id ? "Paketi düzenle" : "Paket ekle"} onClose={() => setF(null)} pending={act.pending} error={act.error}
                    onSubmit={async () => {
                        const { id, fee, is_default: _d, ...rest } = f;
                        void _d;
                        const r = await act.run(() => api.market.platform.savePackage(id ?? null, { ...rest, monthly_fee_kurus: Math.round(Number(fee.replace(",", ".")) * 100) || 0 }),
                            { invalidate: ["mp-packages", "market-meta"], success: "Paket kaydedildi" });
                        if (r) setF(null);
                    }}>
                    <Field label="Ad" required><Input value={f.name} onChange={(e) => setF({ ...f, name: e.target.value })} /></Field>
                    <Grid cols={3}>
                        <Field label="Aylık ücret (TL)"><Input inputMode="decimal" value={f.fee} disabled={f.is_default} onChange={(e) => setF({ ...f, fee: e.target.value })} /></Field>
                        <Field label="Talep indirimi (%)"><Input type="number" min={0} max={100} value={f.fee_discount_pct} onChange={num("fee_discount_pct")} /></Field>
                        <Field label="Sıralama ağırlığı"><Input type="number" min={0} value={f.rank_weight} onChange={num("rank_weight")} /></Field>
                        <Field label="Ayda dahil talep"><Input type="number" min={0} value={f.included_requests} onChange={num("included_requests")} /></Field>
                        <Field label="Aylık SMS hakkı"><Input type="number" min={0} value={f.monthly_sms} onChange={num("monthly_sms")} /></Field>
                        <Field label="Sıra"><Input type="number" value={f.sort_order} onChange={num("sort_order")} /></Field>
                    </Grid>
                    <div className="flex flex-wrap gap-4 text-sm">
                        <label className="flex items-center gap-2"><input type="checkbox" checked={f.priority_access} disabled={f.is_default} onChange={flag("priority_access")} /> Öncelik penceresi</label>
                        <label className="flex items-center gap-2"><input type="checkbox" checked={f.phone_in_showcase} disabled={f.is_default} onChange={flag("phone_in_showcase")} /> Vitrinde telefon</label>
                        <label className="flex items-center gap-2"><input type="checkbox" checked={f.is_active} disabled={f.is_default} onChange={flag("is_active")} /> Etkin</label>
                    </div>
                </FormModal>
            )}
        </Page>
    );
}
