"use client";

import { useState } from "react";
import { Upload } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Button, Card, Field, FormModal, Input, Notice, QueryView, Table, Textarea } from "@/components/ui/kit";
import { date, tl, today } from "@/lib/format";

/**
 * Açılış (devir) bakiyesi: önceki yönetimden devreden borçlar (FAZ 8.1, 034).
 * Devir; bakiyeye, borçlu listesine ve ödeme akışına girer. Dönem özetine girmez
 * ve OTOMATİK GECİKME TAZMİNATI İŞLETİLMEZ (önceki hesap bilinmez; çift tahsilat olurdu).
 */
export function OpeningBalances({ canWrite }: { canWrite: boolean }) {
    const q = useApi(["opening-balances"], api.finance.openingBalances);
    const units = useApi(["units"], api.identity.units);
    const act = useAction();
    const [open, setOpen] = useState(false);
    const [due, setDue] = useState(today());
    const [text, setText] = useState("");

    const byLabel = new Map((units.data?.data ?? []).map((u) => [`${u.block}-${u.door_number}`.toUpperCase(), u.id]));
    const items: { unit_id: string; amount: number; description?: string }[] = [];
    const errors: string[] = [];
    text.split(/\r?\n/).forEach((line, i) => {
        if (!line.trim()) return;
        const [unit = "", amount = "", description = ""] = line.split(/[;\t]/);
        const id = byLabel.get(unit.trim().toUpperCase().replace(/\s*-\s*/, "-"));
        const t = amount.trim();
        const n = Number(t.includes(",") ? t.replace(/\./g, "").replace(",", ".") : t);
        if (!id) return errors.push(`${i + 1}. satır: "${unit.trim()}" dairesi bulunamadı`);
        if (!(n > 0)) return errors.push(`${i + 1}. satır: tutar sıfırdan büyük olmalı`);
        items.push({ unit_id: id, amount: n, ...(description.trim() ? { description: description.trim() } : {}) });
    });

    return (
        <Card
            title="Devir bakiyeleri"
            actions={canWrite && <Button size="sm" variant="secondary" onClick={() => setOpen(true)}><Upload className="h-4 w-4" /> Devir gir</Button>}
            padded={false}
        >
            <ActionFeedback action={act} />
            <QueryView q={q} empty="Devir bakiyesi girilmemiş">
                {(d) => (
                    <Table
                        rows={d.data}
                        rowKey={(o) => o.id}
                        columns={[
                            { header: "Daire", cell: (o) => o.unit },
                            { header: "Tutar", cell: (o) => tl(o.amount) },
                            { header: "Ödenen", cell: (o) => tl(o.paid_amount) },
                            { header: "Vade", cell: (o) => date(o.due_date) },
                            { header: "Açıklama", cell: (o) => o.description },
                            ...(canWrite ? [{
                                header: "",
                                cell: (o: { id: string; paid_amount: number }) => o.paid_amount === 0 ? (
                                    <Button size="sm" variant="ghost" disabled={act.pending}
                                        onClick={() => act.run(() => api.finance.cancelOpeningBalance(o.id), { invalidate: ["opening-balances", "debtors"], success: "Devir kaydı iptal edildi" })}>
                                        İptal
                                    </Button>
                                ) : null,
                            }] : []),
                        ]}
                    />
                )}
            </QueryView>

            <FormModal
                open={open}
                onClose={() => setOpen(false)}
                title="Devir bakiyesi gir"
                pending={act.pending}
                error={act.error}
                onSubmit={async () => {
                    if (errors.length || items.length === 0) return;
                    const r = await act.run(() => api.finance.createOpeningBalances({ due_date: due, items }), {
                        invalidate: ["opening-balances", "debtors"],
                        success: (x) => `${x.created} devir kaydı girildi`,
                    });
                    if (r) { setOpen(false); setText(""); }
                }}
            >
                <Notice tone="amber">
                    Devir tutarına önceki yönetimin işlettiği gecikme tazminatı dahil edilmelidir; sistem devreden borca otomatik tazminat işletmez.
                    Her daireye bir devir kaydı girilir; hepsi tek seferde kaydedilir.
                </Notice>
                <Field label="Vade tarihi" required><Input type="date" required value={due} onChange={(e) => setDue(e.target.value)} /></Field>
                <p className="text-sm text-gray-600 dark:text-gray-400">Her satıra: <code>daire;tutar;açıklama</code> (daire &quot;A-3&quot; biçiminde).</p>
                <Textarea rows={8} value={text} onChange={(e) => setText(e.target.value)} placeholder={"A-3;1.500,50;Önceki yönetimden devir\nB-1;250"} />
                {errors.length > 0
                    ? <Notice tone="red" title="Düzeltilmesi gereken satırlar">{errors.slice(0, 10).join(" · ")}</Notice>
                    : items.length > 0 && <Notice tone="blue">{items.length} daire, toplam {tl(items.reduce((a, x) => a + x.amount, 0))}.</Notice>}
            </FormModal>
        </Card>
    );
}
