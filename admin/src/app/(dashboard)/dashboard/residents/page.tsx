"use client";

import { useState, useEffect, useRef } from "react";
import { Plus, Search, MoreVertical, Home, X, Edit, Trash2, Phone, User } from "lucide-react";

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
    const [selectedBlock, setSelectedBlock] = useState("all");
    const [selectedRole, setSelectedRole] = useState("all");
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [openMenuId, setOpenMenuId] = useState<number | null>(null);
    const [residents, setResidents] = useState(mockResidents);
    const menuRef = useRef<HTMLDivElement>(null);

    // Form state
    const [formData, setFormData] = useState({
        name: "",
        phone: "",
        unit: "",
        role: "Ev Sahibi",
    });

    // Close menu on outside click
    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
                setOpenMenuId(null);
            }
        };
        document.addEventListener("mousedown", handleClickOutside);
        return () => document.removeEventListener("mousedown", handleClickOutside);
    }, []);

    // Filter residents
    const filteredResidents = residents.filter((r) => {
        const matchesSearch =
            r.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
            r.unit.toLowerCase().includes(searchQuery.toLowerCase());
        const matchesBlock =
            selectedBlock === "all" || r.unit.startsWith(selectedBlock);
        const matchesRole = selectedRole === "all" || r.role === selectedRole;
        return matchesSearch && matchesBlock && matchesRole;
    });

    // Handle form submit
    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        const newResident = {
            id: residents.length + 1,
            ...formData,
            balance: 0,
            status: "active",
        };
        setResidents([...residents, newResident]);
        setFormData({ name: "", phone: "", unit: "", role: "Ev Sahibi" });
        setIsModalOpen(false);
    };

    // Handle delete
    const handleDelete = (id: number) => {
        if (confirm("Bu sakini silmek istediğinizden emin misiniz?")) {
            setResidents(residents.filter((r) => r.id !== id));
        }
        setOpenMenuId(null);
    };

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                        Sakinler
                    </h1>
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                        Toplam {residents.length} sakin
                    </p>
                </div>
                <button
                    onClick={() => setIsModalOpen(true)}
                    className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90"
                >
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
                <select
                    value={selectedBlock}
                    onChange={(e) => setSelectedBlock(e.target.value)}
                    className="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-800"
                >
                    <option value="all">Tüm Bloklar</option>
                    <option value="A">A Blok</option>
                    <option value="B">B Blok</option>
                </select>
                <select
                    value={selectedRole}
                    onChange={(e) => setSelectedRole(e.target.value)}
                    className="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm dark:border-gray-600 dark:bg-gray-800"
                >
                    <option value="all">Tüm Roller</option>
                    <option value="Ev Sahibi">Ev Sahibi</option>
                    <option value="Kiracı">Kiracı</option>
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
                                <td className="px-6 py-4 text-right relative">
                                    <button
                                        onClick={() => setOpenMenuId(openMenuId === resident.id ? null : resident.id)}
                                        className="rounded-lg p-2 hover:bg-gray-100 dark:hover:bg-gray-700"
                                    >
                                        <MoreVertical className="h-4 w-4 text-gray-500" />
                                    </button>
                                    {/* Dropdown Menu */}
                                    {openMenuId === resident.id && (
                                        <div
                                            ref={menuRef}
                                            className="absolute right-6 top-12 z-10 w-40 rounded-lg border border-gray-200 bg-white py-1 shadow-lg dark:border-gray-700 dark:bg-gray-800"
                                        >
                                            <button className="flex w-full items-center gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-700">
                                                <Edit className="h-4 w-4" />
                                                Düzenle
                                            </button>
                                            <button
                                                onClick={() => handleDelete(resident.id)}
                                                className="flex w-full items-center gap-2 px-4 py-2 text-sm text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20"
                                            >
                                                <Trash2 className="h-4 w-4" />
                                                Sil
                                            </button>
                                        </div>
                                    )}
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>

            {/* Modal */}
            {isModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-800">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">
                                Yeni Sakin Ekle
                            </h2>
                            <button
                                onClick={() => setIsModalOpen(false)}
                                className="rounded-lg p-1 hover:bg-gray-100 dark:hover:bg-gray-700"
                            >
                                <X className="h-5 w-5 text-gray-500" />
                            </button>
                        </div>
                        <form onSubmit={handleSubmit} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                    Ad Soyad
                                </label>
                                <div className="relative">
                                    <User className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                                    <input
                                        type="text"
                                        required
                                        value={formData.name}
                                        onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 bg-white py-2 pl-10 pr-4 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                                        placeholder="Ahmet Yılmaz"
                                    />
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                    Telefon
                                </label>
                                <div className="relative">
                                    <Phone className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                                    <input
                                        type="tel"
                                        required
                                        value={formData.phone}
                                        onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 bg-white py-2 pl-10 pr-4 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                                        placeholder="+90 555 123 4567"
                                    />
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                    Daire
                                </label>
                                <div className="relative">
                                    <Home className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                                    <input
                                        type="text"
                                        required
                                        value={formData.unit}
                                        onChange={(e) => setFormData({ ...formData, unit: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 bg-white py-2 pl-10 pr-4 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                                        placeholder="A-5"
                                    />
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                    Rol
                                </label>
                                <select
                                    value={formData.role}
                                    onChange={(e) => setFormData({ ...formData, role: e.target.value })}
                                    className="w-full rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                                >
                                    <option value="Ev Sahibi">Ev Sahibi</option>
                                    <option value="Kiracı">Kiracı</option>
                                </select>
                            </div>
                            <div className="flex gap-3 pt-4">
                                <button
                                    type="button"
                                    onClick={() => setIsModalOpen(false)}
                                    className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
                                >
                                    İptal
                                </button>
                                <button
                                    type="submit"
                                    className="flex-1 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90"
                                >
                                    Kaydet
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
