"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Notice, Page, QueryView, Select, StatusBadge, Textarea } from "@/components/ui/kit";
import { AuthPhoto } from "@/components/market/service-photo";
import { AI_VERDICT, PHOTO_STATUS } from "@/components/market/labels";
import { dateTime } from "@/lib/format";
import type { PhotoReview } from "@/lib/types";

const SOURCE: Record<string, string> = { SERVICE_PHOTO: "Hizmet fotoğrafı", REQUEST_PHOTO: "Talep fotoğrafı" };
const DECISION: Record<string, string> = { OCR: "OCR (otomatik)", AI: "Yapay zekâ (otomatik)", PLATFORM: "Platform" };

/** Fotoğraf denetimi (FAZ M13.4): OCR iletişim bilgisi bulursa reddeder; yapay zekâ açıksa temizleri onaylar; kalanlar burada
 *  elle onaylanır ya da gerekçeyle reddedilir. Otomatik onaylananlar da buradan kaldırılabilir. */
export default function PlatformPhotosPage() {
    const [status, setStatus] = useState("REVIEW");
    const q = useApi(["mp-photos", status], () => api.market.platform.photos(status));
    const act = useAction();
    const [rej, setRej] = useState<{ x: PhotoReview; reason: string } | null>(null);
    const inv = ["mp-photos"];
    return (
        <Page title="Fotoğraf denetimi" description="Hizmet ve talep fotoğrafları vitrine ve tedarikçilere yalnız onaydan sonra gösterilir">
            <ActionFeedback action={act} />
            <div className="max-w-xs">
                <Field label="Durum">
                    <Select value={status} onChange={(e) => setStatus(e.target.value)} options={[{ value: "REVIEW", label: "Elle onay bekleyen" },
                        { value: "PENDING", label: "Denetimde (OCR / yapay zekâ)" }, { value: "APPROVED", label: "Yayında" },
                        { value: "REJECTED", label: "Reddedilen" }, { value: "", label: "Hepsi" }]} />
                </Field>
            </div>
            <QueryView q={q} empty="Bu durumda fotoğraf yok">
                {(d) => (
                    <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
                        {d.data.map((x) => (
                            <Card key={x.id} title={x.context || SOURCE[x.source]}>
                                <div className="space-y-2 text-sm">
                                    <AuthPhoto path={api.market.platform.photoImagePath(x.id)} className="max-h-64 w-full rounded object-contain bg-gray-50" />
                                    <p className="flex flex-wrap items-center gap-1">
                                        <StatusBadge value={x.status} map={PHOTO_STATUS} /> <Badge tone="gray">{SOURCE[x.source]}</Badge>
                                        {x.ai_verdict && <StatusBadge value={x.ai_verdict} map={AI_VERDICT} />}
                                    </p>
                                    <p className="text-xs text-gray-500">{x.owner} · {dateTime(x.created_at)}{x.decision_source && ` · karar: ${DECISION[x.decision_source]}`}</p>
                                    {x.ocr_findings.length > 0 && <Notice tone="red" title="OCR iletişim bilgisi buldu">{x.ocr_findings.join(", ")}</Notice>}
                                    {x.ai_categories.length > 0 && <p className="text-xs">Yapay zekâ: {x.ai_categories.join(", ")}</p>}
                                    {x.ai_reason && <p className="text-xs text-gray-600">{x.ai_provider}: {x.ai_reason}</p>}
                                    {x.reason && <p className="text-xs text-gray-600">Gerekçe: {x.reason}</p>}
                                    {x.last_error && <p className="text-xs text-amber-700">Hata: {x.last_error}</p>}
                                    {x.ocr_text && (
                                        <details className="text-xs"><summary className="cursor-pointer text-gray-500">OCR metni</summary>
                                            <pre className="mt-1 whitespace-pre-wrap">{x.ocr_text}</pre></details>
                                    )}
                                    <div className="flex flex-wrap gap-1 pt-1">
                                        {["PENDING", "REVIEW", "REJECTED"].includes(x.status) && (
                                            <Button size="sm" disabled={act.pending}
                                                onClick={() => act.run(() => api.market.platform.approvePhoto(x.id), { invalidate: inv, success: "Fotoğraf onaylandı" })}>Onayla</Button>
                                        )}
                                        {["PENDING", "REVIEW", "APPROVED"].includes(x.status) && (
                                            <Button size="sm" variant="secondary" onClick={() => setRej({ x, reason: "" })}>{x.status === "APPROVED" ? "Kaldır" : "Reddet"}</Button>
                                        )}
                                        {["REVIEW", "REJECTED"].includes(x.status) && (
                                            <Button size="sm" variant="ghost" disabled={act.pending}
                                                onClick={() => act.run(() => api.market.platform.recheckPhoto(x.id), { invalidate: inv, success: "Yeniden denetime alındı" })}>Yeniden denetle</Button>
                                        )}
                                    </div>
                                </div>
                            </Card>
                        ))}
                    </div>
                )}
            </QueryView>
            {rej && (
                <FormModal open title={rej.x.status === "APPROVED" ? "Fotoğrafı kaldır" : "Fotoğrafı reddet"} submitLabel={rej.x.status === "APPROVED" ? "Kaldır" : "Reddet"}
                    pending={act.pending} error={act.error} onClose={() => setRej(null)}
                    onSubmit={async () => {
                        const r = await act.run(() => api.market.platform.rejectPhoto(rej.x.id, rej.reason), { invalidate: inv, success: "Reddedildi; yükleyene bildirildi" });
                        if (r) setRej(null);
                    }}>
                    <Field label="Gerekçe (yükleyene gösterilir)" required><Textarea value={rej.reason} onChange={(e) => setRej({ ...rej, reason: e.target.value })} /></Field>
                </FormModal>
            )}
        </Page>
    );
}
