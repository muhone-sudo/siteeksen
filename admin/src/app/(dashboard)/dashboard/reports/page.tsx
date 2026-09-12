'use client';

import { useState } from 'react';
import apiClient from '@/lib/api-client';
import { NotImplementedNotice, toUserMessage } from '@/components/ui/data-state';

type ReportFormat = 'pdf' | 'xlsx';

export default function ReportsPage() {
    const [selectedPeriod, setSelectedPeriod] = useState('monthly');
    const [selectedReport, setSelectedReport] = useState('financial');
    const [generatingFormat, setGeneratingFormat] = useState<ReportFormat | null>(null);
    const [actionError, setActionError] = useState<string | null>(null);

    const reports = [
        {
            id: 'financial',
            title: 'Finansal Rapor',
            description: 'Gelir-gider özeti, tahsilat oranları',
            icon: '💰',
        },
        {
            id: 'collection',
            title: 'Tahsilat Raporu',
            description: 'Aidat tahsilat durumu ve borç analizi',
            icon: '📊',
        },
        {
            id: 'expense',
            title: 'Gider Raporu',
            description: 'Kategorilere göre gider dağılımı',
            icon: '📉',
        },
        {
            id: 'resident',
            title: 'Sakin Raporu',
            description: 'Sakin istatistikleri ve demografik bilgiler',
            icon: '👥',
        },
        {
            id: 'maintenance',
            title: 'Bakım Raporu',
            description: 'Teknik bakım ve onarım istatistikleri',
            icon: '🔧',
        },
        {
            id: 'energy',
            title: 'Enerji Tüketim Raporu',
            description: 'Sayaç okumları ve tüketim analizi',
            icon: '⚡',
            lastGenerated: '2026-02-01',
        },
    ];

    const reportData: Record<string, { cards: { label: string; value: string; color: string }[] }> = {
        financial: {
            cards: [
                { label: 'Toplam Gelir', value: '₺245.600', color: 'green' },
                { label: 'Toplam Gider', value: '₺178.400', color: 'red' },
                { label: 'Net Bakiye', value: '₺67.200', color: 'blue' },
                { label: 'Tahsilat Oranı', value: '%94.5', color: 'purple' },
            ],
        },
        collection: {
            cards: [
                { label: 'Toplam Tahakkuk', value: '₺288.000', color: 'blue' },
                { label: 'Tahsil Edilen', value: '₺272.160', color: 'green' },
                { label: 'Bekleyen Borç', value: '₺15.840', color: 'red' },
                { label: 'Ortalama Süre', value: '12 gün', color: 'purple' },
            ],
        },
        expense: {
            cards: [
                { label: 'Yönetim Gideri', value: '₺85.000', color: 'blue' },
                { label: 'Personel Gideri', value: '₺54.200', color: 'green' },
                { label: 'Bakım Gideri', value: '₺28.400', color: 'purple' },
                { label: 'Diğer Giderler', value: '₺10.800', color: 'gray' },
            ],
        },
        resident: {
            cards: [
                { label: 'Toplam Sakin', value: '124', color: 'blue' },
                { label: 'Ev Sahibi', value: '89', color: 'green' },
                { label: 'Kiracı', value: '35', color: 'purple' },
                { label: 'Aktif Sakin', value: '118', color: 'gray' },
            ],
        },
        maintenance: {
            cards: [
                { label: 'Toplam Talep', value: '47', color: 'blue' },
                { label: 'Çözülen', value: '42', color: 'green' },
                { label: 'Bekleyen', value: '5', color: 'red' },
                { label: 'Ort. Çözüm Süresi', value: '2.3 gün', color: 'purple' },
            ],
        },
        energy: {
            cards: [
                { label: 'Isı Tüketimi', value: '12.450 kWh', color: 'red' },
                { label: 'Su Tüketimi', value: '345 m³', color: 'blue' },
                { label: 'Elektrik', value: '8.920 kWh', color: 'purple' },
                { label: 'Değişim', value: '+%3.2', color: 'green' },
            ],
        },
    };

    const colorClass: Record<string, { bg: string; text: string }> = {
        green: { bg: 'bg-green-50', text: 'text-green-700' },
        red: { bg: 'bg-red-50', text: 'text-red-700' },
        blue: { bg: 'bg-blue-50', text: 'text-blue-700' },
        purple: { bg: 'bg-purple-50', text: 'text-purple-700' },
        gray: { bg: 'bg-gray-50', text: 'text-gray-700' },
    };

    const currentData = reportData[selectedReport] || reportData.financial;

    const selectedTitle = reports.find((r) => r.id === selectedReport)?.title ?? "Rapor";

    /**
     * Raporu gerçekten sunucuda üretir ve dosyayı indirir.
     * Sahte başarı yok: uç hata verirse indirme yapılmaz, hata kullanıcıya gösterilir.
     */
    const generateAndDownload = async (format: ReportFormat) => {
        setActionError(null);
        setGeneratingFormat(format);
        try {
            // Gateway gövdeyi { type, params } olarak bekliyor; api-client params'ı üst seviyeye yayar.
            const res = await apiClient.generateReport(selectedReport, {
                params: { format, period: selectedPeriod },
            });
            const reportId = res?.data?.report_id ?? res?.report_id;
            if (!reportId) {
                setActionError("Sunucu bir rapor kimliği döndürmedi, dosya indirilemedi.");
                return;
            }

            const blob = await apiClient.downloadReport(String(reportId));
            const url = URL.createObjectURL(blob as Blob);
            const a = document.createElement("a");
            a.href = url;
            a.download = `${selectedTitle.toLowerCase().replace(/\s+/g, "_")}_${selectedPeriod}.${format === "xlsx" ? "xlsx" : "pdf"}`;
            a.click();
            URL.revokeObjectURL(url);
        } catch (err) {
            setActionError(toUserMessage(err, "Rapor oluşturulamadı."));
        } finally {
            setGeneratingFormat(null);
        }
    };

    return (
        <div className="p-6 space-y-6">
            {/* Header */}
            <div className="flex justify-between items-center">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900">Raporlar</h1>
                    <p className="text-gray-500">Finansal ve operasyonel raporlarınız</p>
                </div>
                <div className="flex gap-2">
                    <select
                        value={selectedPeriod}
                        onChange={(e) => setSelectedPeriod(e.target.value)}
                        className="px-4 py-2 border rounded-lg bg-white"
                    >
                        <option value="weekly">Haftalık</option>
                        <option value="monthly">Aylık</option>
                        <option value="quarterly">Çeyreklik</option>
                        <option value="yearly">Yıllık</option>
                    </select>
                    <button
                        onClick={() => generateAndDownload('pdf')}
                        disabled={generatingFormat !== null}
                        className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        {generatingFormat ? 'Oluşturuluyor...' : 'Rapor Oluştur'}
                    </button>
                </div>
            </div>

            <NotImplementedNotice detail="Rapor üretimi sunucuda çalışıyor ancak üretilen PDF/Excel dosyaları şu an örnek veri içeriyor (sabit dönem ve sabit daire/sakin kayıtları). Aşağıdaki özet kartlarındaki tutarlar da örnek değerlerdir; mali karar için kullanılmamalıdır." />

            {actionError && (
                <p role="alert" className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                    {actionError}
                </p>
            )}

            {/* Report Types */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {reports.map((report) => (
                    <div
                        key={report.id}
                        onClick={() => setSelectedReport(report.id)}
                        className={`p-4 rounded-xl border-2 cursor-pointer transition-all ${selectedReport === report.id
                            ? 'border-blue-500 bg-blue-50'
                            : 'border-gray-200 hover:border-gray-300 bg-white'
                            }`}
                    >
                        <div className="flex items-start gap-3">
                            <span className="text-3xl">{report.icon}</span>
                            <div className="flex-1">
                                <h3 className="font-semibold text-gray-900">{report.title}</h3>
                                <p className="text-sm text-gray-500">{report.description}</p>
                            </div>
                        </div>
                    </div>
                ))}
            </div>

            {/* Report Preview - Dynamic for all report types */}
            <div className="bg-white rounded-xl border p-6 space-y-6">
                <h2 className="text-xl font-semibold">
                    {selectedTitle} Özeti <span className="text-sm font-normal text-gray-500">(örnek veri)</span>
                </h2>

                <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                    {currentData.cards.map((card, idx) => (
                        <div
                            key={idx}
                            className={`p-4 ${colorClass[card.color].bg} rounded-lg`}
                        >
                            <p className={`text-sm ${colorClass[card.color].text.replace('700', '600')}`}>
                                {card.label}
                            </p>
                            <p className={`text-2xl font-bold ${colorClass[card.color].text}`}>
                                {card.value}
                            </p>
                        </div>
                    ))}
                </div>

                <div className="flex flex-wrap items-center gap-2">
                    <button
                        onClick={() => generateAndDownload('pdf')}
                        disabled={generatingFormat !== null}
                        className="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        {generatingFormat === 'pdf' ? '📥 Hazırlanıyor...' : '📥 PDF İndir'}
                    </button>
                    <button
                        onClick={() => generateAndDownload('xlsx')}
                        disabled={generatingFormat !== null}
                        className="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        {generatingFormat === 'xlsx' ? '📊 Hazırlanıyor...' : '📊 Excel İndir'}
                    </button>
                    {/* E-posta gönderme: sunucuda böyle bir uç yok. Sahte "gönderildi" mesajı kaldırıldı. */}
                    <button
                        disabled
                        title="Rapor e-postası gönderen bir sunucu ucu henüz mevcut değil"
                        className="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        📧 E-posta Gönder
                    </button>
                    <span className="text-sm text-gray-500">E-posta gönderme özelliği henüz hazır değil.</span>
                </div>
            </div>
        </div>
    );
}
