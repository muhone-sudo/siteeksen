"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Input, Notice, Page, QueryView, Select, Table, Tabs } from "@/components/ui/kit";
import { dateTime } from "@/lib/format";
import type { Setting } from "@/lib/types";

/**
 * Site işletme ayarları. Mevzuata bağlı oranlar (gecikme tazminatı, ısıtma
 * payları, nisaplar) bu ekrandan DEĞİŞTİRİLEMEZ — kanunla sabittir ve
 * veritabanı kısıtıyla korunur.
 */
export default function SettingsPage() {
    const [tab, setTab] = useState<"settings" | "history">("settings");
    const list = useApi(["settings"], api.settings.list);
    const defs = useApi(["settings", "defs"], api.settings.definitions);
    const history = useApi(["settings", "history"], () => api.settings.history(), tab === "history");
    const act = useAction();
    const [edit, setEdit] = useState<Setting | null>(null);
    const [value, setValue] = useState("");

    const defOf = (key: string) => defs.data?.data.find((d) => d.key === key);

    return (
        <Page title="Ayarlar" description="Site işletme ayarları">
            <Notice tone="blue">Mevzuata bağlı değerler (gecikme tazminatı, ısıtma payları, genel kurul nisapları) burada değiştirilemez; kanunla sabittir.</Notice>
            <ActionFeedback action={act} />
            <Tabs tabs={[{ id: "settings", label: "Ayarlar" }, { id: "history", label: "Değişiklik geçmişi" }]} value={tab} onChange={setTab} />
            {tab === "settings" && (
                <Card padded={false}>
                    <QueryView q={list} empty="Ayar yok">
                        {(d) => (
                            <Table rows={d.data} rowKey={(s) => s.key} columns={[
                                { header: "Ayar", cell: (s) => <div><p className="font-medium">{s.description}</p><p className="font-mono text-xs text-gray-500">{s.key}</p></div> },
                                { header: "Değer", cell: (s) => <span className="font-mono">{String(s.value ?? "")}</span> },
                                { header: "", cell: (s) => (s.is_default ? <Badge>Varsayılan</Badge> : <Badge tone="blue">Değiştirildi</Badge>) },
                                { header: "Son değişiklik", cell: (s) => (s.updated_at ? `${dateTime(s.updated_at)} · ${s.updated_by_name ?? ""}` : "—") },
                                { header: "", cell: (s) => (
                                    <div className="flex gap-1">
                                        <Button size="sm" variant="ghost" onClick={() => { setValue(String(s.value ?? "")); setEdit(s); }}>Düzenle</Button>
                                        {!s.is_default && <Button size="sm" variant="ghost" disabled={act.pending} onClick={() => act.run(() => api.settings.reset(s.key), { invalidate: ["settings"], success: "Varsayılana döndü" })}>Sıfırla</Button>}
                                    </div>
                                ) },
                            ]} />
                        )}
                    </QueryView>
                </Card>
            )}
            {tab === "history" && (
                <Card padded={false}>
                    <QueryView q={history} empty="Değişiklik yok">
                        {(d) => (
                            <Table rows={d.data} rowKey={(h) => `${h.key}-${h.changed_at}`} columns={[
                                { header: "Zaman", cell: (h) => dateTime(h.changed_at) },
                                { header: "Ayar", cell: (h) => <span className="font-mono text-xs">{h.key}</span> },
                                { header: "Eski", cell: (h) => h.old_value ?? "—" },
                                { header: "Yeni", cell: (h) => h.new_value },
                                { header: "Değiştiren", cell: (h) => h.changed_by_name ?? "—" },
                            ]} />
                        )}
                    </QueryView>
                </Card>
            )}

            <FormModal open={!!edit} onClose={() => setEdit(null)} title={edit?.description ?? ""} pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!edit) return;
                    const v: unknown = edit.type === "INT" ? Number(value) : edit.type === "BOOL" ? value === "true" : value;
                    const r = await act.run(() => api.settings.set(edit.key, v), { invalidate: ["settings"], success: "Ayar kaydedildi" });
                    if (r) setEdit(null);
                }}>
                {edit && (
                    <Field label="Değer" hint={(() => { const d = defOf(edit.key); return d?.min !== undefined ? `Aralık: ${d.min}–${d.max}` : undefined; })()}>
                        {edit.type === "BOOL" ? (
                            <Select value={value} onChange={(e) => setValue(e.target.value)} options={[{ value: "true", label: "Açık" }, { value: "false", label: "Kapalı" }]} />
                        ) : (
                            <Input type={edit.type === "INT" ? "number" : "text"} value={value} onChange={(e) => setValue(e.target.value)} />
                        )}
                    </Field>
                )}
            </FormModal>
        </Page>
    );
}
