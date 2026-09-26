"use client";

import { useRef, useState } from "react";
import { Download, Upload } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Modal, Page, QueryView, ReadOnlyHint, Select, Stats, Table, Textarea } from "@/components/ui/kit";
import { bytes, dateTime, num } from "@/lib/format";
import type { DocumentRec } from "@/lib/types";

const CATEGORIES = [
    { value: "MANAGEMENT_PLAN", label: "Yönetim planı" }, { value: "DECISION", label: "Karar" }, { value: "BUDGET", label: "İşletme projesi" },
    { value: "ACCOUNTING", label: "Muhasebe" }, { value: "CONTRACT", label: "Sözleşme" }, { value: "INVOICE", label: "Fatura" },
    { value: "INSURANCE", label: "Sigorta" }, { value: "REPORT", label: "Rapor" }, { value: "LEGAL", label: "Hukuki" },
    { value: "PERSONNEL", label: "Personel" }, { value: "TECHNICAL", label: "Teknik" }, { value: "OTHER", label: "Diğer" },
];
const CAT = Object.fromEntries(CATEGORIES.map((c) => [c.value, c.label]));
const VIS = [
    { value: "MANAGEMENT", label: "Yalnız yönetim" },
    { value: "OWNERS", label: "Kat malikleri" },
    { value: "RESIDENTS", label: "Tüm sakinler" },
];

/**
 * Belge arşivi. Her görüntüleme ve indirme erişim kaydına yazılır (KVKK m.12).
 * Dosyanın SHA-256 özeti saklanır; belge sonradan değiştirilirse fark edilir.
 */
