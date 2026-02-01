"use client";

import { useState } from "react";
import { Plus, Search, MoreVertical, Home } from "lucide-react";

const mockResidents = [
    {
        id: 1,
        name: "Ahmet Yılmaz",
        phone: "+90 555 123 4567",
        unit: "A-3",
        role: "Ev Sahibi",
        balance: 0,
        status: "active",
    },
    {
        id: 2,
        name: "Mehmet Demir",
        phone: "+90 555 987 6543",
        unit: "A-4",
        role: "Kiracı",
        balance: -1200,
        status: "active",
    },
    {
        id: 3,
        name: "Ayşe Yıldız",
        phone: "+90 555 456 7890",
        unit: "B-7",
        role: "Ev Sahibi",
        balance: 0,
        status: "active",
    },
    {
        id: 4,
        name: "Ali Kaya",
        phone: "+90 555 321 0987",
        unit: "A-12",
        role: "Kiracı",
        balance: -2400,
        status: "active",
    },
];

export default function ResidentsPage() {
    const [searchQuery, setSearchQuery] = useState("");

    const filteredResidents = mockResidents.filter(
        (r) =>
            r.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
            r.unit.toLowerCase().includes(searchQuery.toLowerCase())
    );

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                        Sakinler
                    </h1>
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                        Toplam {mockResidents.length} sakin
                    </p>
                </div>
                <button className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90">
                    <Plus className="h-4 w-4" />
                    Yeni Sakin
                </button>
            </div>

            {/* Search & Filter */}
            <div className="flex gap-4">
                <div className="relative flex-1">
                    <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                    <input
                        type="text"
                        placeholder="İsim veya daire ara..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="w-full rounded-lg border border-gray-300 bg-white py-2 pl-10 pr-4 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-800"
                    />
                </div>
                <select className="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-800">
                    <option>Tüm Bloklar</option>
                    <option>A Blok</option>
                    <option>B Blok</option>
                </select>
                <select className="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-800">
                    <option>Tüm Roller</option>
                    <option>Ev Sahibi</option>
                    <option>Kiracı</option>
                </select>
            </div>

            {/* Table */}
            <div className="overflow-hidden rounded-xl bg-white shadow-sm dark:bg-gray-800">
                <table className="w-full">
                    <thead className="border-b border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-900">
                        <tr>
                            <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">
                                Sakin
                            </th>
                            <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">
                                Daire
                            </th>
                            <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">
                                Rol
                            </th>
                            <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">
                                Bakiye
                            </th>
                            <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">
                                Durum
                            </th>
                            <th className="px-6 py-3 text-right text-xs font-medium uppercase text-gray-500">
                                İşlem
                            </th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                        {filteredResidents.map((resident) => (
                            <tr key={resident.id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50">
                                <td className="px-6 py-4">
                                    <div className="flex items-center gap-3">
                                        <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10 text-primary font-medium">
                                            {resident.name.split(" ").map((n) => n[0]).join("")}
                                        </div>
                                        <div>
                                            <p className="font-medium text-gray-900 dark:text-white">
                                                {resident.name}
                                            </p>
                                            <p className="text-sm text-gray-500">{resident.phone}</p>
                                        </div>
                                    </div>
                                </td>
                                <td className="px-6 py-4">
                                    <div className="flex items-center gap-2">
                                        <Home className="h-4 w-4 text-gray-400" />
                                        <span className="text-gray-900 dark:text-white">
                                            {resident.unit}
                                        </span>
                                    </div>
                                </td>
                                <td className="px-6 py-4 text-gray-900 dark:text-white">
                                    {resident.role}
                                </td>
                                <td className="px-6 py-4">
                                    <span
                                        className={
                                            resident.balance < 0 ? "text-red-500" : "text-green-500"
                                        }
                                    >
                                        {resident.balance === 0
                                            ? "Borç Yok"
                                            : `₺${Math.abs(resident.balance).toLocaleString()}`}
                                    </span>
                                </td>
                                <td className="px-6 py-4">
                                    <span className="rounded-full bg-green-100 px-3 py-1 text-xs font-medium text-green-700">
                                        Aktif
                                    </span>
                                </td>
                                <td className="px-6 py-4 text-right">
                                    <button className="rounded-lg p-2 hover:bg-gray-100 dark:hover:bg-gray-700">
                                        <MoreVertical className="h-4 w-4 text-gray-500" />
                                    </button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
}
