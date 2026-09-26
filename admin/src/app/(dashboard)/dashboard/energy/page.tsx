"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useApi } from "@/lib/use-api";
import { Badge, Card, Notice, Page, QueryView, Select, Table } from "@/components/ui/kit";
import { num } from "@/lib/format";
import { METER_TYPES } from "@/lib/labels";

/**
 * Enerji analizi. Hesaplar kodda yazılı formüllerle yapılır (medyan sapması,
 * dönem karşılaştırması) — "yapay zekâ" YOKTUR ve öyle sunulmaz.
 */
export default function EnergyPage() {
    const [type, setType] = useState("HEAT");
    const [months, setMonths] = useState(12);
    const trends = useApi(["energy", "trends", type, months], () => api.analytics.energyTrends(type, months));
    const anomalies = useApi(["energy", "anomalies", type], () => api.analytics.energyAnomalies(type));

    return (
        <Page title="Enerji analizi" description="Tüketim eğilimi ve olağandışı tüketim (açıklanabilir formül, YZ yok)."
            actions={
                <>
                    <Select value={type} onChange={(e) => setType(e.target.value)} options={METER_TYPES} />
                    <Select value={String(months)} onChange={(e) => setMonths(Number(e.target.value))} options={[6, 12, 24, 36].map((m) => ({ value: String(m), label: `Son ${m} ay` }))} />
                </>
            }>
            <Card title="Dönemsel tüketim" padded={false}>
                <QueryView q={trends} isEmpty={(d) => d.periods.length === 0} empty="Bu tür için okuma yok">
                    {(d) => (
                        <div className="space-y-3 p-4">
                            {d.month_over_month && (
                                <p className="text-sm">Son ay değişimi: <b>{d.month_over_month.change_pct === null ? "—" : `%${d.month_over_month.change_pct}`}</b>{" "}
                                    <Badge tone={d.month_over_month.direction === "UP" ? "red" : d.month_over_month.direction === "DOWN" ? "green" : "gray"}>{d.month_over_month.direction}</Badge>
                                </p>
                            )}
                            <Table rows={d.periods} rowKey={(p) => p.period} columns={[
                                { header: "Dönem", cell: (p) => p.period },
                                { header: "Toplam tüketim", cell: (p) => num(p.total_consumption) },
                                { header: "Okunan daire", cell: (p) => p.units_with_reading },
                                { header: "Okuma", cell: (p) => p.reading_count },
                            ]} />
                            <Notice tone="blue">{d.note}</Notice>
                        </div>
                    )}
                </QueryView>
            </Card>
            <Card title="Olağandışı tüketim" padded={false}>
                <QueryView q={anomalies} isEmpty={() => false}>
                    {(d) => (
                        <div className="space-y-3 p-4">
                            {d.anomalies.length === 0 ? <p className="text-sm text-gray-500">Olağandışı tüketim bulunmadı.</p> : (
                                <Table rows={d.anomalies} rowKey={(a) => a.unit_id} columns={[
                                    { header: "Daire", cell: (a) => a.unit_name },
                                    { header: "Değer", cell: (a) => num(a.value) },
                                    { header: "Medyan", cell: (a) => num(a.median) },
                                    { header: "Sapma", cell: (a) => `%${a.deviation_pct}` },
                                    { header: "Önem", cell: (a) => <Badge tone={a.severity === "HIGH" ? "red" : a.severity === "MEDIUM" ? "amber" : "gray"}>{a.severity}</Badge> },
                                    { header: "Gerekçe", cell: (a) => <span className="text-xs">{a.reason}</span> },
                                ]} />
                            )}
                            <Notice tone="blue">{d.basis} {d.note}</Notice>
                        </div>
                    )}
                </QueryView>
            </Card>
        </Page>
    );
}
