"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Button, Card, Field, Grid, Input, Notice, Page, QueryView, Table } from "@/components/ui/kit";
import { num } from "@/lib/format";
import { METER_TYPES } from "@/lib/labels";
import type { CarbonResult } from "@/lib/types";

const TYPE_LABEL = Object.fromEntries(METER_TYPES.map((t) => [t.value, t.label]));

/**
 * Karbon ayak izi. Emisyon katsayıları KODA GÖMÜLÜ DEĞİLDİR: kullanıcı,
 * kaynağını belirterek girer (ör. ulusal elektrik şebekesi katsayısı yıldan
 * yıla değişir). Bileşik "sürdürülebilirlik skoru" üretilmez — kabul görmüş
 * bir formülü yoktur.
 */
export default function EsgPage() {
    const [range, setRange] = useState({ from: "", to: "" });
    const consumption = useApi(["esg", range.from, range.to], () => api.analytics.esgConsumption(range));
    const act = useAction();
    const [factors, setFactors] = useState<Record<string, string>>({});
    const [source, setSource] = useState("");
    const [result, setResult] = useState<CarbonResult | null>(null);

    return (
        <Page title="Karbon ayak izi" description="Ölçülen tüketimden CO₂e hesabı — katsayılar ve kaynağı sizden.">
            <Card title="Tüketim">
                <Grid>
                    <Field label="Başlangıç"><Input type="date" value={range.from} onChange={(e) => setRange({ ...range, from: e.target.value })} /></Field>
                    <Field label="Bitiş"><Input type="date" value={range.to} onChange={(e) => setRange({ ...range, to: e.target.value })} /></Field>
                </Grid>
                <div className="mt-4">
                    <QueryView q={consumption} isEmpty={(d) => d.consumption.length === 0} empty="Bu aralıkta okuma yok">
                        {(d) => (
                            <div className="space-y-3">
                                <Table rows={d.consumption} rowKey={(c) => c.meter_type} columns={[
                                    { header: "Tür", cell: (c) => TYPE_LABEL[c.meter_type] ?? c.meter_type },
                                    { header: "Toplam tüketim", cell: (c) => num(c.total_consumption) },
                                    { header: "Sayaç", cell: (c) => c.meter_count },
                                    { header: "Okuma", cell: (c) => c.reading_count },
                                    { header: "Katsayı (kgCO₂e / birim)", cell: (c) => (
                                        <Input className="w-32" type="number" step="0.0001" value={factors[c.meter_type] ?? ""} onChange={(e) => setFactors({ ...factors, [c.meter_type]: e.target.value })} />
                                    ) },
                                ]} />
                                <Field label="Katsayı kaynağı" required hint="ör. 'TEİAŞ 2025 şebeke emisyon faktörü' — sonuçla birlikte saklanır">
                                    <Input value={source} onChange={(e) => setSource(e.target.value)} />
                                </Field>
                                <Button disabled={act.pending || !source}
                                    onClick={async () => {
                                        const emission_factors = Object.fromEntries(Object.entries(factors).filter(([, v]) => v !== "").map(([k, v]) => [k, Number(v)]));
                                        const r = await act.run(() => api.analytics.carbon({ ...range, emission_factors, emission_factor_source: source }));
                                        if (r) setResult(r);
                                    }}>
                                    Hesapla
                                </Button>
                                <Notice tone="blue">{d.note}</Notice>
                            </div>
                        )}
                    </QueryView>
                </div>
            </Card>
            <ActionFeedback action={act} />
            {result && (
                <Card title={`Toplam ${num(result.total_co2e_kg)} kg CO₂e`}>
                    <Table rows={result.lines} rowKey={(l) => l.meter_type} columns={[
                        { header: "Tür", cell: (l) => TYPE_LABEL[l.meter_type] ?? l.meter_type },
                        { header: "Tüketim", cell: (l) => num(l.consumption) },
                        { header: "Katsayı", cell: (l) => l.emission_factor },
                        { header: "kg CO₂e", cell: (l) => <b>{num(l.co2e_kg)}</b> },
                    ]} />
                    <p className="mt-3 text-xs text-gray-500">{result.method} {result.note}</p>
                </Card>
            )}
        </Page>
    );
}
