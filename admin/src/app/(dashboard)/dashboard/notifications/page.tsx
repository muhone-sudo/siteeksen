"use client";

import { useState, useEffect } from "react";
import apiClient from "@/lib/api-client";
import {
    Plus,
    X,
    Send,
    Bell,
    Users,
    Filter,
    Clock,
    Mail,
    Smartphone,
    MessageSquare,
    Zap,
    Calendar,
    Search,
    Check,
    Pause,
    Play,
    Trash2,
} from "lucide-react";

// Types
interface AudienceGroup {
    id: string;
    name: string;
    description: string;
    count: number;
}

interface AutomationRule {
    id: number;
    name: string;
    triggerType: "overdue" | "scheduled" | "event";
    audienceType: string;
    messageTemplate: string;
    channel: "sms" | "push" | "email" | "inapp";
    frequency: "daily" | "weekly" | "monthly";
    dayOfWeek?: number;
    dayOfMonth?: number;
    time: string;
    isActive: boolean;
    lastRun?: string;
}

interface NotificationHistory {
    id: number;
    title: string;
    message: string;
    channel: "sms" | "push" | "email" | "inapp";
    audienceType: string;
    sentCount: number;
    sentAt: string;
    status: "sent" | "scheduled" | "failed";
}

// Mock data
const audienceGroups: AudienceGroup[] = [
    { id: "all", name: "Tüm Sakinler", description: "Tüm kayıtlı sakinler", count: 124 },
    { id: "overdue", name: "Aidat Borçlular", description: "Ödenmemiş aidatı olanlar", count: 18 },
    { id: "block_a", name: "A Blok Sakinleri", description: "A Blok'ta oturanlar", count: 42 },
    { id: "block_b", name: "B Blok Sakinleri", description: "B Blok'ta oturanlar", count: 38 },
    { id: "owners", name: "Ev Sahipleri", description: "Sadece ev sahipleri", count: 89 },
    { id: "tenants", name: "Kiracılar", description: "Sadece kiracılar", count: 35 },
    { id: "board", name: "Yönetim Kurulu", description: "YK üyeleri", count: 5 },
];

const mockAutomations: AutomationRule[] = [
    {
        id: 1,
        name: "Haftalık Aidat Hatırlatma",
        triggerType: "overdue",
        audienceType: "overdue",
        messageTemplate: "Sayın {ad}, {borç} TL tutarında aidat borcunuz bulunmaktadır. Lütfen en kısa sürede ödeme yapınız.",
        channel: "sms",
        frequency: "weekly",
        dayOfWeek: 1,
        time: "10:00",
        isActive: true,
        lastRun: "2026-01-27T10:00:00",
    },
    {
        id: 2,
        name: "Aylık Tahakkuk Bildirimi",
        triggerType: "scheduled",
        audienceType: "all",
        messageTemplate: "Sayın {ad}, {ay} ayı aidatınız tahakkuk etmiştir. Son ödeme tarihi: {tarih}",
        channel: "push",
        frequency: "monthly",
        dayOfMonth: 1,
        time: "09:00",
        isActive: true,
        lastRun: "2026-01-01T09:00:00",
    },
];

const mockHistory: NotificationHistory[] = [
    { id: 1, title: "Aidat Hatırlatma", message: "Aidat borcunuz bulunmaktadır...", channel: "sms", audienceType: "overdue", sentCount: 18, sentAt: "2026-01-27T10:00:00", status: "sent" },
    { id: 2, title: "Şubat Tahakkuk", message: "Şubat ayı aidatınız tahakkuk etmiştir...", channel: "push", audienceType: "all", sentCount: 124, sentAt: "2026-02-01T09:00:00", status: "sent" },
    { id: 3, title: "Asansör Bakım Duyurusu", message: "Yarın asansör bakımı yapılacaktır...", channel: "inapp", audienceType: "all", sentCount: 124, sentAt: "2026-01-30T14:00:00", status: "sent" },
];

const channelConfig: Record<string, { label: string; icon: React.ElementType; color: string }> = {
    sms: { label: "SMS", icon: MessageSquare, color: "bg-green-100 text-green-700" },
    push: { label: "Push", icon: Bell, color: "bg-blue-100 text-blue-700" },
    email: { label: "E-posta", icon: Mail, color: "bg-purple-100 text-purple-700" },
    inapp: { label: "Uygulama", icon: Smartphone, color: "bg-orange-100 text-orange-700" },
};

