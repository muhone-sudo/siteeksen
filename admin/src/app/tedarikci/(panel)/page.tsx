"use client";

import { useEffect, useRef, useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, Grid, Input, Notice, Page, QueryView, Select, StatusBadge, Table } from "@/components/ui/kit";
import { date, dateTime, kurus } from "@/lib/format";
import { ACCOUNT_STATUS, DOC_STATUS, DOC_TYPE } from "@/components/market/labels";
import type { MpAccount } from "@/lib/types";

/** Tedarikçi hesabı (FAZ M3): hesap bilgileri, belgeler, incelemeye gönderme. Hesap yoksa açma formu. */
export default function SupplierAccountPage() {
    const me = useApi(["market-me"], api.market.supplierMe);
    const noAccount = (me.error as { response?: { data?: { code?: string } } } | null)?.response?.data?.code === "NO_ACCOUNT";
    return (
        <Page title="Hesabım" description="Usta & Hizmet tedarikçi hesabınız">
            {noAccount ? <CreateAccount /> : (
                <QueryView q={me}>{(acc) => <AccountView acc={acc} />}</QueryView>
            )}
        </Page>
    );
}

function AccountFields({ v, set, disabled }: { v: AccountForm; set: (f: AccountForm) => void; disabled?: boolean }) {
    return (
        <Grid cols={3}>
            <Field label="Ticari unvan" required><Input value={v.trade_name} disabled={disabled} onChange={(e) => set({ ...v, trade_name: e.target.value })} /></Field>
            <Field label="Vergi no / T.C. kimlik no" hint="10 hane vergi no; şahıs işletmesinde 11 hane" required>
                <Input value={v.tax_number} disabled={disabled} inputMode="numeric" maxLength={11} onChange={(e) => set({ ...v, tax_number: e.target.value.replace(/\D/g, "") })} />
            </Field>
            <Field label="Vergi dairesi" required><Input value={v.tax_office} disabled={disabled} onChange={(e) => set({ ...v, tax_office: e.target.value })} /></Field>
        </Grid>
    );
}

type AccountForm = { trade_name: string; tax_number: string; tax_office: string };

function CreateAccount() {
    const act = useAction();
    const [f, setF] = useState<AccountForm>({ trade_name: "", tax_number: "", tax_office: "" });
    const [terms, setTerms] = useState(false);
    return (
        <Card title="Tedarikçi hesabınızı oluşturun">
            <ActionFeedback action={act} />
            <div className="space-y-4">
                <Notice tone="blue">
                    Havuzda görünmek için hesap bilgilerinizi girip vergi levhası (ya da oda kaydı) ve kimlik belgenizi yükleyin, ardından
                    incelemeye gönderin. SiteEksen onayladıktan sonra işletmeleriniz yayına alınabilir.
                </Notice>
                <AccountFields v={f} set={setF} />
                <label className="flex items-start gap-2 text-sm">
                    <input type="checkbox" className="mt-1" checked={terms} onChange={(e) => setTerms(e.target.checked)} />
                    <span>Usta &amp; Hizmet tedarikçi üyelik koşullarını kabul ediyorum.</span>
                </label>
                <Button disabled={!terms || act.pending} onClick={() => act.run(() => api.market.createAccount({ ...f, terms_accepted: true }),
                    { invalidate: ["market-me"], success: "Tedarikçi hesabınız oluşturuldu" })}>Hesabı oluştur</Button>
            </div>
        </Card>
    );
}

