"use client";

import { useState } from "react";
import { Plus, Send, Pin, Clock, Users } from "lucide-react";

const mockAnnouncements = [
    {
        id: 1,
        title: "Asansör Bakımı",
        content:
            "5 Şubat 2026 Perşembe günü saat 10:00-14:00 arasında asansör periyodik bakımı yapılacaktır.",
        category: "MAINTENANCE",
        priority: "HIGH",
        createdAt: "2026-01-30",
        isPinned: true,
        readCount: 87,
        totalResidents: 124,
    },
    {
        id: 2,
        title: "Ocak Ayı Aidat Hatırlatması",
        content:
            "Ocak ayı aidatlarının son ödeme tarihi 10 Ocak 2026'dır. Geç ödemelerde gecikme faizi uygulanacaktır.",
        category: "PAYMENT",
        priority: "NORMAL",
        createdAt: "2026-01-05",
        isPinned: false,
        readCount: 112,
        totalResidents: 124,
    },
    {
        id: 3,
        title: "Bahçe Düzenleme Çalışması",
        content:
            "Mart ayı içerisinde site bahçesinde peyzaj düzenleme çalışması yapılacaktır.",
        category: "INFO",
        priority: "LOW",
        createdAt: "2026-01-28",
        isPinned: false,
        readCount: 45,
        totalResidents: 124,
    },
];

const categoryConfig: Record<string, { label: string; color: string }> = {
    MAINTENANCE: { label: "Bakım", color: "bg-orange-100 text-orange-700" },
    PAYMENT: { label: "Ödeme", color: "bg-blue-100 text-blue-700" },
    INFO: { label: "Duyuru", color: "bg-gray-100 text-gray-700" },
    EMERGENCY: { label: "Acil", color: "bg-red-100 text-red-700" },
};

export default function AnnouncementsPage() {
    const [showNewForm, setShowNewForm] = useState(false);

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                        Duyurular
                    </h1>
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                        Site sakinlerine duyuru yayınlayın
                    </p>
                </div>
                <button
                    onClick={() => setShowNewForm(true)}
                    className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90"
                >
                    <Plus className="h-4 w-4" />
                    Yeni Duyuru
                </button>
            </div>

            {/* Stats */}
            <div className="grid gap-4 md:grid-cols-3">
                <div className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
                    <div className="flex items-center gap-3">
                        <div className="rounded-lg bg-blue-100 p-2 dark:bg-blue-900/20">
                            <Send className="h-5 w-5 text-blue-600" />
                        </div>
                        <div>
                            <p className="text-2xl font-bold text-gray-900 dark:text-white">
                                {mockAnnouncements.length}
                            </p>
                            <p className="text-sm text-gray-500">Aktif Duyuru</p>
                        </div>
                    </div>
                </div>
                <div className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
                    <div className="flex items-center gap-3">
                        <div className="rounded-lg bg-green-100 p-2 dark:bg-green-900/20">
                            <Users className="h-5 w-5 text-green-600" />
                        </div>
                        <div>
                            <p className="text-2xl font-bold text-gray-900 dark:text-white">
                                %72
                            </p>
                            <p className="text-sm text-gray-500">Ortalama Okunma</p>
                        </div>
                    </div>
                </div>
                <div className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
                    <div className="flex items-center gap-3">
                        <div className="rounded-lg bg-purple-100 p-2 dark:bg-purple-900/20">
                            <Pin className="h-5 w-5 text-purple-600" />
                        </div>
                        <div>
                            <p className="text-2xl font-bold text-gray-900 dark:text-white">
                                1
                            </p>
                            <p className="text-sm text-gray-500">Sabitlenmiş</p>
                        </div>
                    </div>
                </div>
            </div>

            {/* Announcements List */}
            <div className="space-y-4">
                {mockAnnouncements.map((announcement) => (
                    <div
                        key={announcement.id}
                        className={`rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800 ${announcement.isPinned ? "border-2 border-primary" : ""
                            }`}
                    >
                        <div className="flex items-start justify-between">
                            <div className="flex-1">
                                <div className="mb-2 flex items-center gap-3">
                                    {announcement.isPinned && (
                                        <Pin className="h-4 w-4 text-primary" />
                                    )}
                                    <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                                        {announcement.title}
                                    </h3>
                                    <span
                                        className={`rounded-full px-3 py-1 text-xs font-medium ${categoryConfig[announcement.category].color
                                            }`}
                                    >
                                        {categoryConfig[announcement.category].label}
                                    </span>
                                </div>
                                <p className="mb-4 text-gray-600 dark:text-gray-400">
                                    {announcement.content}
                                </p>
                                <div className="flex items-center gap-4 text-sm text-gray-500">
                                    <span className="flex items-center gap-1">
                                        <Clock className="h-4 w-4" />
                                        {new Date(announcement.createdAt).toLocaleDateString("tr-TR")}
                                    </span>
                                    <span className="flex items-center gap-1">
                                        <Users className="h-4 w-4" />
                                        {announcement.readCount}/{announcement.totalResidents} okudu
                                    </span>
                                </div>
                            </div>
                            <div className="ml-4">
                                <div className="text-right">
                                    <span className="text-2xl font-bold text-primary">
                                        %{Math.round(
                                            (announcement.readCount / announcement.totalResidents) * 100
                                        )}
                                    </span>
                                    <p className="text-xs text-gray-500">okunma</p>
                                </div>
                            </div>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
}
