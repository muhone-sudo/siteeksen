"use client";

import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Notice, Page, QueryView, Stats, StatusBadge, Table } from "@/components/ui/kit";
import { num, tl } from "@/lib/format";
import { RISK } from "@/lib/labels";

const ACTION: Record<string, string> = {
    NONE: "Eylem gerekmez", EARLY_REMINDER: "Erken hatırlatma", INSTALLMENT: "Taksit önerisi",
    PERSONAL_CONTACT: "Kişisel görüşme", LEGAL_REVIEW: "Hukuki değerlendirme",
};

/**
 * Tahsilat riski. Puan, ödeme geçmişinden AÇIK bir formülle hesaplanır; her
 * puanın gerekçesi (etkenler) gösterilir. YZ kullanılmaz. Öneri bir yardımcıdır:
 * otomatik yaptırım uygulanmaz (KVKK m.11/1-g: yalnız otomatik işlemeye dayalı
 * aleyhe sonuca itiraz hakkı).
 */
export default function CollectionPage() {
    const q = useApi(["collection", "risk"], api.analytics.risk);
    const act = useAction();
    const { canWrite } = useRoles();
    const t = q.data?.totals ?? {};

    return (
        <Page title="Tahsilat riski" description="Açıklanabilir risk puanı ve önerilen eylem."
            actions={canWrite && <Button variant="secondary" disabled={act.pending} onClick={() => act.run(() => api.analytics.riskSnapshot(), { success: (r) => `${r.saved} dairenin puanı bugünün tarihiyle saklandı (${r.skipped} dairenin geçmişi yok)` })}>Bugünü kaydet</Button>}>
            <ActionFeedback action={act} />
            <Stats items={[
                { label: "Kritik", value: num(t.CRITICAL), tone: "red" },
                { label: "Yüksek", value: num(t.HIGH), tone: "red" },
                { label: "Orta", value: num(t.MEDIUM), tone: "amber" },
                { label: "Düşük", value: num(t.LOW), tone: "green" },
            ]} />
            <Card padded={false}>
                <QueryView q={q} empty="Daire yok">
                    {(d) => (
                        <div className="space-y-3">
                            <Table rows={d.data} rowKey={(r) => r.unit_id} columns={[
                                { header: "Daire", cell: (r) => r.unit_name },
                                { header: "Puan", cell: (r) => <b>{r.risk_score}</b> },
                                { header: "Risk", cell: (r) => <div className="flex gap-1"><StatusBadge value={r.risk_category} map={RISK} />{!r.reliable && <Badge>Az veri</Badge>}</div> },
                                { header: "Borç", cell: (r) => tl(r.current_debt) },
                                { header: "Ödenmemiş", cell: (r) => `${r.unpaid}/${r.total_assessments}` },
                                { header: "En uzun gecikme", cell: (r) => `${r.longest_overdue_days} gün` },
                                { header: "Öneri", cell: (r) => <div><p>{ACTION[r.suggested_action] ?? r.suggested_action}</p><p className="text-xs text-gray-500">{r.suggested_action_reason}</p></div> },
                                { header: "Etkenler", cell: (r) => <span className="text-xs text-gray-500">{r.factors.map((f) => `${f.detail} (+${f.points})`).join(" · ")}</span> },
                            ]} />
                            <div className="space-y-2 p-4">
                                <Notice tone="blue">{d.method}</Notice>
                                <Notice tone="amber">{d.action_note}</Notice>
                            </div>
                        </div>
                    )}
                </QueryView>
            </Card>
        </Page>
    );
}