function AccountView({ acc }: { acc: MpAccount }) {
    const act = useAction();
    const [f, setF] = useState<AccountForm>({ trade_name: acc.trade_name, tax_number: acc.tax_number, tax_office: acc.tax_office });
    useEffect(() => setF({ trade_name: acc.trade_name, tax_number: acc.tax_number, tax_office: acc.tax_office }), [acc]);
    const draft = acc.status === "DRAFT";
    return (
        <>
            <ActionFeedback action={act} />
            <Card title="Hesap durumu">
                <div className="space-y-2 text-sm">
                    <p>Durum: <StatusBadge value={acc.status} map={ACCOUNT_STATUS} />{acc.reviewed_at && <> · inceleme {dateTime(acc.reviewed_at)}</>}</p>
                    {acc.status_reason && <Notice tone={acc.status === "APPROVED" ? "blue" : "red"} title="İnceleme notu">{acc.status_reason}</Notice>}
                    {acc.status === "DRAFT" && <Notice tone="amber">Bilgilerinizi ve belgelerinizi tamamlayıp incelemeye gönderin. İnceleme sürerken bilgiler değiştirilemez.</Notice>}
                    {acc.status === "REVIEW" && <Notice tone="blue">Hesabınız inceleniyor. Sonuç size bildirilecek.</Notice>}
                    <p>Paket: <Badge tone="blue">{acc.package.name}</Badge> · Bakiye: <strong>{kurus(acc.balance_kurus)}</strong>
                        {acc.package_renews_at && <> · yenileme {date(acc.package_renews_at)}</>}</p>
                </div>
            </Card>
            <Card title="Hesap bilgileri">
                <div className="space-y-3">
                    <AccountFields v={f} set={setF} disabled={!draft} />
                    {draft && (
                        <div className="flex flex-wrap gap-2">
                            <Button variant="ghost" disabled={act.pending} onClick={() => act.run(() => api.market.updateAccount(f), { invalidate: ["market-me"], success: "Kaydedildi" })}>Kaydet</Button>
                            <Button disabled={act.pending} onClick={() => act.run(async () => { await api.market.updateAccount(f); return api.market.submitAccount(); },
                                { invalidate: ["market-me"], success: "Hesabınız incelemeye gönderildi" })}>Kaydet ve incelemeye gönder</Button>
                        </div>
                    )}
                </div>
            </Card>
            <Documents editable={acc.status === "DRAFT" || acc.status === "REVIEW"} canDelete={draft} />
        </>
    );
}

function Documents({ editable, canDelete }: { editable: boolean; canDelete: boolean }) {
    const docs = useApi(["market-docs"], api.market.documents);
    const act = useAction();
    const [type, setType] = useState("TAX_PLATE");
    const fileRef = useRef<HTMLInputElement>(null);
    return (
        <Card title="Belgeler" padded={false}>
            <div className="space-y-3 p-4">
                <ActionFeedback action={act} />
                {editable && (
                    <div className="flex flex-wrap items-end gap-2">
                        <Field label="Belge türü">
                            <Select value={type} onChange={(e) => setType(e.target.value)} options={Object.entries(DOC_TYPE).map(([value, label]) => ({ value, label }))} />
                        </Field>
                        <input ref={fileRef} type="file" accept="application/pdf,image/jpeg,image/png" className="text-sm" />
                        <Button disabled={act.pending} onClick={() => {
                            const file = fileRef.current?.files?.[0];
                            if (!file) return;
                            const form = new FormData();
                            form.append("doc_type", type);
                            form.append("file", file);
                            void act.run(() => api.market.uploadDocument(form), { invalidate: ["market-docs"], success: "Belge yüklendi" })
                                .then(() => { if (fileRef.current) fileRef.current.value = ""; });
                        }}>Yükle</Button>
                        <p className="w-full text-xs text-gray-500">PDF, JPEG ya da PNG; en çok 10 MB. Gerekli: vergi levhası ya da oda kaydı ve kimlik belgesi.</p>
                    </div>
                )}
            </div>
            <QueryView q={docs} empty="Henüz belge yüklenmedi">
                {(d) => (
                    <Table rows={d.data} rowKey={(x) => x.id} columns={[
                        { header: "Tür", cell: (x) => DOC_TYPE[x.doc_type] ?? x.doc_type },
                        { header: "Dosya", cell: (x) => <span className="break-all">{x.file_name}</span> },
                        { header: "Durum", cell: (x) => <div><StatusBadge value={x.status} map={DOC_STATUS} />{x.review_note && <p className="text-xs text-gray-500">{x.review_note}</p>}</div> },
                        { header: "Yüklendi", cell: (x) => dateTime(x.uploaded_at) },
                        { header: "", cell: (x) => (
                            <div className="flex gap-1">
                                <Button size="sm" variant="ghost" onClick={() => act.run(() => api.market.downloadDocument(x.id, x.file_name))}>İndir</Button>
                                {canDelete && x.status === "PENDING" && (
                                    <Button size="sm" variant="ghost" disabled={act.pending} onClick={() => act.run(() => api.market.deleteDocument(x.id), { invalidate: ["market-docs"], success: "Belge silindi" })}>Sil</Button>
                                )}
                            </div>
                        ) },
                    ]} />
                )}
            </QueryView>
        </Card>
    );
}
