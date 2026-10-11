"use client";

import { useState } from "react";
import { FileText } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { Badge, Button, Card, Field, FormModal, Grid, Input, Notice, QueryView, Select, Table, Textarea } from "@/components/ui/kit";
import { date, dateTime } from "@/lib/format";
import type { TenancyEndRequest } from "@/lib/types";

const KIND: Record<TenancyEndRequest["kind"], string> = { OWNER_REQUEST: "Malik isteği", TENANT_EXIT: "Kiracının çıkışı", MANAGEMENT: "Yönetim yolu" };
const STATUS: Record<TenancyEndRequest["status"], { label: string; tone?: "green" | "amber" | "red" | "blue" }> = {
    PENDING_TENANT: { label: "Kiracı onayı bekliyor", tone: "amber" },
    OBJECTION_WINDOW: { label: "İtiraz süresinde", tone: "blue" },
    SUSPENDED: { label: "İtiraz edildi — askıda", tone: "red" },
    COMPLETED: { label: "Bitti", tone: "green" },
    REJECTED: { label: "Kiracı reddetti" },
    CANCELLED: { label: "İptal edildi" },
    REVERSED: { label: "Geri alındı", tone: "amber" },
};
const DOC_KINDS = [
    { value: "TAHLIYE_KARARI", label: "Tahliye kararı" },
    { value: "ICRA_TAHLIYE", label: "İcra yoluyla tahliye" },
    { value: "TASINMA_TUTANAGI", label: "Taşınma tutanağı" },
    { value: "DIGER", label: "Diğer" },
];
const EVENT: Record<string, string> = {
    CREATED: "açıldı", APPROVED: "kiracı onayladı", DECLINED: "kiracı reddetti", OBJECTED: "kiracı itiraz etti",
    DOCUMENT_ADDED: "belge eklendi", COMPLETED: "tamamlandı", CANCELLED: "iptal edildi", REVERSED: "geri alındı",
};
const BY: Record<string, string> = { TENANT: "kiracı", OWNER: "malik", MANAGEMENT: "yönetim" };

type DocForm = { requestId?: string; unit_id: string; reason: string; document_kind: string; uyap_code: string; password: string; attest: boolean; file: File | null };

/**
 * Kiracılığın bitişi (069, D4). Malik isteği kiracı onaylamadan bitmez; kiracı kendi çıkışını bildirebilir.
 * Yönetim yolu: belge (UYAP kodu isteğe bağlı) + şifreyle beyan + 7 gün itiraz; itirazda askı; sahte çıkarsa geri alma.
 * Dairenin maliki ya da vekili olan yönetici yönetim yolunu başlatamaz (sunucu denetler).
 */