export default function DocumentsPage() {
    const [category, setCategory] = useState("");
    const [archived, setArchived] = useState(false);
    const list = useApi(["documents", category, archived], () => api.documents.list({ category, include_archived: archived ? "true" : undefined }));
    const summary = useApi(["documents", "summary"], api.documents.summary);
    const act = useAction();
    const { canWrite } = useRoles();
    const [open, setOpen] = useState(false);
    const fileRef = useRef<HTMLInputElement>(null);
    const [meta, setMeta] = useState({ category: "DECISION", title: "", description: "", visibility: "MANAGEMENT", retention_until: "" });
    const [archiving, setArchiving] = useState<DocumentRec | null>(null);
    const [reason, setReason] = useState("");
    const [logFor, setLogFor] = useState<DocumentRec | null>(null);
    const log = useApi(["documents", "log", logFor?.id], () => api.documents.accessLog(logFor!.id), !!logFor);

    return (
        <Page title="Belge arşivi" description="Yönetim planı, kararlar, sözleşmeler, faturalar. Her erişim kaydedilir."
            actions={canWrite && <Button onClick={() => setOpen(true)}><Upload className="h-4 w-4" /> Belge yükle</Button>}>
            {!canWrite && <ReadOnlyHint />}
            <ActionFeedback action={act} />
            <Stats items={[
                { label: "Belge", value: num(summary.data?.total) },
                { label: "Arşivlenen", value: num(summary.data?.archived) },
                { label: "Toplam boyut", value: bytes(summary.data?.total_size_bytes) },
                { label: "Saklama süresi dolan", value: num(summary.data?.retention_due), tone: "amber" },
            ]} />
            <Card padded={false} title="Belgeler" actions={
                <div className="flex items-center gap-2">
                    <label className="flex items-center gap-1 text-sm"><input type="checkbox" checked={archived} onChange={(e) => setArchived(e.target.checked)} /> Arşivdekiler</label>
                    <Select value={category} onChange={(e) => setCategory(e.target.value)} options={CATEGORIES} placeholder="Tüm kategoriler" />
                </div>
            }>
                <QueryView q={list} empty="Belge yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(x) => x.id} columns={[
                            { header: "Belge", cell: (x) => <div><p className="font-medium">{x.title}</p><p className="text-xs text-gray-500">{x.file_name} · {bytes(x.size_bytes)}{x.version > 1 ? ` · v${x.version}` : ""}</p></div> },
                            { header: "Kategori", cell: (x) => CAT[x.category] ?? x.category },
                            { header: "Görünürlük", cell: (x) => <Badge tone={x.visibility === "MANAGEMENT" ? "gray" : "blue"}>{VIS.find((v) => v.value === x.visibility)?.label ?? x.visibility}</Badge> },
                            { header: "Yükleme", cell: (x) => `${dateTime(x.uploaded_at)} · ${x.uploaded_by_name ?? ""}` },
                            { header: "", cell: (x) => (
                                <div className="flex gap-1">
                                    <Button size="sm" variant="ghost" onClick={() => act.run(() => api.documents.download(x.id, x.file_name))}><Download className="h-3.5 w-3.5" /></Button>
                                    <Button size="sm" variant="ghost" onClick={() => setLogFor(x)}>Erişim</Button>
                                    {canWrite && !x.archived_at && <Button size="sm" variant="ghost" onClick={() => { setReason(""); setArchiving(x); }}>Arşivle</Button>}
                                </div>
                            ) },
                        ]} />
                    )}
                </QueryView>
            </Card>

            <FormModal open={open} onClose={() => setOpen(false)} title="Belge yükle" submitLabel="Yükle" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    const file = fileRef.current?.files?.[0];
                    if (!file) return;
                    const fd = new FormData();
                    fd.append("file", file);
                    for (const [k, v] of Object.entries(meta)) if (v) fd.append(k, v);
                    const r = await act.run(() => api.documents.upload(fd), { invalidate: ["documents"], success: (res) => `Yüklendi (SHA-256 ${res.sha256.slice(0, 12)}…)` });
                    if (r) setOpen(false);
                }}>
                <Field label="Dosya" required><input ref={fileRef} type="file" required className="block w-full text-sm" /></Field>
                <Grid>
                    <Field label="Kategori" required><Select value={meta.category} onChange={(e) => setMeta({ ...meta, category: e.target.value })} options={CATEGORIES} /></Field>
                    <Field label="Görünürlük"><Select value={meta.visibility} onChange={(e) => setMeta({ ...meta, visibility: e.target.value })} options={VIS} /></Field>
                    <Field label="Başlık" hint="Boşsa dosya adı kullanılır"><Input value={meta.title} onChange={(e) => setMeta({ ...meta, title: e.target.value })} /></Field>
                    <Field label="Saklama bitişi"><Input type="date" value={meta.retention_until} onChange={(e) => setMeta({ ...meta, retention_until: e.target.value })} /></Field>
                </Grid>
                <Field label="Açıklama"><Textarea value={meta.description} onChange={(e) => setMeta({ ...meta, description: e.target.value })} /></Field>
            </FormModal>
            <FormModal open={!!archiving} onClose={() => setArchiving(null)} title="Belgeyi arşivle" submitLabel="Arşivle" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!archiving) return;
                    const r = await act.run(() => api.documents.archive(archiving.id, reason), { invalidate: ["documents"], success: "Arşivlendi (silinmedi)" });
                    if (r) setArchiving(null);
                }}>
                <Field label="Gerekçe" required><Textarea required value={reason} onChange={(e) => setReason(e.target.value)} /></Field>
            </FormModal>
            <Modal open={!!logFor} onClose={() => setLogFor(null)} title={`Erişim kaydı — ${logFor?.title ?? ""}`} wide>
                <QueryView q={log} empty="Erişim yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(x) => `${x.accessed_at}-${x.action}`} columns={[
                            { header: "Zaman", cell: (x) => dateTime(x.accessed_at) },
                            { header: "Kişi", cell: (x) => x.user_name ?? "—" },
                            { header: "İşlem", cell: (x) => x.action },
                            { header: "IP", cell: (x) => x.ip_address ?? "—" },
                        ]} />
                    )}
                </QueryView>
            </Modal>
        </Page>
    );
}
