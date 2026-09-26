"use client";

import { useState } from "react";
import { ShieldCheck } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Notice, Page, QueryView, ReadOnlyHint, Select, Table, Textarea } from "@/components/ui/kit";
import { date, dateTime, today } from "@/lib/format";
import type { Book, BookIntegrity } from "@/lib/types";

/**
 * Karar ve işletme defterleri (KMK m.32, m.36). Kayıtlar yalnızca EKLENİR;
 * değiştirme/silme veritabanı tetikleyicisiyle engellidir ve her kayıt bir
 * öncekinin hash'ine bağlıdır. Defter her yıl sonundan itibaren bir ay içinde
 * notere kapattırılır.
 */
export default function BooksPage() {
    const year = new Date().getFullYear();
    const [kind, setKind] = useState("DECISION");
    const [y, setY] = useState(year);
    const act = useAction();
    const { canWrite } = useRoles();
    const [book, setBook] = useState<Book | null>(null);
    const entries = useApi(["books", book?.id], () => api.governance.entries(book!.id), !!book);
    const [integrity, setIntegrity] = useState<BookIntegrity | null>(null);
    const [entryOpen, setEntryOpen] = useState(false);
    const [entry, setEntry] = useState({ title: "", body: "", entry_date: today() });
    const [closeOpen, setCloseOpen] = useState(false);
    const [closeForm, setCloseForm] = useState({ notary_ref: "", closed_at: today() });

    const open = async () => {
        setIntegrity(null);
        // Defter yoksa oluşturulur (aynı yıl/tür için tek defter).
        const r = await act.run(() => api.governance.ensureBook(kind, y));
        if (r) setBook(r);
    };

    return (
        <Page title="Defterler" description="Karar defteri (m.32) ve işletme defteri — ekle-yalnız, hash zincirli.">
            {!canWrite && <ReadOnlyHint />}
            <ActionFeedback action={act} />
            <Card>
                <div className="flex flex-wrap items-end gap-2">
                    <Field label="Defter"><Select value={kind} onChange={(e) => setKind(e.target.value)} options={[{ value: "DECISION", label: "Karar defteri" }, { value: "OPERATING", label: "İşletme defteri" }]} /></Field>
                    <Field label="Yıl"><Input type="number" value={y} onChange={(e) => setY(Number(e.target.value))} className="w-28" /></Field>
                    <Button onClick={open} disabled={act.pending}>Aç</Button>
                </div>
            </Card>

            {book && (
                <Card title={`${book.kind === "DECISION" ? "Karar defteri" : "İşletme defteri"} ${book.period_year}`}
                    actions={
                        <div className="flex flex-wrap items-center gap-2">
                            {book.status === "OPEN" ? <Badge tone="green">Açık</Badge> : <Badge>Notere kapatıldı {date(book.notary_closed_at)}</Badge>}
                            <Button size="sm" variant="secondary" disabled={act.pending}
                                onClick={async () => { const r = await act.run(() => api.governance.verifyBook(book.id)); if (r) setIntegrity(r); }}>
                                <ShieldCheck className="h-4 w-4" /> Bütünlüğü doğrula
                            </Button>
                            {canWrite && book.status === "OPEN" && (
                                <>
                                    <Button size="sm" onClick={() => { setEntry({ title: "", body: "", entry_date: today() }); setEntryOpen(true); }}>Kayıt ekle</Button>
                                    <Button size="sm" variant="ghost" onClick={() => setCloseOpen(true)}>Notere kapat</Button>
                                </>
                            )}
                        </div>
                    }>
                    {integrity && <div className="mb-3"><Notice tone={integrity.valid ? "green" : "red"}>{integrity.message}</Notice></div>}
                    <QueryView q={entries} empty="Defterde kayıt yok">
                        {(d) => (
                            <Table rows={d.data} rowKey={(e) => e.id} columns={[
                                { header: "No", cell: (e) => e.entry_no },
                                { header: "Tarih", cell: (e) => date(e.entry_date) },
                                { header: "Kayıt", cell: (e) => <div><p className="font-medium">{e.title}</p><p className="whitespace-pre-line text-xs text-gray-600">{e.body}</p></div> },
                                { header: "Hash", cell: (e) => <span className="font-mono text-[10px] text-gray-400" title={e.entry_hash}>{e.entry_hash.slice(0, 12)}…</span> },
                                { header: "Oluşturma", cell: (e) => dateTime(e.created_at) },
                            ]} />
                        )}
                    </QueryView>
                </Card>
            )}

            <FormModal open={entryOpen} onClose={() => setEntryOpen(false)} title="Deftere kayıt ekle" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!book) return;
                    const r = await act.run(() => api.governance.addEntry(book.id, entry), { invalidate: ["books"], success: (e) => `${e.entry_no} numaralı kayıt eklendi` });
                    if (r) setEntryOpen(false);
                }}>
                <Notice tone="amber">Kayıt eklendikten sonra DEĞİŞTİRİLEMEZ ve SİLİNEMEZ. Düzeltme gerekirse yeni bir kayıtla yapılır.</Notice>
                <Field label="Başlık" required><Input required value={entry.title} onChange={(e) => setEntry({ ...entry, title: e.target.value })} /></Field>
                <Field label="Metin" required><Textarea required rows={6} value={entry.body} onChange={(e) => setEntry({ ...entry, body: e.target.value })} /></Field>
                <Field label="Tarih"><Input type="date" value={entry.entry_date} onChange={(e) => setEntry({ ...entry, entry_date: e.target.value })} /></Field>
            </FormModal>

            <FormModal open={closeOpen} onClose={() => setCloseOpen(false)} title="Defteri notere kapat" submitLabel="Kapat" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!book) return;
                    const r = await act.run(() => api.governance.closeBook(book.id, { ...closeForm, period_year: book.period_year }), {
                        success: (res) => res.warning ? `Defter kapatıldı. ${res.warning}` : "Defter kapatıldı",
                    });
                    if (r) { setCloseOpen(false); setBook({ ...book, status: "CLOSED", notary_closed_at: closeForm.closed_at }); }
                }}>
                <Grid>
                    <Field label="Noter kapanış no"><Input value={closeForm.notary_ref} onChange={(e) => setCloseForm({ ...closeForm, notary_ref: e.target.value })} /></Field>
                    <Field label="Kapanış tarihi"><Input type="date" value={closeForm.closed_at} onChange={(e) => setCloseForm({ ...closeForm, closed_at: e.target.value })} /></Field>
                </Grid>
                <p className="text-xs text-gray-500">KMK m.36: yıl sonundan itibaren bir ay içinde kapattırılmalıdır; süre aşılırsa uyarı verilir.</p>
            </FormModal>
        </Page>
    );
}
