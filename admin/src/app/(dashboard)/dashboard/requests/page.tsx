"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Button, Card, Page, QueryView, Select, StatusBadge, Table } from "@/components/ui/kit";
import { dateTime } from "@/lib/format";
import { opts, PRIORITY, REQUEST_STATUS } from "@/lib/labels";

/** Yönetimin tetikleyebileceği geçişler (arka uçla aynı: OPEN→IN_PROGRESS→RESOLVED; kapatmayı sakin onaylar). */
const NEXT: Record<string, { status: string; label: string }> = {
    OPEN: { status: "IN_PROGRESS", label: "İşleme al" },
    IN_PROGRESS: { status: "RESOLVED", label: "Çözüldü işaretle" },
};

export default function RequestsPage() {
    const [status, setStatus] = useState("");
    const q = useApi(["requests", status], () => api.requests.list(status));
    const act = useAction();
    const { roles } = useRoles();
    // Talep durumunu yönetim ve görevli ilerletir (denetçi okur).
    const canAdvance = roles.some((r) => ["MANAGER", "BOARD_MEMBER", "STAFF"].includes(r));

    return (
        <Page
            title="Talepler"
            description="Arıza ve istek bildirimleri. 'Çözüldü' işaretlenen talep, sakin onayladığında kapanır."
        >
            <ActionFeedback action={act} />
            <Card>
                <div className="mb-4">
                    <Select value={status} onChange={(e) => setStatus(e.target.value)} options={opts(REQUEST_STATUS)} placeholder="Tüm durumlar" className="max-w-xs" />
                </div>
                <QueryView q={q} empty="Talep yok">
                    {(d) => (
                        <Table
                            rows={d.data}
                            rowKey={(r) => r.id}
                            columns={[
                                { header: "No", cell: (r) => <span className="font-mono text-xs">{r.ticket_number}</span> },
                                { header: "Başlık", cell: (r) => <div><p className="font-medium">{r.title}</p><p className="text-xs text-gray-500">{r.description}</p></div> },
                                { header: "Öncelik", cell: (r) => <StatusBadge value={r.priority} map={PRIORITY} /> },
                                { header: "Durum", cell: (r) => <StatusBadge value={r.status} map={REQUEST_STATUS} /> },
                                { header: "Açılış", cell: (r) => dateTime(r.created_at) },
                                {
                                    header: "",
                                    cell: (r) =>
                                        canAdvance && NEXT[r.status] ? (
                                            <Button
                                                size="sm"
                                                disabled={act.pending}
                                                onClick={() =>
                                                    act.run(() => api.requests.setStatus(r.id, NEXT[r.status].status), {
                                                        invalidate: ["requests", "dashboard"],
                                                        success: `${r.ticket_number}: durum güncellendi`,
                                                    })
                                                }
                                            >
                                                {NEXT[r.status].label}
                                            </Button>
                                        ) : null,
                                },
                            ]}
                        />
                    )}
                </QueryView>
            </Card>
        </Page>
    );
}
