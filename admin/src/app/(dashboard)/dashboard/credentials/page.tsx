"use client";

import { Card, Notice, Page } from "@/components/ui/kit";

/**
 * Entegrasyon anahtarları.
 *
 * Kimlik bilgisi kasası YAZILMADI (sunucu 501 döner): ödeme, SMS, e-posta ve
 * push sağlayıcılarından hiçbiri koda bağlı değildir ve sağlayıcı anahtarını
 * saklamak için alan düzeyinde şifreli bir kasa gerekir. Önceki sürüm bu
 * ekranda 7 entegrasyonu "aktif" gösteriyordu; hiçbiri çalışmıyordu.
 */
export default function CredentialsPage() {
    return (
        <Page title="Entegrasyon anahtarları" description="Harici sağlayıcı bağlantıları">
            <Notice tone="amber" title="Entegrasyon kasası henüz yok">
                Ödeme (iyzico), SMS, e-posta ve anlık bildirim sağlayıcıları sisteme bağlı değildir. Bu kanallara gönderilen bildirimler kuyrukta bekler ve
                “gönderildi” sayılmaz; çevrimiçi ödeme alınmaz (yönetici onaylı havale/EFT akışı çalışır).
            </Notice>
            <Card title="Bugün çalışan kanallar">
                <ul className="list-inside list-disc space-y-1 text-sm text-gray-700 dark:text-gray-300">
                    <li>Uygulama içi bildirim (sakin uygulamasında ve panelde görünür)</li>
                    <li>Yönetici onaylı tahsilat (havale / EFT dekontuyla)</li>
                    <li>Belge depolama (yerel disk ya da S3 uyumlu depolama — sunucu yapılandırmasıyla)</li>
                </ul>
            </Card>
        </Page>
    );
}