export function TenancyEndsCard() {
    const q = useApi(["residents", "tenancy-requests"], api.identity.tenancyRequests);
    const units = useApi(["units"], api.identity.units);
    const act = useAction();
    const { canWrite } = useRoles();
    const [doc, setDoc] = useState<DocForm | null>(null);
    const [reverse, setReverse] = useState<{ id: string; reason: string; password: string } | null>(null);
    const tenanted = (units.data?.data ?? []).filter((u) => u.occupancy === "TENANT_OCCUPIED").map((u) => ({ value: u.id, label: `${u.block}-${u.door_number}` }));
    const attestation = q.data?.attestation_text ?? "";

    const submitDoc = async () => {
        if (!doc?.file) return;
        const f = new FormData();
        f.set("document_kind", doc.document_kind);
        f.set("uyap_code", doc.uyap_code);
        f.set("password", doc.password);
        f.set("attest", doc.attest ? "true" : "false");
        f.set("file", doc.file);
        let r;
        if (doc.requestId) {
            const id = doc.requestId;
            r = await act.run(() => api.identity.addTenancyDocument(id, f), { invalidate: ["residents"], success: (x) => x.message });
        } else {
            f.set("unit_id", doc.unit_id);
            f.set("reason", doc.reason);
            r = await act.run(() => api.identity.startTenancyEnd(f), { invalidate: ["residents"], success: (x) => x.message });
        }
        if (r) setDoc(null);
    };

    return (
        <Card title="Kiracılık bitişleri" actions={canWrite && (
            <Button size="sm" variant="secondary" onClick={() => setDoc({ unit_id: "", reason: "", document_kind: "TASINMA_TUTANAGI", uyap_code: "", password: "", attest: false, file: null })}>
                <FileText className="h-4 w-4" /> Yönetim yolu başlat
            </Button>
        )}>
            <p className="mb-3 text-sm text-gray-600 dark:text-gray-400">
                Malikin isteği kiracı onaylamadan sonuçlanmaz; kiracı kendi çıkışını uygulamadan bildirir. Belgeye dayanan yönetim yolunda kiracı
                belgeyi görür ve 7 gün içinde itiraz edebilir; itirazda işlem askıya alınır. Aktif kiracı başka yoldan pasifleştirilemez.
            </p>
            <QueryView q={q} empty="Kiracılık bitiş kaydı yok">
                {(d) => (
                    <Table
                        rows={d.data}
                        rowKey={(r) => r.id}
                        columns={[
                            { header: "Daire", cell: (r) => r.unit },
                            { header: "Kiracı", cell: (r) => r.tenant_name },
                            { header: "Yol", cell: (r) => KIND[r.kind] },
                            { header: "Durum", cell: (r) => <Badge tone={STATUS[r.status].tone}>{STATUS[r.status].label}</Badge> },
                            { header: "Süre / bitiş", cell: (r) => (r.end_date ? `Bitti · ${date(r.end_date)}` : r.objection_deadline ? `İtiraz sonu ${dateTime(r.objection_deadline)}` : "—") },
                            {
                                header: "Belgeler ve kayıt", cell: (r) => (
                                    <div className="space-y-1 text-xs">
                                        {r.documents.map((x) => (
                                            <button key={x.id} type="button" className="block text-blue-600 hover:underline dark:text-blue-400"
                                                onClick={() => act.run(() => api.identity.tenancyDocument(r.id, x.id, x.file_name))}>
                                                {DOC_KINDS.find((k) => k.value === x.document_kind)?.label ?? x.document_kind}{x.uyap_code ? ` · UYAP ${x.uyap_code}` : ""} · {x.file_name}
                                            </button>
                                        ))}
                                        <div className="text-gray-500">{r.events.map((e) => `${dateTime(e.created_at)} ${BY[e.by]} ${EVENT[e.event] ?? e.event}${e.note ? ` (${e.note})` : ""}`).join(" · ")}</div>
                                    </div>
                                ),
                            },
                            ...(canWrite ? [{
                                header: "", cell: (r: TenancyEndRequest) => r.kind !== "MANAGEMENT" ? null : (
                                    <div className="flex flex-wrap justify-end gap-1">
                                        {r.status === "OBJECTION_WINDOW" && (
                                            <Button size="sm" variant="ghost" disabled={act.pending || (r.objection_deadline ? new Date(r.objection_deadline) > new Date() : true)}
                                                title="İtiraz süresi itirazsız dolunca etkinleşir"
                                                onClick={() => act.run(() => api.identity.completeTenancyEnd(r.id), { invalidate: ["residents"], success: (x) => x.message })}>Tamamla</Button>
                                        )}
                                        {r.status === "SUSPENDED" && (
                                            <Button size="sm" variant="ghost" onClick={() => setDoc({ requestId: r.id, unit_id: r.unit_id, reason: "", document_kind: "TAHLIYE_KARARI", uyap_code: "", password: "", attest: false, file: null })}>Yeni belge</Button>
                                        )}
                                        {(r.status === "OBJECTION_WINDOW" || r.status === "SUSPENDED") && (
                                            <Button size="sm" variant="ghost" disabled={act.pending}
                                                onClick={() => act.run(() => api.identity.cancelTenancyEnd(r.id, ""), { invalidate: ["residents"], success: (x) => x.message })}>İptal</Button>
                                        )}
                                        {r.status === "COMPLETED" && (
                                            <Button size="sm" variant="ghost" onClick={() => setReverse({ id: r.id, reason: "", password: "" })}>Geri al</Button>
                                        )}
                                    </div>
                                ),
                            }] : []),
                        ]}
                    />
                )}
            </QueryView>

            <FormModal open={!!doc} onClose={() => setDoc(null)} title={doc?.requestId ? "Yeni belge — yeni 7 günlük itiraz süresi" : "Yönetim yoluyla kiracılığın bitişi"}
                submitLabel="Belgeyi yükle ve onayla" pending={act.pending} error={act.error} onSubmit={submitDoc}>
                {doc && (
                    <>
                        <Notice tone="amber" title="Beyan">{attestation}</Notice>
                        <Grid>
                            {!doc.requestId && (
                                <Field label="Daire (aktif kiracılı)" required>
                                    <Select required value={doc.unit_id} onChange={(e) => setDoc({ ...doc, unit_id: e.target.value })} options={tenanted} placeholder="Seçin" />
                                </Field>
                            )}
                            <Field label="Belge türü" required><Select value={doc.document_kind} onChange={(e) => setDoc({ ...doc, document_kind: e.target.value })} options={DOC_KINDS} /></Field>
                            <Field label="UYAP doğrulama kodu" hint="Varsa girin; kodu olmayan belgeler de kabul edilir"><Input value={doc.uyap_code} onChange={(e) => setDoc({ ...doc, uyap_code: e.target.value })} /></Field>
                            <Field label="Belge (PDF ya da görsel, en çok 10 MB)" required>
                                <Input required type="file" accept="application/pdf,image/png,image/jpeg,image/webp" onChange={(e) => setDoc({ ...doc, file: e.target.files?.[0] ?? null })} />
                            </Field>
                            <Field label="Şifreniz" required hint="Kimliğinizi doğrulamak için"><Input required type="password" autoComplete="current-password" value={doc.password} onChange={(e) => setDoc({ ...doc, password: e.target.value })} /></Field>
                        </Grid>
                        {!doc.requestId && (
                            <Field label="Gerekçe" required hint="Kiracı bu metni görür (en az 10 karakter)">
                                <Textarea required rows={3} value={doc.reason} onChange={(e) => setDoc({ ...doc, reason: e.target.value })} />
                            </Field>
                        )}
                        <label className="flex items-start gap-2 text-sm">
                            <input type="checkbox" checked={doc.attest} onChange={(e) => setDoc({ ...doc, attest: e.target.checked })} className="mt-1" />
                            <span>Yukarıdaki beyanı okudum ve onaylıyorum.</span>
                        </label>
                    </>
                )}
            </FormModal>

            <FormModal open={!!reverse} onClose={() => setReverse(null)} title="Kiracılığı geri aç" submitLabel="Geri al" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!reverse) return;
                    const r = await act.run(() => api.identity.reverseTenancyEnd(reverse.id, { reason: reverse.reason, password: reverse.password }), { invalidate: ["residents"], success: (x) => x.message });
                    if (r) setReverse(null);
                }}>
                <Notice tone="blue">Belge sahte ya da hatalı çıktıysa kiracılık aynı kayıtla, geçmişiyle geri açılır. Dairede bu arada başka kiracı kaydedildiyse geri alınamaz.</Notice>
                <Field label="Gerekçe" required><Textarea required rows={3} value={reverse?.reason ?? ""} onChange={(e) => reverse && setReverse({ ...reverse, reason: e.target.value })} /></Field>
                <Field label="Şifreniz" required><Input required type="password" autoComplete="current-password" value={reverse?.password ?? ""} onChange={(e) => reverse && setReverse({ ...reverse, password: e.target.value })} /></Field>
            </FormModal>
        </Card>
    );
}
