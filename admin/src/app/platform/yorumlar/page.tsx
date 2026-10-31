"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Page, QueryView, Select, Table, Textarea } from "@/components/ui/kit";
import { dateTime } from "@/lib/format";
import type { MpReview } from "@/lib/types";

/** Yorum denetimi (FAZ M7.7): yorum silinmez; gerekçeyle gizlenir ve puan özetinden çıkar. */
export default function PlatformReviewsPage() {
    const [hidden, setHidden] = useState("0");
    const q = useApi(["mp-reviews", hidden], () => api.market.platform.reviews(hidden));
    const act = useAction();
    const [pick, setPick] = useState<{ r: MpReview; reason: string } | null>(null);
    return (
        <Page title="Yorum denetimi" description="Şikâyet edilen ya da kişisel veri içeren yorumlar gerekçeyle gizlenir; silinmez">
            <ActionFeedback action={act} />
            <div className="max-w-xs">
                <Field label="Göster">
                    <Select value={hidden} onChange={(e) => setHidden(e.target.value)} options={[{ value: "0", label: "Yayındakiler" }, { value: "1", label: "Gizlenenler" }, { value: "", label: "Hepsi" }]} />
                </Field>
            </div>
            <Card padded={false}>
                <QueryView q={q} empty="Yorum yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(r) => r.id} columns={[
                            { header: "Tarih", cell: (r) => dateTime(r.created_at) },
                            { header: "İşletme", cell: (r) => r.business_name },
                            { header: "Puan", cell: (r) => `${r.rating}/5` },
                            { header: "Yorum", cell: (r) => <div><p>{r.comment || "—"}</p>{r.reply && <p className="text-xs text-gray-500">Yanıt: {r.reply}</p>}</div> },
                            { header: "Durum", cell: (r) => r.hidden_at ? <div><Badge tone="red">Gizli</Badge><p className="text-xs text-gray-500">{r.hidden_reason}</p></div> : <Badge tone="green">Yayında</Badge> },
                            { header: "", cell: (r) => !r.hidden_at && <Button size="sm" variant="ghost" onClick={() => setPick({ r, reason: "" })}>Gizle</Button> },
                        ]} />
                    )}
                </QueryView>
            </Card>
            {pick && (
                <FormModal open title="Yorumu gizle" submitLabel="Gizle" pending={act.pending} error={act.error} onClose={() => setPick(null)}
                    onSubmit={async () => {
                        const r = await act.run(() => api.market.platform.hideReview(pick.r.id, pick.reason), { invalidate: ["mp-reviews"], success: "Yorum gizlendi" });
                        if (r) setPick(null);
                    }}>
                    <p className="text-sm">“{pick.r.comment}” — {pick.r.business_name}</p>
                    <Field label="Gerekçe" required><Textarea value={pick.reason} onChange={(e) => setPick({ ...pick, reason: e.target.value })} /></Field>
                </FormModal>
            )}
        </Page>
    );
}
