"use client";

// Site yaşam döngüsü (058, Apsiyon BUG-11): yönetim hizmeti sonlandırınca site pasife alınır;
// yeni tahakkuk, gecikme tazminatı ve bildirim üretilmez, kayıtlar silinmez.

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Input, Notice, QueryView, Table } from "@/components/ui/kit";
import { dateTime } from "@/lib/format";

export function LifecycleCard() {
    const status = useApi(["property-status"], api.identity.propertyStatus);
    const act = useAction();
    const { roles } = useRoles();
    const isManager = roles.includes("MANAGER");
    const [form, setForm] = useState<null | { reason: string; confirm_name: string }>(null);
    const active = status.data?.is_active ?? true;

    return (
        <>
            <ActionFeedback action={act} />
            <Card title="Site durumu">
                <QueryView q={status}>
                    {(s) => (
                        <div className="space-y-3 text-sm">
                            <p>
                                {s.name}: {s.is_active ? <Badge tone="green">Etkin</Badge> : <Badge tone="red">Pasif</Badge>}
                                {!s.is_active && s.deactivated_at && <> · {dateTime(s.deactivated_at)} — {s.deactivation_reason}</>}
                            </p>
                            <Notice tone={s.is_active ? "amber" : "red"}>
                                {s.is_active
                                    ? "Yönetim hizmeti sonlandırıldığında siteyi pasife alın: yeni aidat tahakkuku, gecikme tazminatı, zamanlanmış hatırlatma ve bildirim üretilmez. Kayıtlar silinmez; sakinler geçmiş kayıtlarını görmeye devam eder."
                                    : "Site pasif: yeni tahakkuk, gecikme tazminatı ve bildirim üretilmiyor. Yeniden etkinleştirmede pasif dönem için geriye dönük tahakkuk yapılmaz."}
                            </Notice>
                            {isManager && (
                                <Button variant={s.is_active ? "danger" : "primary"} onClick={() => setForm({ reason: "", confirm_name: "" })}>
                                    {s.is_active ? "Siteyi pasife al" : "Siteyi yeniden etkinleştir"}
                                </Button>
                            )}
                            {s.events.length > 0 && (
                                <Table rows={s.events} rowKey={(e) => e.at} columns={[
                                    { header: "Tarih", cell: (e) => dateTime(e.at) },
                                    { header: "İşlem", cell: (e) => (e.action === "DEACTIVATED" ? "Pasife alındı" : "Yeniden etkinleştirildi") },
                                    { header: "Gerekçe", cell: (e) => e.reason },
                                ]} />
                            )}
                        </div>
                    )}
                </QueryView>
            </Card>
            <FormModal open={!!form} onClose={() => setForm(null)} title={active ? "Siteyi pasife al" : "Siteyi yeniden etkinleştir"} pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!form) return;
                    const r = await act.run(() => (active ? api.identity.deactivateProperty(form) : api.identity.reactivateProperty({ reason: form.reason })),
                        { invalidate: ["property-status"], success: (res) => res.message });
                    if (r) setForm(null);
                }}>
                {form && (
                    <>
                        <Field label="Gerekçe" required><Input required minLength={5} value={form.reason} onChange={(e) => setForm({ ...form, reason: e.target.value })} /></Field>
                        {active && (
                            <Field label={`Onay için site adını yazın: ${status.data?.name ?? ""}`} required>
                                <Input required value={form.confirm_name} onChange={(e) => setForm({ ...form, confirm_name: e.target.value })} />
                            </Field>
                        )}
                    </>
                )}
            </FormModal>
        </>
    );
}
