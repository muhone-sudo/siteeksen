"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Input, Notice, Page, QueryView } from "@/components/ui/kit";
import { dateTime } from "@/lib/format";
import type { MpReview } from "@/lib/types";

/** İşletmelerime verilen puanlar (FAZ M7.5, K11): yalnız tamamlanan işlere; her yoruma bir kez yanıt. */
export default function SupplierReviewsPage() {
    const q = useApi(["market-reviews"], api.market.reviews);
    return (
        <Page title="Puanlar" description="Tamamlanan işler için alıcıların değerlendirmeleri; her yoruma bir kez yanıt verebilirsiniz">
            <QueryView q={q} empty="Henüz değerlendirme yok">
                {(d) => <div className="space-y-3">{d.data.map((r) => <ReviewCard key={r.id} r={r} />)}</div>}
            </QueryView>
        </Page>
    );
}

function ReviewCard({ r }: { r: MpReview }) {
    const act = useAction();
    const [reply, setReply] = useState("");
    return (
        <Card title={`${r.business_name ?? ""} — ${"★".repeat(r.rating)}${"☆".repeat(5 - r.rating)}`}>
            <ActionFeedback action={act} />
            <div className="space-y-2 text-sm">
                <p className="text-gray-500">{dateTime(r.created_at)}</p>
                {r.comment && <p>“{r.comment}”</p>}
                {r.hidden_at && <Notice tone="amber" title="Platform bu yorumu gizledi">{r.hidden_reason}</Notice>}
                {r.reply ? (
                    <p><Badge tone="blue">Yanıtınız</Badge> {r.reply}</p>
                ) : (
                    <div className="flex gap-2">
                        <Input value={reply} placeholder="Yanıtınız (bir kez yazılır)" onChange={(e) => setReply(e.target.value)} />
                        <Button disabled={act.pending || !reply.trim()}
                            onClick={() => act.run(() => api.market.replyReview(r.id, reply), { invalidate: ["market-reviews"], success: "Yanıt yayımlandı" })}>Yanıtla</Button>
                    </div>
                )}
            </div>
        </Card>
    );
}
