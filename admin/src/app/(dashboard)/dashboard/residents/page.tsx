"use client";

import { useState } from "react";
import { KeyRound, Plus } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Modal, Notice, Page, QueryView, Select, Table } from "@/components/ui/kit";
import { dateTime } from "@/lib/format";
import { RESIDENT_ROLES, ROLE_LABEL } from "@/lib/labels";
import type { Activation, Resident } from "@/lib/types";

/**
 * Etkinleştirme kodu YALNIZCA BİR KEZ gösterilir: sunucu kodun kendisini değil
 * özetini saklar, bu pencere kapandıktan sonra kod bir daha görüntülenemez.
 * SMS sağlayıcısı bağlı olmadığı için kodu sakine yönetici iletir.
 */
function ActivationModal({ value, onClose }: { value: { who: string; phone: string; act: Activation } | null; onClose: () => void }) {
    const [copied, setCopied] = useState(false);
    if (!value) return null;
    const { who, phone, act } = value;
    return (
        <Modal open onClose={onClose} title={act.purpose === "RESET" ? "Şifre sıfırlama kodu" : "Hesap etkinleştirme kodu"}>
            <div className="space-y-4">
                <p className="text-sm text-gray-700 dark:text-gray-300">
                    <strong>{who}</strong> ({phone}) için kod:
                </p>
                <div className="flex items-center justify-between rounded-lg border border-gray-300 bg-gray-50 px-4 py-3 dark:border-gray-600 dark:bg-gray-700">
                    <code className="font-mono text-2xl tracking-[0.3em] text-gray-900 dark:text-white">{act.activation_code}</code>
                    <Button
                        size="sm"
                        variant="secondary"
                        onClick={async () => {
                            try {
                                await navigator.clipboard.writeText(act.activation_code);
                                setCopied(true);
                            } catch {
                                setCopied(false);
                            }
                        }}
                    >
                        {copied ? "Kopyalandı" : "Kopyala"}
                    </Button>
                </div>
                <p className="text-xs text-gray-500">Son geçerlilik: {dateTime(act.expires_at)}</p>
                <Notice tone="amber" title="Bu kod bir daha gösterilmez">{act.note}</Notice>
                <div className="flex justify-end">
                    <Button onClick={onClose}>Kodu ilettim, kapat</Button>
                </div>
            </div>
        </Modal>
    );
}

