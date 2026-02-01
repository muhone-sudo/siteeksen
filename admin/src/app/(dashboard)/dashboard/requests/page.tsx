"use client";

import { useState } from "react";
import { Search, Filter, MessageSquare, Clock, User } from "lucide-react";

const mockRequests = [
    {
        id: 1,
        ticketNo: "TLP-2026-0142",
        title: "Asansör arızası - A Blok",
        category: "Asansör",
        unit: "Ortak Alan",
        resident: "Ahmet Yılmaz",
        status: "OPEN",
        priority: "HIGH",
        createdAt: "2026-01-31T10:30:00",
        description: "A Blok asansörü 2. katta duruyor, hareket etmiyor.",
    },
    {
        id: 2,
        ticketNo: "TLP-2026-0141",
        title: "Merdiven aydınlatma arızası",
        category: "Elektrik",
        unit: "A Blok",
        resident: "Ayşe Kaya",
        status: "IN_PROGRESS",
        priority: "NORMAL",
        createdAt: "2026-01-30T14:15:00",
        assignedTo: "Elektrikçi - Mehmet Usta",
    },
    {
        id: 3,
        ticketNo: "TLP-2026-0140",
        title: "Bahçe sulama sistemi",
        category: "Bahçe",
        unit: "Ortak Alan",
        resident: "Ali Demir",
        status: "RESOLVED",
        priority: "LOW",
        createdAt: "2026-01-28T09:00:00",
        resolvedAt: "2026-01-29T16:00:00",
    },
];

const statusConfig: Record<string, { label: string; color: string }> = {
    OPEN: { label: "Açık", color: "bg-yellow-100 text-yellow-700" },
    IN_PROGRESS: { label: "İşlemde", color: "bg-blue-100 text-blue-700" },
    RESOLVED: { label: "Çözüldü", color: "bg-green-100 text-green-700" },
    CLOSED: { label: "Kapatıldı", color: "bg-gray-100 text-gray-700" },
};

const priorityConfig: Record<string, { label: string; color: string }> = {
    LOW: { label: "Düşük", color: "text-gray-500" },
    NORMAL: { label: "Normal", color: "text-blue-500" },
    HIGH: { label: "Yüksek", color: "text-orange-500" },
    URGENT: { label: "Acil", color: "text-red-500" },
};

export default function RequestsPage() {
    const [statusFilter, setStatusFilter] = useState("all");
    const [searchQuery, setSearchQuery] = useState("");

    const filteredRequests = mockRequests.filter((r) => {
        if (statusFilter !== "all" && r.status !== statusFilter) return false;
        if (
            searchQuery &&
            !r.title.toLowerCase().includes(searchQuery.toLowerCase()) &&
            !r.ticketNo.toLowerCase().includes(searchQuery.toLowerCase())
        )
            return false;
        return true;
    });

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                        Talep Yönetimi
                    </h1>
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                        Site sakinlerinin talep ve şikayetleri
                    </p>
                </div>
            </div>

            {/* Stats */}
            <div className="grid gap-4 md:grid-cols-4">
                <StatCard label="Açık" count={1} color="yellow" />
                <StatCard label="İşlemde" count={1} color="blue" />
                <StatCard label="Bugün Çözülen" count={0} color="green" />
                <StatCard label="Ortalama Çözüm" count="4 saat" color="purple" isText />
            </div>

            {/* Filters */}
            <div className="flex gap-4">
                <div className="relative flex-1">
                    <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                    <input
                        type="text"
                        placeholder="Talep ara..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="w-full rounded-lg border border-gray-300 bg-white py-2 pl-10 pr-4 text-sm focus:border-primary focus:outline-none dark:border-gray-600 dark:bg-gray-800"
                    />
                </div>
                <select
                    value={statusFilter}
                    onChange={(e) => setStatusFilter(e.target.value)}
                    className="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-800"
                >
                    <option value="all">Tüm Durumlar</option>
                    <option value="OPEN">Açık</option>
                    <option value="IN_PROGRESS">İşlemde</option>
                    <option value="RESOLVED">Çözüldü</option>
                </select>
            </div>

            {/* Requests List */}
            <div className="space-y-4">
                {filteredRequests.map((request) => (
                    <div
                        key={request.id}
                        className="rounded-xl bg-white p-6 shadow-sm transition-shadow hover:shadow-md dark:bg-gray-800"
                    >
                        <div className="flex items-start justify-between">
                            <div className="flex-1">
                                <div className="mb-2 flex items-center gap-3">
                                    <span className="text-sm font-mono text-gray-500">
                                        {request.ticketNo}
                                    </span>
                                    <span
                                        className={`rounded-full px-3 py-1 text-xs font-medium ${statusConfig[request.status].color
                                            }`}
                                    >
                                        {statusConfig[request.status].label}
                                    </span>
                                    <span
                                        className={`text-sm font-medium ${priorityConfig[request.priority].color
                                            }`}
                                    >
                                        {priorityConfig[request.priority].label}
                                    </span>
                                </div>
                                <h3 className="mb-2 text-lg font-semibold text-gray-900 dark:text-white">
                                    {request.title}
                                </h3>
                                <div className="flex flex-wrap items-center gap-4 text-sm text-gray-500">
                                    <span className="flex items-center gap-1">
                                        <User className="h-4 w-4" />
                                        {request.resident}
                                    </span>
                                    <span>{request.category}</span>
                                    <span className="flex items-center gap-1">
                                        <Clock className="h-4 w-4" />
                                        {new Date(request.createdAt).toLocaleString("tr-TR")}
                                    </span>
                                </div>
                            </div>
                            <button className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium hover:bg-gray-50 dark:border-gray-600 dark:hover:bg-gray-700">
                                Detay
                            </button>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
}

function StatCard({
    label,
    count,
    color,
    isText = false,
}: {
    label: string;
    count: number | string;
    color: string;
    isText?: boolean;
}) {
    const colorMap: Record<string, string> = {
        yellow: "bg-yellow-100 text-yellow-700",
        blue: "bg-blue-100 text-blue-700",
        green: "bg-green-100 text-green-700",
        purple: "bg-purple-100 text-purple-700",
    };

    return (
        <div className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
            <p className="text-sm text-gray-500">{label}</p>
            <p className="mt-1 text-2xl font-bold text-gray-900 dark:text-white">
                {count}
            </p>
        </div>
    );
}