const frequencyLabels: Record<string, string> = {
    daily: "Günlük",
    weekly: "Haftalık",
    monthly: "Aylık",
};

const messageVariables = ["{ad}", "{soyad}", "{daire}", "{blok}", "{borç}", "{tarih}", "{ay}"];

export default function NotificationsPage() {
    const [activeTab, setActiveTab] = useState<"compose" | "automation" | "history">("compose");
    const [isAutomationModalOpen, setIsAutomationModalOpen] = useState(false);
    const [isSendModalOpen, setIsSendModalOpen] = useState(false);

    const [automations, setAutomations] = useState(mockAutomations);
    const [history, setHistory] = useState(mockHistory);

    useEffect(() => {
        apiClient.loadToken();
        apiClient.getNotificationHistory({ limit: 50 }).then((data) => {
            const items = data?.data ?? data;
            if (Array.isArray(items) && items.length > 0) {
                setHistory(items.map((n: any) => ({
                    id: n.id,
                    title: n.title,
                    message: n.body ?? n.message ?? "",
                    channel: n.channel ?? "push",
                    audienceType: n.audience_type ?? "all",
                    sentCount: n.sent_count ?? 0,
                    sentAt: n.sent_at ?? n.created_at,
                    status: n.status ?? "sent",
                })));
            }
        }).catch(() => {});
    }, []);

    // Compose form state
    const [composeForm, setComposeForm] = useState({
        audienceType: "all",
        customFilter: "",
        channel: "push",
        title: "",
        message: "",
        scheduleType: "now",
        scheduledDate: "",
        scheduledTime: "",
    });

    // Automation form state
    const [automationForm, setAutomationForm] = useState({
        name: "",
        triggerType: "overdue",
        audienceType: "overdue",
        messageTemplate: "",
        channel: "sms",
        frequency: "weekly",
        dayOfWeek: 1,
        dayOfMonth: 1,
        time: "10:00",
    });

    const selectedAudience = audienceGroups.find((g) => g.id === composeForm.audienceType);

    const handleSendNotification = () => {
        setIsSendModalOpen(true);
    };

    const confirmSend = async () => {
        try {
            await apiClient.sendNotification({
                title: composeForm.title,
                message: composeForm.message,
                channel: composeForm.channel,
                audience_type: composeForm.audienceType,
            });
        } catch {}
        setIsSendModalOpen(false);
        setComposeForm({ ...composeForm, title: "", message: "" });
    };

    const handleAddAutomation = (e: React.FormEvent) => {
        e.preventDefault();
        setAutomations([
            ...automations,
            {
                id: automations.length + 1,
                ...automationForm,
                triggerType: automationForm.triggerType as AutomationRule["triggerType"],
                channel: automationForm.channel as AutomationRule["channel"],
                frequency: automationForm.frequency as AutomationRule["frequency"],
                isActive: true,
            },
        ]);
        setAutomationForm({ name: "", triggerType: "overdue", audienceType: "overdue", messageTemplate: "", channel: "sms", frequency: "weekly", dayOfWeek: 1, dayOfMonth: 1, time: "10:00" });
        setIsAutomationModalOpen(false);
    };

    const toggleAutomation = (id: number) => {
        setAutomations(automations.map((a) => (a.id === id ? { ...a, isActive: !a.isActive } : a)));
    };

    const deleteAutomation = (id: number) => {
        setAutomations(automations.filter((a) => a.id !== id));
    };

    const insertVariable = (variable: string) => {
        setComposeForm({ ...composeForm, message: composeForm.message + variable });
    };

    const tabs = [
        { id: "compose", label: "Bildirim Oluştur", icon: Send },
        { id: "automation", label: "Otomasyonlar", icon: Zap },
        { id: "history", label: "Gönderim Geçmişi", icon: Clock },
    ];

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Bildirim Yönetimi</h1>
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                        Hedefli ve otomatik bildirimler gönderin
                    </p>
                </div>
            </div>

            {/* Tabs */}
            <div className="flex gap-2 border-b border-gray-200 dark:border-gray-700">
                {tabs.map((tab) => (
                    <button
                        key={tab.id}
                        onClick={() => setActiveTab(tab.id as typeof activeTab)}
                        className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${activeTab === tab.id
                                ? "border-primary text-primary"
                                : "border-transparent text-gray-500 hover:text-gray-700"
                            }`}
                    >
                        <tab.icon className="h-4 w-4" />
                        {tab.label}
                    </button>
                ))}
            </div>

            {/* Tab Content */}
            <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                {/* Compose */}
                {activeTab === "compose" && (
                    <div className="space-y-6">
                        <div className="grid gap-6 lg:grid-cols-3">
                            {/* Left: Audience Selection */}
                            <div className="space-y-4">
                                <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Hedef Kitle</h3>

                                {/* Predefined Groups */}
                                <div className="space-y-2">
                                    {audienceGroups.map((group) => (
                                        <label
                                            key={group.id}
                                            className={`flex items-center justify-between p-3 rounded-lg border cursor-pointer transition-colors ${composeForm.audienceType === group.id
                                                    ? "border-primary bg-primary/5"
                                                    : "border-gray-200 hover:border-gray-300 dark:border-gray-700"
                                                }`}
                                        >
                                            <div className="flex items-center gap-3">
                                                <input
                                                    type="radio"
                                                    name="audience"
                                                    value={group.id}
                                                    checked={composeForm.audienceType === group.id}
                                                    onChange={() => setComposeForm({ ...composeForm, audienceType: group.id })}
                                                    className="h-4 w-4 text-primary"
                                                />
                                                <div>
                                                    <p className="text-sm font-medium text-gray-900 dark:text-white">{group.name}</p>
                                                    <p className="text-xs text-gray-500">{group.description}</p>
                                                </div>
                                            </div>
                                            <span className="text-sm font-medium text-primary">{group.count}</span>
                                        </label>
                                    ))}
                                </div>

                                {/* Custom Filter */}
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                        Özel Filtre (Opsiyonel)
                                    </label>
                                    <div className="relative">
                                        <Filter className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                                        <input
                                            type="text"
                                            value={composeForm.customFilter}
                                            onChange={(e) => setComposeForm({ ...composeForm, customFilter: e.target.value })}
                                            placeholder="Örn: Borç > 5000 TL"
                                            className="w-full rounded-lg border border-gray-300 py-2 pl-10 pr-4 text-sm dark:border-gray-600 dark:bg-gray-700"
                                        />
                                    </div>
                                </div>
                            </div>

                            {/* Middle: Message Composer */}
                            <div className="lg:col-span-2 space-y-4">
                                <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Mesaj</h3>

                                {/* Channel Selection */}
                                <div className="flex gap-2">
                                    {Object.entries(channelConfig).map(([key, config]) => {
                                        const Icon = config.icon;
                                        return (
                                            <button
                                                key={key}
                                                onClick={() => setComposeForm({ ...composeForm, channel: key })}
                                                className={`flex items-center gap-2 px-4 py-2 rounded-lg border text-sm font-medium transition-colors ${composeForm.channel === key
                                                        ? "border-primary bg-primary text-white"
                                                        : "border-gray-300 hover:border-gray-400 dark:border-gray-600"
                                                    }`}
                                            >
                                                <Icon className="h-4 w-4" />
                                                {config.label}
                                            </button>
                                        );
                                    })}
                                </div>

                                {/* Title */}
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Başlık</label>
                                    <input
                                        type="text"
                                        value={composeForm.title}
                                        onChange={(e) => setComposeForm({ ...composeForm, title: e.target.value })}
                                        placeholder="Bildirim başlığı"
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                    />
                                </div>

                                {/* Message */}
                                <div>
                                    <div className="flex items-center justify-between mb-1">
                                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">Mesaj</label>
                                        <div className="flex gap-1">
                                            {messageVariables.map((v) => (
                                                <button
                                                    key={v}
                                                    onClick={() => insertVariable(v)}
                                                    className="text-xs bg-gray-100 hover:bg-gray-200 px-2 py-1 rounded dark:bg-gray-700"
                                                >
                                                    {v}
                                                </button>
                                            ))}
                                        </div>
                                    </div>
                                    <textarea
                                        rows={4}
                                        value={composeForm.message}
                                        onChange={(e) => setComposeForm({ ...composeForm, message: e.target.value })}
                                        placeholder="Bildirim mesajı yazın..."
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                    />
                                </div>

                                {/* Schedule */}
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Zamanlama</label>
                                    <div className="flex gap-4">
                                        <label className="flex items-center gap-2">
                                            <input
                                                type="radio"
                                                name="schedule"
                                                checked={composeForm.scheduleType === "now"}
                                                onChange={() => setComposeForm({ ...composeForm, scheduleType: "now" })}
                                                className="h-4 w-4 text-primary"
                                            />
                                            <span className="text-sm">Hemen Gönder</span>
                                        </label>
                                        <label className="flex items-center gap-2">
                                            <input
                                                type="radio"
                                                name="schedule"
                                                checked={composeForm.scheduleType === "scheduled"}
                                                onChange={() => setComposeForm({ ...composeForm, scheduleType: "scheduled" })}
                                                className="h-4 w-4 text-primary"
                                            />
                                            <span className="text-sm">Zamanla</span>
                                        </label>
                                    </div>
                                    {composeForm.scheduleType === "scheduled" && (
                                        <div className="flex gap-4 mt-3">
                                            <input
                                                type="date"
                                                value={composeForm.scheduledDate}
                                                onChange={(e) => setComposeForm({ ...composeForm, scheduledDate: e.target.value })}
                                                className="rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                            />
                                            <input
                                                type="time"
                                                value={composeForm.scheduledTime}
                                                onChange={(e) => setComposeForm({ ...composeForm, scheduledTime: e.target.value })}
                                                className="rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                            />
                                        </div>
                                    )}
                                </div>

                                {/* Send Button */}
                                <div className="pt-4">
                                    <button
                                        onClick={handleSendNotification}
                                        disabled={!composeForm.title || !composeForm.message}
                                        className="flex items-center gap-2 rounded-lg bg-primary px-6 py-3 text-sm font-medium text-white hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed"
                                    >
                                        <Send className="h-4 w-4" />
                                        {composeForm.scheduleType === "now" ? "Şimdi Gönder" : "Zamanla"}
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                )}

                {/* Automation */}
                {activeTab === "automation" && (
                    <div className="space-y-6">
                        <div className="flex items-center justify-between">
                            <div>
                                <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Otomasyon Kuralları</h3>
                                <p className="text-sm text-gray-500">Otomatik bildirim göndermek için kurallar tanımlayın</p>
                            </div>
                            <button
                                onClick={() => setIsAutomationModalOpen(true)}
                                className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90"
                            >
                                <Plus className="h-4 w-4" />
                                Yeni Otomasyon
                            </button>
                        </div>

                        <div className="space-y-4">
                            {automations.map((automation) => {
                                const ChannelIcon = channelConfig[automation.channel].icon;
                                return (
                                    <div
                                        key={automation.id}
                                        className={`rounded-lg border p-4 ${automation.isActive ? "border-green-200 bg-green-50/50 dark:border-green-800 dark:bg-green-900/10" : "border-gray-200 dark:border-gray-700"
                                            }`}
                                    >
                                        <div className="flex items-start justify-between">
                                            <div className="flex-1">
                                                <div className="flex items-center gap-3 mb-2">
                                                    <h4 className="font-medium text-gray-900 dark:text-white">{automation.name}</h4>
                                                    <span className={`rounded-full px-2 py-1 text-xs font-medium ${channelConfig[automation.channel].color}`}>
                                                        <ChannelIcon className="inline h-3 w-3 mr-1" />
                                                        {channelConfig[automation.channel].label}
                                                    </span>
                                                    <span className={`rounded-full px-2 py-1 text-xs font-medium ${automation.isActive ? "bg-green-100 text-green-700" : "bg-gray-100 text-gray-700"}`}>
                                                        {automation.isActive ? "Aktif" : "Pasif"}
                                                    </span>
                                                </div>
                                                <p className="text-sm text-gray-600 dark:text-gray-400 mb-2">{automation.messageTemplate}</p>
                                                <div className="flex gap-4 text-sm text-gray-500">
                                                    <span className="flex items-center gap-1">
                                                        <Users className="h-4 w-4" />
                                                        {audienceGroups.find((g) => g.id === automation.audienceType)?.name}
                                                    </span>
                                                    <span className="flex items-center gap-1">
                                                        <Clock className="h-4 w-4" />
                                                        {frequencyLabels[automation.frequency]} - {automation.time}
                                                    </span>
                                                    {automation.lastRun && (
                                                        <span>Son: {new Date(automation.lastRun).toLocaleDateString("tr-TR")}</span>
                                                    )}
                                                </div>
                                            </div>
                                            <div className="flex gap-2">
                                                <button
                                                    onClick={() => toggleAutomation(automation.id)}
                                                    className={`p-2 rounded-lg ${automation.isActive ? "hover:bg-red-100 text-red-600" : "hover:bg-green-100 text-green-600"}`}
                                                    title={automation.isActive ? "Durdur" : "Başlat"}
                                                >
                                                    {automation.isActive ? <Pause className="h-4 w-4" /> : <Play className="h-4 w-4" />}
                                                </button>
                                                <button
                                                    onClick={() => deleteAutomation(automation.id)}
                                                    className="p-2 rounded-lg hover:bg-red-100 text-red-600"
                                                    title="Sil"
                                                >
                                                    <Trash2 className="h-4 w-4" />
                                                </button>
                                            </div>
                                        </div>
                                    </div>
                                );
                            })}
                        </div>
                    </div>
                )}

                {/* History */}
                {activeTab === "history" && (
                    <div className="space-y-6">
                        <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Gönderim Geçmişi</h3>

                        <table className="w-full">
                            <thead>
                                <tr className="border-b border-gray-200 dark:border-gray-700">
                                    <th className="py-3 text-left text-sm font-medium text-gray-500">Tarih</th>
                                    <th className="py-3 text-left text-sm font-medium text-gray-500">Başlık</th>
                                    <th className="py-3 text-left text-sm font-medium text-gray-500">Kanal</th>
                                    <th className="py-3 text-left text-sm font-medium text-gray-500">Hedef</th>
                                    <th className="py-3 text-right text-sm font-medium text-gray-500">Gönderim</th>
                                    <th className="py-3 text-center text-sm font-medium text-gray-500">Durum</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                                {history.map((item) => {
                                    const ChannelIcon = channelConfig[item.channel].icon;
                                    return (
                                        <tr key={item.id}>
                                            <td className="py-3 text-sm text-gray-600 dark:text-gray-400">
                                                {new Date(item.sentAt).toLocaleString("tr-TR")}
                                            </td>
                                            <td className="py-3">
                                                <p className="text-sm font-medium text-gray-900 dark:text-white">{item.title}</p>
                                                <p className="text-xs text-gray-500 truncate max-w-xs">{item.message}</p>
                                            </td>
                                            <td className="py-3">
                                                <span className={`inline-flex items-center gap-1 rounded-full px-2 py-1 text-xs font-medium ${channelConfig[item.channel].color}`}>
                                                    <ChannelIcon className="h-3 w-3" />
                                                    {channelConfig[item.channel].label}
                                                </span>
                                            </td>
                                            <td className="py-3 text-sm text-gray-600 dark:text-gray-400">
                                                {audienceGroups.find((g) => g.id === item.audienceType)?.name}
                                            </td>
                                            <td className="py-3 text-right text-sm font-medium text-gray-900 dark:text-white">
                                                {item.sentCount} kişi
                                            </td>
                                            <td className="py-3 text-center">
                                                <span className={`rounded-full px-2 py-1 text-xs font-medium ${item.status === "sent" ? "bg-green-100 text-green-700" : item.status === "scheduled" ? "bg-yellow-100 text-yellow-700" : "bg-red-100 text-red-700"
                                                    }`}>
                                                    {item.status === "sent" ? "Gönderildi" : item.status === "scheduled" ? "Zamanlanmış" : "Başarısız"}
                                                </span>
                                            </td>
                                        </tr>
                                    );
                                })}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            {/* Send Confirmation Modal */}
            {isSendModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-sm rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800">
                        <div className="flex flex-col items-center text-center">
                            <div className="rounded-full bg-primary/10 p-3 mb-4">
                                <Send className="h-6 w-6 text-primary" />
                            </div>
                            <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-2">Bildirim Gönder</h2>
                            <p className="text-gray-500 mb-4">
                                <strong>{selectedAudience?.count || 0}</strong> kişiye {channelConfig[composeForm.channel].label} göndermek istediğinize emin misiniz?
                            </p>
                            <div className="bg-gray-50 rounded-lg p-3 w-full mb-6 dark:bg-gray-700">
                                <p className="text-sm font-medium text-gray-900 dark:text-white">{composeForm.title}</p>
                                <p className="text-xs text-gray-500 mt-1">{composeForm.message}</p>
                            </div>
                            <div className="flex gap-3 w-full">
                                <button
                                    onClick={() => setIsSendModalOpen(false)}
                                    className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300"
                                >
                                    İptal
                                </button>
                                <button
                                    onClick={confirmSend}
                                    className="flex-1 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90"
                                >
                                    Gönder
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {/* Automation Modal */}
            {isAutomationModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-lg rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800 max-h-[90vh] overflow-y-auto">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">Yeni Otomasyon</h2>
                            <button onClick={() => setIsAutomationModalOpen(false)} className="rounded-lg p-1 hover:bg-gray-100 dark:hover:bg-gray-700">
                                <X className="h-5 w-5 text-gray-500" />
                            </button>
                        </div>
                        <form onSubmit={handleAddAutomation} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Otomasyon Adı</label>
                                <input
                                    type="text"
                                    required
                                    value={automationForm.name}
                                    onChange={(e) => setAutomationForm({ ...automationForm, name: e.target.value })}
                                    placeholder="Örn: Haftalık Aidat Hatırlatma"
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Tetikleyici</label>
                                    <select
                                        value={automationForm.triggerType}
                                        onChange={(e) => setAutomationForm({ ...automationForm, triggerType: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                    >
                                        <option value="overdue">Borç Durumu</option>
                                        <option value="scheduled">Zamanlanmış</option>
                                        <option value="event">Olay Bazlı</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Hedef Kitle</label>
                                    <select
                                        value={automationForm.audienceType}
                                        onChange={(e) => setAutomationForm({ ...automationForm, audienceType: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                    >
                                        {audienceGroups.map((g) => (
                                            <option key={g.id} value={g.id}>{g.name}</option>
                                        ))}
                                    </select>
                                </div>
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Kanal</label>
                                    <select
                                        value={automationForm.channel}
                                        onChange={(e) => setAutomationForm({ ...automationForm, channel: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                    >
                                        <option value="sms">SMS</option>
                                        <option value="push">Push Bildirimi</option>
                                        <option value="email">E-posta</option>
                                        <option value="inapp">Uygulama İçi</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Sıklık</label>
                                    <select
                                        value={automationForm.frequency}
                                        onChange={(e) => setAutomationForm({ ...automationForm, frequency: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                    >
                                        <option value="daily">Günlük</option>
                                        <option value="weekly">Haftalık</option>
                                        <option value="monthly">Aylık</option>
                                    </select>
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Gönderim Saati</label>
                                <input
                                    type="time"
                                    value={automationForm.time}
                                    onChange={(e) => setAutomationForm({ ...automationForm, time: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Mesaj Şablonu</label>
                                <div className="flex flex-wrap gap-1 mb-2">
                                    {messageVariables.map((v) => (
                                        <button
                                            key={v}
                                            type="button"
                                            onClick={() => setAutomationForm({ ...automationForm, messageTemplate: automationForm.messageTemplate + v })}
                                            className="text-xs bg-gray-100 hover:bg-gray-200 px-2 py-1 rounded dark:bg-gray-700"
                                        >
                                            {v}
                                        </button>
                                    ))}
                                </div>
                                <textarea
                                    rows={3}
                                    required
                                    value={automationForm.messageTemplate}
                                    onChange={(e) => setAutomationForm({ ...automationForm, messageTemplate: e.target.value })}
                                    placeholder="Sayın {ad}, {borç} TL tutarında aidat borcunuz bulunmaktadır..."
                                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                                />
                            </div>
                            <div className="flex gap-3 pt-4">
                                <button type="button" onClick={() => setIsAutomationModalOpen(false)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300">
                                    İptal
                                </button>
                                <button type="submit" className="flex-1 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90">
                                    Oluştur
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
