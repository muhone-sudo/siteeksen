"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { Badge, Button, Card, Field, FormModal, Notice, QueryView, Table, Textarea } from "@/components/ui/kit";
import { dateTime } from "@/lib/format";
import type { VisibilityPolicy } from "@/lib/types";

type OptionKey = "show_tenant_contact" | "show_tenant_debt_total" | "show_tenant_overdue" | "show_unit_requests";
const STATUS: Record<VisibilityPolicy["status"], string> = {
    DEFAULT: "Varsayılan (en dar)", PENDING: "Onay bekliyor", ACTIVE: "Yürürlükte", SUPERSEDED: "Yerini yenisi aldı", REJECTED: "Reddedildi", CANCELLED: "Geri çekildi",
};

/**
 * Malikin görünürlük politikası (071, D6). Devirden sonra malikin kiracılı dairede neyi göreceğini malik değil
 * yönetim belirler; site genelinde tek politika, varsayılan en dar. Yönetim önerir, öneren dışındaki bir kurul
 * üyesi onaylayınca yürürlüğe girer ve kiracılara bildirilir. Kiracılar etkin politikayı uygulamada görür.
 */
export function VisibilityCard() {
    const q = useApi(["settings", "owner-visibility"], api.settings.ownerVisibility);
    const act = useAction();
    const { roles, canWrite, userId } = useRoles();
    const isBoard = roles.includes("BOARD_MEMBER");
    const [form, setForm] = useState<(Record<OptionKey, boolean> & { note: string }) | null>(null);
    const [decide, setDecide] = useState<{ id: string; approve: boolean; note: string } | null>(null);

    return (
        <QueryView q={q}>
            {(d) => {
                const on = (p: VisibilityPolicy) => d.options.filter((o) => p[o.key]).map((o) => o.label);
                return (
                    <>
                        <Card title="Malikin kiracılı dairede gördükleri" actions={canWrite && !d.pending && (
                            <Button size="sm" onClick={() => setForm({
                                show_tenant_contact: d.active.show_tenant_contact, show_tenant_debt_total: d.active.show_tenant_debt_total,
                                show_tenant_overdue: d.active.show_tenant_overdue, show_unit_requests: d.active.show_unit_requests, note: "",
                            })}>Değişiklik öner</Button>
                        )}>
                            <p className="mb-3 text-sm text-gray-600 dark:text-gray-400">{d.note}</p>
                            <div className="mb-3 flex items-center gap-2 text-sm">
                                <Badge tone={d.active.status === "ACTIVE" ? "green" : undefined}>{STATUS[d.active.status]}</Badge>
                                {d.active.decided_at && <span className="text-gray-500">{dateTime(d.active.decided_at)} · onaylayan {d.active.decided_by_name}</span>}
                            </div>
                            <ul className="mb-3 list-disc pl-5 text-sm">
                                {d.options.map((o) => <li key={o.key}>{o.label}: <strong>{d.active[o.key] ? "görür" : "görmez"}</strong></li>)}
                            </ul>
                            <div className="grid gap-3 text-sm sm:grid-cols-2">
                                <Notice tone="blue" title="Her zaman görür">{d.always_visible.join(" · ")}</Notice>
                                <Notice tone="amber" title="Hiçbir zaman görmez">{d.never_visible.join(" · ")}</Notice>
                            </div>
                        </Card>

                        {d.pending && (
                            <Card title="Onay bekleyen öneri">
                                <p className="text-sm">{d.pending.proposed_by_name} · {dateTime(d.pending.proposed_at ?? "")}: “{d.pending.note}”</p>
                                <p className="mt-2 text-sm">Açılacak alanlar: {on(d.pending).join(", ") || "hiçbiri (en dar ayar)"}</p>
                                <div className="mt-3 flex gap-2">
                                    {isBoard && d.pending.proposed_by !== userId && (
                                        <>
                                            <Button size="sm" onClick={() => setDecide({ id: d.pending!.id!, approve: true, note: "" })}>Onayla</Button>
                                            <Button size="sm" variant="secondary" onClick={() => setDecide({ id: d.pending!.id!, approve: false, note: "" })}>Reddet</Button>
                                        </>
                                    )}
                                    {d.pending.proposed_by === userId && (
                                        <Button size="sm" variant="ghost" disabled={act.pending}
                                            onClick={() => act.run(() => api.settings.cancelOwnerVisibility(d.pending!.id!), { invalidate: ["settings"], success: (x) => x.message })}>Geri çek</Button>
                                    )}
                                </div>
                                {!isBoard && <p className="mt-2 text-xs text-gray-500">Öneriyi öneren dışındaki bir yönetim kurulu üyesi onaylar.</p>}
                            </Card>
                        )}

                        {d.history && d.history.length > 0 && (
                            <Card title="Geçmiş" padded={false}>
                                <Table rows={d.history} rowKey={(h) => h.id ?? ""} columns={[
                                    { header: "Öneri", cell: (h) => `${dateTime(h.proposed_at ?? "")} · ${h.proposed_by_name}` },
                                    { header: "Açılan alanlar", cell: (h) => on(h).join(", ") || "hiçbiri" },
                                    { header: "Gerekçe", cell: (h) => h.note },
                                    { header: "Durum", cell: (h) => <Badge tone={h.status === "ACTIVE" ? "green" : undefined}>{STATUS[h.status]}</Badge> },
                                    { header: "Karar", cell: (h) => (h.decided_at ? `${dateTime(h.decided_at)} · ${h.decided_by_name ?? ""}${h.decision_note ? ` — ${h.decision_note}` : ""}` : "—") },
                                ]} />
                            </Card>
                        )}

                        <FormModal open={!!form} onClose={() => setForm(null)} title="Görünürlük değişikliği öner" submitLabel="Öner" pending={act.pending} error={act.error}
                            onSubmit={async () => {
                                if (!form) return;
                                const r = await act.run(() => api.settings.proposeOwnerVisibility(form), { invalidate: ["settings"], success: (x) => x.message });
                                if (r) setForm(null);
                            }}>
                            {form && (
                                <>
                                    <Notice tone="amber">Seçenekleri açmak kiracının kişisel verisini malike gösterir (KVKK m.4 ölçülülük). Değişiklik kiracılara bildirilir.</Notice>
                                    {d.options.map((o) => (
                                        <label key={o.key} className="flex items-center gap-2 text-sm">
                                            <input type="checkbox" checked={form[o.key]} onChange={(e) => setForm({ ...form, [o.key]: e.target.checked })} />
                                            {o.label}
                                        </label>
                                    ))}
                                    <Field label="Gerekçe" required hint="Kiracılar bu metni görür (en az 10 karakter)">
                                        <Textarea required rows={3} value={form.note} onChange={(e) => setForm({ ...form, note: e.target.value })} />
                                    </Field>
                                </>
                            )}
                        </FormModal>

                        <FormModal open={!!decide} onClose={() => setDecide(null)} title={decide?.approve ? "Öneriyi onayla" : "Öneriyi reddet"} submitLabel={decide?.approve ? "Onayla" : "Reddet"}
                            pending={act.pending} error={act.error}
                            onSubmit={async () => {
                                if (!decide) return;
                                const call = decide.approve ? api.settings.approveOwnerVisibility : api.settings.rejectOwnerVisibility;
                                const r = await act.run(() => call(decide.id, decide.note), { invalidate: ["settings"], success: (x) => x.message });
                                if (r) setDecide(null);
                            }}>
                            <Field label="Not"><Textarea rows={3} value={decide?.note ?? ""} onChange={(e) => decide && setDecide({ ...decide, note: e.target.value })} /></Field>
                        </FormModal>
                    </>
                );
            }}
        </QueryView>
    );
}
