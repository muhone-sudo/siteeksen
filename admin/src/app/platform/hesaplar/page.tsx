"use client";

import { useState } from "react";
import Link from "next/link";
import { api } from "@/lib/api";
import { useApi } from "@/lib/use-api";
import { Card, Page, QueryView, StatusBadge, Table, Tabs } from "@/components/ui/kit";
import { dateTime } from "@/lib/format";
import { ACCOUNT_STATUS } from "@/components/market/labels";

const TABS = [{ id: "REVIEW", label: "İncelemede" }, { id: "APPROVED", label: "Onaylı" }, { id: "DRAFT", label: "Taslak" },
    { id: "SUSPENDED", label: "Askıda" }, { id: "", label: "Tümü" }] as const;

export default function PlatformAccountsPage() {
    const [status, setStatus] = useState<(typeof TABS)[number]["id"]>("REVIEW");
    const list = useApi(["mp-accounts", status], () => api.market.platform.accounts(status));
    return (
        <Page title="Tedarikçi hesapları" description="Belge incelemesi, onay, askıya alma">
            <Tabs tabs={TABS.map((t) => ({ id: t.id, label: t.label }))} value={status} onChange={setStatus} />
            <Card padded={false}>
                <QueryView q={list} empty="Bu durumda hesap yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(a) => a.id} columns={[
                            { header: "Unvan", cell: (a) => <Link className="font-medium text-primary hover:underline" href={`/platform/hesaplar/${a.id}`}>{a.trade_name || "(unvan girilmemiş)"}</Link> },
                            { header: "Sahibi", cell: (a) => <div><p>{a.owner_name}</p><p className="text-xs text-gray-500">{a.owner_phone}</p></div> },
                            { header: "Vergi no", cell: (a) => <span className="font-mono">{a.tax_number || "—"}</span> },
                            { header: "Belge / işletme", cell: (a) => `${a.document_count} / ${a.business_count}` },
                            { header: "Durum", cell: (a) => <StatusBadge value={a.status} map={ACCOUNT_STATUS} /> },
                            { header: "Son değişiklik", cell: (a) => dateTime(a.updated_at) },
                        ]} />
                    )}
                </QueryView>
            </Card>
        </Page>
    );
}
