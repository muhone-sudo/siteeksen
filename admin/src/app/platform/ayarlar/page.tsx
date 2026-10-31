"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Button, Card, Field, FormModal, Input, Page, QueryView, Table } from "@/components/ui/kit";
import type { MpSetting } from "@/lib/types";

/** Pazaryeri ayarları (FAZ M4.5): öncelik penceresi, talep süresi, otomatik tamamlama, günlük sınır… Kodda sabit yok. */
export default function PlatformSettingsPage() {
    const meta = useApi(["market-meta"], api.market.meta);
    const act = useAction();
    const [e, setE] = useState<(MpSetting & { v: string }) | null>(null);
    return (
        <Page title="Pazaryeri ayarları" description="Değişiklik işlem kaydına yazılır">
            <ActionFeedback action={act} />
            <Card padded={false}>
                <QueryView q={meta} isEmpty={(m) => m.settings.length === 0}>
                    {(m) => (
                        <Table rows={m.settings} rowKey={(s) => s.key} columns={[
                            { header: "Ayar", cell: (s) => <div><p className="font-medium">{s.description}</p><p className="font-mono text-xs text-gray-500">{s.key}</p></div> },
                            { header: "Değer", cell: (s) => <span className="font-mono">{s.value}</span> },
                            { header: "", cell: (s) => <Button size="sm" variant="ghost" onClick={() => setE({ ...s, v: String(s.value) })}>Düzenle</Button> },
                        ]} />
                    )}
                </QueryView>
            </Card>
            {e && (
                <FormModal open title={e.description} onClose={() => setE(null)} pending={act.pending} error={act.error}
                    onSubmit={async () => {
                        const r = await act.run(() => api.market.platform.saveSetting(e.key, Number(e.v)), { invalidate: ["market-meta"], success: "Ayar kaydedildi" });
                        if (r) setE(null);
                    }}>
                    <Field label="Değer (tam sayı)"><Input type="number" min={0} value={e.v} onChange={(x) => setE({ ...e, v: x.target.value })} /></Field>
                </FormModal>
            )}
        </Page>
    );
}