export default function ResidentsPage() {
    const [search, setSearch] = useState("");
    const [role, setRole] = useState("");
    const q = useApi(["residents", search, role], () => api.identity.residents({ search, role }));
    const units = useApi(["units"], api.identity.units);
    const act = useAction();
    const { canWrite } = useRoles();
    const [open, setOpen] = useState(false);
    const [form, setForm] = useState({ first_name: "", last_name: "", phone: "", email: "", unit_id: "", role: "OWNER" });
    const [edit, setEdit] = useState<Resident | null>(null);
    const [shown, setShown] = useState<{ who: string; phone: string; act: Activation } | null>(null);

    const unitOptions = (units.data?.data ?? []).map((u) => ({ value: u.id, label: `${u.block}-${u.door_number}` }));

    return (
        <Page
            title="Sakinler"
            description="Malik, kiracı ve vekil kayıtları. Kişisel veriler KVKK kapsamında yalnızca yetkili rollere gösterilir."
            actions={canWrite && <Button onClick={() => setOpen(true)}><Plus className="h-4 w-4" /> Sakin ekle</Button>}
        >
            <ActionFeedback action={act} />
            <Card>
                <div className="mb-4 flex flex-wrap gap-2">
                    <Input placeholder="Ad, soyad ya da telefon ara" value={search} onChange={(e) => setSearch(e.target.value)} className="max-w-xs" />
                    <Select value={role} onChange={(e) => setRole(e.target.value)} options={RESIDENT_ROLES} placeholder="Tüm sıfatlar" className="max-w-[12rem]" />
                </div>
                <QueryView q={q} empty="Sakin bulunamadı">
                    {(d) => (
                        <Table
                            rows={d.data}
                            rowKey={(r) => r.id}
                            columns={[
                                { header: "Ad Soyad", cell: (r) => `${r.first_name} ${r.last_name}` },
                                { header: "Telefon", cell: (r) => r.phone },
                                { header: "Daire", cell: (r) => r.unit },
                                { header: "Sıfat", cell: (r) => ROLE_LABEL[r.role] ?? r.role },
                                { header: "Durum", cell: (r) => (r.is_active ? <Badge tone="green">Aktif</Badge> : <Badge>Ayrıldı</Badge>) },
                                ...(canWrite
                                    ? [{
                                          header: "",
                                          cell: (r: Resident) => (
                                              <div className="flex justify-end gap-1">
                                                  <Button
                                                      size="sm"
                                                      variant="ghost"
                                                      title="Etkinleştirme ya da şifre sıfırlama kodu üret (eski kod geçersizleşir)"
                                                      disabled={act.pending}
                                                      onClick={async () => {
                                                          const a = await act.run(() => api.identity.issueActivationCode(r.id));
                                                          if (a) {
                                                              act.clear();
                                                              setShown({ who: `${r.first_name} ${r.last_name}`, phone: r.phone, act: a });
                                                          }
                                                      }}
                                                  >
                                                      <KeyRound className="h-3.5 w-3.5" /> Kod üret
                                                  </Button>
                                                  <Button size="sm" variant="ghost" onClick={() => setEdit(r)}>Düzenle</Button>
                                              </div>
                                          ),
                                      }]
                                    : []),
                            ]}
                        />
                    )}
                </QueryView>
            </Card>

            <FormModal
                open={open}
                onClose={() => setOpen(false)}
                title="Sakin ekle"
                pending={act.pending}
                error={act.error}
                onSubmit={async () => {
                    const r = await act.run(() => api.identity.createResident(form), { invalidate: ["residents"], success: "Sakin eklendi" });
                    if (r) {
                        setOpen(false);
                        if (r.activation) setShown({ who: `${r.first_name} ${r.last_name}`, phone: r.phone, act: r.activation });
                    }
                }}
            >
                <Grid>
                    <Field label="Ad" required><Input required value={form.first_name} onChange={(e) => setForm({ ...form, first_name: e.target.value })} /></Field>
                    <Field label="Soyad" required><Input required value={form.last_name} onChange={(e) => setForm({ ...form, last_name: e.target.value })} /></Field>
                    <Field label="Telefon" required hint="05xx… ya da +90…"><Input required value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} /></Field>
                    <Field label="E-posta"><Input type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} /></Field>
                    <Field label="Bağımsız bölüm" required>
                        <Select required value={form.unit_id} onChange={(e) => setForm({ ...form, unit_id: e.target.value })} options={unitOptions} placeholder="Seçin" />
                    </Field>
                    <Field label="Sıfat" required>
                        <Select value={form.role} onChange={(e) => setForm({ ...form, role: e.target.value })} options={RESIDENT_ROLES} />
                    </Field>
                </Grid>
            </FormModal>

            <ActivationModal value={shown} onClose={() => setShown(null)} />

            <FormModal
                open={!!edit}
                onClose={() => setEdit(null)}
                title={edit ? `${edit.first_name} ${edit.last_name}` : ""}
                pending={act.pending}
                error={act.error}
                onSubmit={async () => {
                    if (!edit) return;
                    const r = await act.run(() => api.identity.updateResident(edit.id, { role: edit.role, is_active: edit.is_active }), {
                        invalidate: ["residents"],
                        success: "Sakin kaydı güncellendi",
                    });
                    if (r) setEdit(null);
                }}
            >
                {edit && (
                    <Grid>
                        <Field label="Sıfat">
                            <Select value={edit.role} onChange={(e) => setEdit({ ...edit, role: e.target.value })} options={RESIDENT_ROLES} />
                        </Field>
                        <Field label="Durum" hint="Ayrılan sakinin kaydı silinmez; geçmiş kayıtlarda adı korunur.">
                            <Select
                                value={edit.is_active ? "1" : "0"}
                                onChange={(e) => setEdit({ ...edit, is_active: e.target.value === "1" })}
                                options={[{ value: "1", label: "Aktif" }, { value: "0", label: "Ayrıldı" }]}
                            />
                        </Field>
                    </Grid>
                )}
            </FormModal>
        </Page>
    );
}
