"use client";

import { api } from "@/lib/api";
import { useApi } from "@/lib/use-api";
import { Badge, Card, Notice, Page, QueryView, Table } from "@/components/ui/kit";

const CHANNELS: Record<string, string> = { IN_APP: "Uygulama içi", SMS: "SMS", EMAIL: "E-posta", PUSH: "Anlık bildirim (push)" };

/**
 * Dış sağlayıcıların GERÇEK bağlantı durumu (FAZ H.1.2). Sağlayıcı anahtarları
 * ortam değişkeniyle verilir; bu ekranda girilmez ve hiçbir yerde gösterilmez.
 */
export default function IntegrationsPage() {
    const q = useApi(["integrations"], api.integrations.status);
    return (
        <Page title="Entegrasyon durumu" description="Ödeme, SMS, e-posta ve dosya deposu bağlantıları">
            <Notice tone="blue">
                Sağlayıcı anahtarları sunucu ortam değişkenleriyle verilir (iyzico: <code>IYZICO_*</code>, SMS: <code>NETGSM_*</code>,
                e-posta: <code>SMTP_*</code>, depo: <code>STORAGE_*</code>). Anahtar bu ekranda girilmez ve gösterilmez.
            </Notice>
            <QueryView q={q} empty="Durum alınamadı">
                {(d) => {
                    const delivery = d.data.delivery;
                    const missing = new Set(delivery?.channels_without_provider ?? []);
                    const rows = Object.keys(CHANNELS).map((ch) => ({ ch, ready: !missing.has(ch) }));
                    return (
                        <>
                            {d.unavailable && d.unavailable.length > 0 && (
                                <Notice tone="amber" title="Bazı servislerden durum alınamadı">
                                    {d.unavailable.map((u) => `${u.source}: ${u.reason}`).join(" · ")}
                                </Notice>
                            )}
                            <Card title="Bildirim kanalları" padded={false}>
                                <Table rows={rows} rowKey={(r) => r.ch} columns={[
                                    { header: "Kanal", cell: (r) => CHANNELS[r.ch] },
                                    { header: "Durum", cell: (r) => (r.ready ? <Badge tone="green">Bağlı</Badge> : <Badge tone="amber">Sağlayıcı yok — kuyrukta bekler</Badge>) },
                                ]} />
                            </Card>
                            {delivery?.note && <Notice tone="amber">{delivery.note}</Notice>}
                            <Card title="Kartla ödeme">
                                {d.data.card_payment ? (
                                    d.data.card_payment.ready
                                        ? <Badge tone="green">{d.data.card_payment.provider} bağlı</Badge>
                                        : <Badge tone="amber">{d.data.card_payment.provider} yapılandırılmamış — kart ödemesi kapalı, havale/EFT çalışır</Badge>
                                ) : <span className="text-sm text-gray-500">Bilinmiyor</span>}
                            </Card>
                            <Card title="Dosya deposu">
                                {d.data.storage ? (
                                    <dl className="grid gap-1 text-sm sm:grid-cols-2">
                                        {Object.entries(d.data.storage).map(([k, v]) => (
                                            <div key={k} className="flex gap-2"><dt className="text-gray-500">{k}</dt><dd className="font-mono">{v}</dd></div>
                                        ))}
                                    </dl>
                                ) : <span className="text-sm text-gray-500">Bilinmiyor</span>}
                            </Card>
                        </>
                    );
                }}
            </QueryView>
        </Page>
    );
}
