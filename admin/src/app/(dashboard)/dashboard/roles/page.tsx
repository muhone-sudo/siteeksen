"use client";

import { useState } from "react";
import { Plus } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Modal, Notice, Page, QueryView, Select, Table } from "@/components/ui/kit";
import { date, dateTime } from "@/lib/format";
import type { Activation, GrantRoleInput, SiteRole } from "@/lib/types";

const ROLE_OPTIONS = [
    { value: "MANAGER", label: "Yönetici" },
    { value: "BOARD_MEMBER", label: "Yönetim kurulu üyesi" },
    { value: "AUDITOR", label: "Denetçi" },
    { value: "STAFF", label: "Görevli" },
];
const ROLE_NAME = Object.fromEntries(ROLE_OPTIONS.map((r) => [r.value, r.label]));
const NEEDS_DECISION = new Set(["MANAGER", "BOARD_MEMBER", "AUDITOR"]);

/**
 * Görevlendirmeler. Yönetici, kurul üyesi ve denetçi KMK m.34/m.41 uyarınca kat
 * malikleri kurulu kararıyla atanır; karar bilgisi zorunludur. Atamayı yalnızca
 * yönetici yapar. Görev sonlandırılınca kişinin açık oturumları kapanır; kayıt silinmez.
 */
export default function RolesPage() {
    const q = useApi(["site-roles"], api.identity.siteRoles);
    const act = useAction();
    const { roles } = useRoles();
    const isManager = roles.includes("MANAGER");
    const empty: GrantRoleInput = { phone: "", role: "STAFF", decision_ref: "", first_name: "", last_name: "", valid_to: "" };
    const [form, setForm] = useState<GrantRoleInput | null>(null);
    const [shown, setShown] = useState<{ phone: string; act: Activation } | null>(null);

    return (
        <Page
            title="Görevlendirmeler"
            description="Yönetici, yönetim kurulu, denetçi ve görevli atamaları."
            actions={isManager && <Button onClick={() => setForm(empty)}><Plus className="h-4 w-4" /> Görev ver</Button>}
        >
            <ActionFeedback action={act} />
            {!isManager && <Notice tone="blue">Görev verme ve sonlandırma yalnızca yöneticinin yetkisindedir.</Notice>}
            <Card padded={false}>
                <QueryView q={q} empty="Görevlendirme yok">
                    {(d) => (
                        <Table
                            rows={d.data}
                            rowKey={(r) => r.id}
                            columns={[
                                { header: "Kişi", cell: (r) => `${r.first_name} ${r.last_name}` },
                                { header: "Telefon", cell: (r) => r.phone },
                                { header: "Görev", cell: (r) => ROLE_NAME[r.role] ?? r.role },
                                { header: "Dönem", cell: (r) => `${date(r.valid_from)} – ${r.valid_to ? date(r.valid_to) : "süresiz"}` },
                                { header: "Karar", cell: (r) => r.decision_ref || "—" },
                                { header: "Durum", cell: (r) => (r.active ? <Badge tone="green">Etkin</Badge> : <Badge>Sona erdi</Badge>) },
                                { header: "Atayan", cell: (r) => (r.granted_by_name ? `${r.granted_by_name} · ${dateTime(r.granted_at)}` : dateTime(r.granted_at)) },
                                ...(isManager
                                    ? [{
                                          header: "",
                                          cell: (r: SiteRole) =>
                                              r.active ? (
                                                  <Button size="sm" variant="ghost" disabled={act.pending}
                                                      onClick={() => {
                                                          if (window.confirm(`${r.first_name} ${r.last_name} — ${ROLE_NAME[r.role] ?? r.role} görevi sonlandırılsın mı? Kişinin açık oturumları kapanır.`)) {
                                                              void act.run(() => api.identity.endRole(r.id), { invalidate: ["site-roles"], success: "Görev sonlandırıldı" });
                                                          }
                                                      }}>
                                                      Sonlandır
                                                  </Button>
                                              ) : null,
                                      }]
                                    : []),
                            ]}
                        />
                    )}
                </QueryView>
            </Card>

            <FormModal
                open={!!form}
                onClose={() => setForm(null)}
                title="Görev ver"
                pending={act.pending}
                error={act.error}
                onSubmit={async () => {
                    if (!form) return;
                    const body: GrantRoleInput = { ...form };
                    for (const k of ["decision_ref", "valid_to", "first_name", "last_name"] as const) if (!body[k]) delete body[k];
                    const r = await act.run(() => api.identity.grantRole(body), { invalidate: ["site-roles"], success: "Görev verildi" });
                    if (r) {
                        setForm(null);
                        if (r.activation) setShown({ phone: form.phone, act: r.activation });
                    }
                }}
            >
                {form && (
                    <Grid>
                        <Field label="Telefon" required hint="Kişi bu sitede kayıtlı olmalı ya da yeni hesap açılır">
                            <Input required value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} />
                        </Field>
                        <Field label="Görev" required>
                            <Select value={form.role} onChange={(e) => setForm({ ...form, role: e.target.value })} options={ROLE_OPTIONS} />
                        </Field>
                        <Field label="Kurul kararı" required={NEEDS_DECISION.has(form.role)} hint="Tarih ve sayı (KMK m.34/m.41)">
                            <Input required={NEEDS_DECISION.has(form.role)} value={form.decision_ref ?? ""} onChange={(e) => setForm({ ...form, decision_ref: e.target.value })} />
                        </Field>
                        <Field label="Bitiş tarihi" hint="Boşsa süresiz">
                            <Input type="date" value={form.valid_to ?? ""} onChange={(e) => setForm({ ...form, valid_to: e.target.value })} />
                        </Field>
                        <Field label="Ad" hint="Yalnızca yeni hesap için"><Input value={form.first_name ?? ""} onChange={(e) => setForm({ ...form, first_name: e.target.value })} /></Field>
                        <Field label="Soyad" hint="Yalnızca yeni hesap için"><Input value={form.last_name ?? ""} onChange={(e) => setForm({ ...form, last_name: e.target.value })} /></Field>
                    </Grid>
                )}
            </FormModal>

            {shown && (
                <Modal open onClose={() => setShown(null)} title="Hesap etkinleştirme kodu">
                    <div className="space-y-3">
                        <p className="text-sm">{shown.phone} için yeni hesap açıldı. Kod:</p>
                        <code className="block rounded-lg border bg-gray-50 px-4 py-3 font-mono text-2xl tracking-[0.3em] dark:bg-gray-700">{shown.act.activation_code}</code>
                        <p className="text-xs text-gray-500">Son geçerlilik: {dateTime(shown.act.expires_at)}</p>
                        <Notice tone="amber" title="Bu kod bir daha gösterilmez">{shown.act.note}</Notice>
                        <div className="flex justify-end"><Button onClick={() => setShown(null)}>Kodu ilettim, kapat</Button></div>
                    </div>
                </Modal>
            )}
        </Page>
    );
}
