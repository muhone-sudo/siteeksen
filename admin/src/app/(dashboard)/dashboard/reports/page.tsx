"use client";

import { useState } from "react";
import Link from "next/link";
import { Download } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Button, Card, Field, Notice, Page, Select } from "@/components/ui/kit";
import { date } from "@/lib/format";

/**
 * Raporlar (TEST_RAPORU 2.6): PDF / Excel dökümleri gerçek veriden üretilir. Her belgenin
 * sayfa altında içerik özeti (SHA-256 doğrulama kodu) yazar. Çift taraflı muhasebe (mizan)
 * bu sistemde yoktur; mali müşavirin programından alınır.
 */
const LINKS: { href: string; title: string; desc: string }[] = [
    { href: "/dashboard/assessments", title: "Tahakkuk dönemleri", desc: "Dönem bazında tahakkuk, tahsilat ve oran" },
    { href: "/dashboard/accounting", title: "Tahsilat ve borçlular", desc: "Ödemeler ve daire bazında borç" },
    { href: "/dashboard/expenses", title: "Gider özeti", desc: "Kalem bazında gider, faturalı/faturasız ayrımı" },
    { href: "/dashboard/collection", title: "Tahsilat riski", desc: "Açıklanabilir risk puanı ve önerilen eylem" },
    { href: "/dashboard/energy", title: "Enerji analizi", desc: "Tüketim eğilimi ve olağandışı tüketim" },
    { href: "/dashboard/esg", title: "Karbon ayak izi", desc: "Kullanıcının verdiği katsayılarla CO₂e" },
];

function Downloads({ act, onPdf, onXlsx }: { act: ReturnType<typeof useAction>; onPdf: () => Promise<void>; onXlsx?: () => Promise<void> }) {
    return (
        <div className="mt-3 flex gap-2">
            <Button size="sm" disabled={act.pending} onClick={() => act.run(onPdf)}><Download className="h-3.5 w-3.5" /> PDF</Button>
            {onXlsx && <Button size="sm" variant="secondary" disabled={act.pending} onClick={() => act.run(onXlsx)}><Download className="h-3.5 w-3.5" /> Excel</Button>}
        </div>
    );
}

export default function ReportsPage() {
    const act = useAction();
    const thisYear = new Date().getFullYear();
    const [year, setYear] = useState(thisYear);
    const assemblies = useApi(["assemblies"], api.governance.assemblies);
    const budgets = useApi(["budgets"], api.governance.budgets);
    const [assemblyId, setAssemblyId] = useState("");
    const [budgetId, setBudgetId] = useState("");

    return (
        <Page title="Raporlar" description="Gerçek veriden PDF / Excel dökümleri ve özet ekranlar">
            <ActionFeedback action={act} />
            <div className="grid gap-4 lg:grid-cols-2">
                <Card title="Borçlu listesi">
                    <p className="text-sm text-gray-600">Bölüm bazında ödenmemiş bakiye.</p>
                    <Notice tone="amber">Yalnızca yönetimin iç kullanımı içindir; ortak alanlara asılamaz, site gruplarında paylaşılamaz (KVK Kurulu 2026/348).</Notice>
                    <Downloads act={act} onPdf={() => api.reports.debtors("pdf")} onXlsx={() => api.reports.debtors("xlsx")} />
                </Card>
                <Card title="Tahakkuk ve tahsilat özeti">
                    <Field label="Yıl"><Select value={String(year)} onChange={(e) => setYear(Number(e.target.value))} options={[0, 1, 2, 3].map((d) => ({ value: String(thisYear - d), label: String(thisYear - d) }))} /></Field>
                    <p className="mt-2 text-xs text-gray-500">Mizan değildir; çift taraflı muhasebe kaydı mali müşavir programındadır.</p>
                    <Downloads act={act} onPdf={() => api.reports.collections(year, "pdf")} onXlsx={() => api.reports.collections(year, "xlsx")} />
                </Card>
                <Card title="Hazirun cetveli">
                    <Field label="Genel kurul">
                        <Select value={assemblyId} onChange={(e) => setAssemblyId(e.target.value)} placeholder="Seçin"
                            options={(assemblies.data?.data ?? []).map((a) => ({ value: a.id, label: `${date(a.held_at ?? a.scheduled_at)} — ${a.call_number}. toplantı` }))} />
                    </Field>
                    <p className="mt-2 text-xs text-gray-500">Toplantı öncesi imza cetveli olarak, sonrasında katılım işaretli olarak kullanılır.</p>
                    {assemblyId && <Downloads act={act} onPdf={() => api.reports.attendanceSheet(assemblyId, "pdf")} onXlsx={() => api.reports.attendanceSheet(assemblyId, "xlsx")} />}
                </Card>
                <Card title="İşletme projesi">
                    <Field label="Proje">
                        <Select value={budgetId} onChange={(e) => setBudgetId(e.target.value)} placeholder="Seçin"
                            options={(budgets.data?.data ?? []).map((b) => ({ value: b.id, label: `${b.period_year} — ${b.status}` }))} />
                    </Field>
                    {budgetId && <Downloads act={act} onPdf={() => api.reports.budget(budgetId, "pdf")} onXlsx={() => api.reports.budget(budgetId, "xlsx")} />}
                </Card>
            </div>
            <p className="text-sm text-gray-500">Karar defteri dökümü: Yönetişim → Defterler ekranındaki &quot;PDF&quot; düğmesi (zincir doğrulamasıyla).</p>
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                {LINKS.map((l) => (
                    <Link key={l.href} href={l.href}>
                        <Card className="h-full transition hover:ring-2 hover:ring-primary/30">
                            <p className="font-semibold text-gray-900 dark:text-white">{l.title}</p>
                            <p className="mt-1 text-sm text-gray-500">{l.desc}</p>
                        </Card>
                    </Link>
                ))}
            </div>
        </Page>
    );
}
