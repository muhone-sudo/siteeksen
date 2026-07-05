'use client';

import { useState } from 'react';
import { X, Mail, User, Briefcase, Edit, Trash2 } from 'lucide-react';

interface UserData {
    id: number;
    name: string;
    role: string;
    email: string;
    deleted: number;
}

export default function SettingsPage() {
    const [activeTab, setActiveTab] = useState('general');
    const [isUserModalOpen, setIsUserModalOpen] = useState(false);
    const [users, setUsers] = useState<UserData[]>([
        { id: 1, name: 'Ahmet Yılmaz', role: 'Yönetim Kurulu Başkanı', email: 'ahmet@email.com', deleted: 0 },
        { id: 2, name: 'Mehmet Demir', role: 'Muhasebeci', email: 'mehmet@email.com', deleted: 0 },
        { id: 3, name: 'Ayşe Kaya', role: 'Site Görevlisi', email: 'ayse@email.com', deleted: 0 },
    ]);
    const [newUser, setNewUser] = useState({ name: '', email: '', role: 'Site Görevlisi' });
    const [editingUserId, setEditingUserId] = useState<number | null>(null);
    const [deleteUserId, setDeleteUserId] = useState<number | null>(null);
    const [generalSettings, setGeneralSettings] = useState({
        siteName: 'Güneş Sitesi',
        address: 'Atatürk Mah. Cumhuriyet Cad. No:123',
        email: 'yonetim@gunessitesi.com',
        phone: '+90 212 555 0123',
        timezone: 'Europe/Istanbul (UTC+3)',
    });
    const [generalSaved, setGeneralSaved] = useState(false);
    const [notificationSettings, setNotificationSettings] = useState([
        { label: 'Yeni talep bildirimi', checked: true },
        { label: 'Ödeme hatırlatıcıları', checked: true },
        { label: 'Duyuru bildirimleri', checked: true },
        { label: 'Ziyaretçi bildirimleri', checked: false },
        { label: 'Sistem güncellemeleri', checked: true },
    ]);

    const handleSaveGeneral = () => {
        setGeneralSaved(true);
        setTimeout(() => setGeneralSaved(false), 2000);
    };

    const toggleNotification = (idx: number) => {
        setNotificationSettings(prev => prev.map((n, i) => i === idx ? { ...n, checked: !n.checked } : n));
    };

    const tabs = [
        { id: 'general', label: 'Genel', icon: '⚙️' },
        { id: 'notifications', label: 'Bildirimler', icon: '🔔' },
        { id: 'users', label: 'Kullanıcılar', icon: '👥' },
        { id: 'integrations', label: 'Entegrasyonlar', icon: '🔗' },
        { id: 'billing', label: 'Fatura', icon: '💳' },
    ];

    const activeUsers = users.filter(u => u.deleted === 0);

    const openAddUser = () => { setEditingUserId(null); setNewUser({ name: '', email: '', role: 'Site Görevlisi' }); setIsUserModalOpen(true); };
    const openEditUser = (u: UserData) => { setEditingUserId(u.id); setNewUser({ name: u.name, email: u.email, role: u.role }); setIsUserModalOpen(true); };

    const handleAddUser = (e: React.FormEvent) => {
        e.preventDefault();
        if (editingUserId !== null) {
            setUsers(prev => prev.map(u => u.id === editingUserId ? { ...u, ...newUser } : u));
        } else {
            setUsers(prev => [...prev, { id: Date.now(), ...newUser, deleted: 0 }]);
        }
        setNewUser({ name: '', email: '', role: 'Site Görevlisi' });
        setEditingUserId(null);
        setIsUserModalOpen(false);
    };

    const handleDeleteUser = () => {
        if (deleteUserId === null) return;
        setUsers(prev => prev.map(u => u.id === deleteUserId ? { ...u, deleted: 1 } : u));
        setDeleteUserId(null);
    };

    return (
        <div className="p-6 space-y-6">
            {/* Header */}
            <div>
                <h1 className="text-2xl font-bold text-gray-900">Ayarlar</h1>
                <p className="text-gray-500">Site ve sistem ayarlarınızı yönetin</p>
            </div>

            <div className="flex gap-6">
                {/* Sidebar Tabs */}
                <div className="w-64 space-y-1">
                    {tabs.map((tab) => (
                        <button
                            key={tab.id}
                            onClick={() => setActiveTab(tab.id)}
                            className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg text-left transition-all ${activeTab === tab.id
                                ? 'bg-blue-50 text-blue-700 font-medium'
                                : 'text-gray-600 hover:bg-gray-100'
                                }`}
                        >
                            <span>{tab.icon}</span>
                            {tab.label}
                        </button>
                    ))}
                </div>

                {/* Content */}
                <div className="flex-1 bg-white rounded-xl border p-6">
                    {activeTab === 'general' && (
                        <div className="space-y-6">
                            <h2 className="text-lg font-semibold">Genel Ayarlar</h2>

                            <div className="space-y-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">
                                        Site Adı
                                    </label>
                                    <input
                                        type="text"
                                        value={generalSettings.siteName}
                                        onChange={(e) => setGeneralSettings({ ...generalSettings, siteName: e.target.value })}
                                        className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                                    />
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">
                                        Site Adresi
                                    </label>
                                    <input
                                        type="text"
                                        value={generalSettings.address}
                                        onChange={(e) => setGeneralSettings({ ...generalSettings, address: e.target.value })}
                                        className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                                    />
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">
                                        İletişim E-posta
                                    </label>
                                    <input
                                        type="email"
                                        value={generalSettings.email}
                                        onChange={(e) => setGeneralSettings({ ...generalSettings, email: e.target.value })}
                                        className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                                    />
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">
                                        Telefon
                                    </label>
                                    <input
                                        type="tel"
                                        value={generalSettings.phone}
                                        onChange={(e) => setGeneralSettings({ ...generalSettings, phone: e.target.value })}
                                        className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                                    />
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">
                                        Zaman Dilimi
                                    </label>
                                    <select
                                        value={generalSettings.timezone}
                                        onChange={(e) => setGeneralSettings({ ...generalSettings, timezone: e.target.value })}
                                        className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                                    >
                                        <option>Europe/Istanbul (UTC+3)</option>
                                    </select>
                                </div>
                            </div>

                            <div className="flex items-center gap-3">
                                <button onClick={handleSaveGeneral} className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
                                    Değişiklikleri Kaydet
                                </button>
                                {generalSaved && <span className="text-sm text-green-600">Kaydedildi</span>}
                            </div>
                        </div>
                    )}

                    {activeTab === 'notifications' && (
                        <div className="space-y-6">
                            <h2 className="text-lg font-semibold">Bildirim Ayarları</h2>

                            <div className="space-y-4">
                                {notificationSettings.map((item, idx) => (
                                    <label key={idx} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                                        <span>{item.label}</span>
                                        <input
                                            type="checkbox"
                                            checked={item.checked}
                                            onChange={() => toggleNotification(idx)}
                                            className="w-5 h-5 text-blue-600 rounded focus:ring-blue-500"
                                        />
                                    </label>
                                ))}
                            </div>
                        </div>
                    )}

                    {activeTab === 'users' && (
                        <div className="space-y-6">
                            <div className="flex justify-between items-center">
                                <h2 className="text-lg font-semibold">Yönetici Kullanıcılar</h2>
                                <button
                                    onClick={openAddUser}
                                    className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                                >
                                    + Kullanıcı Ekle
                                </button>
                            </div>

                            <div className="space-y-2">
                                {activeUsers.map((user) => (
                                    <div key={user.id} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                                        <div className="flex items-center gap-3">
                                            <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 font-semibold">
                                                {user.name.charAt(0)}
                                            </div>
                                            <div>
                                                <p className="font-medium">{user.name}</p>
                                                <p className="text-sm text-gray-500">{user.role}</p>
                                            </div>
                                        </div>
                                        <div className="flex items-center gap-1">
                                            <button onClick={() => openEditUser(user)} className="p-1.5 rounded-lg hover:bg-blue-100 text-blue-500"><Edit className="h-4 w-4" /></button>
                                            <button onClick={() => setDeleteUserId(user.id)} className="p-1.5 rounded-lg hover:bg-red-100 text-red-500"><Trash2 className="h-4 w-4" /></button>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}

                    {activeTab === 'integrations' && (
                        <div className="space-y-6">
                            <h2 className="text-lg font-semibold">Entegrasyonlar</h2>

                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                {[
                                    { name: 'SMS (Netgsm) - Yakında', status: 'coming_soon', icon: '📱' },
                                    { name: 'Ödeme (Iyzico)', status: 'connected', icon: '💳' },
                                    { name: 'Push (Firebase)', status: 'connected', icon: '🔔' },
                                    { name: 'E-posta (SMTP)', status: 'connected', icon: '📧' },
                                    { name: 'AI Vision (OpenAI) - Coming Soon', status: 'coming_soon', icon: '🧠' },
                                ].map((integration, idx) => (
                                    <div key={idx} className="p-4 border rounded-lg">
                                        <div className="flex items-center justify-between">
                                            <div className="flex items-center gap-3">
                                                <span className="text-2xl">{integration.icon}</span>
                                                <span className="font-medium">{integration.name}</span>
                                            </div>
                                            <span className={`px-2 py-1 rounded-full text-xs ${integration.status === 'connected'
                                                ? 'bg-green-100 text-green-700'
                                                : integration.status === 'coming_soon'
                                                ? 'bg-gray-100 text-gray-700'
                                                : 'bg-yellow-100 text-yellow-700'
                                                }`}>
                                                {integration.status === 'connected' ? 'Bağlı' : integration.status === 'coming_soon' ? 'Yakında' : 'Bekliyor'}
                                            </span>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}

                    {activeTab === 'billing' && (
                        <div className="space-y-6">
                            <h2 className="text-lg font-semibold">Fatura Bilgileri</h2>

                            <div className="p-4 bg-blue-50 rounded-lg">
                                <p className="text-sm text-blue-600">Mevcut Plan</p>
                                <p className="text-xl font-bold text-blue-700">Pro Plan</p>
                                <p className="text-sm text-blue-600 mt-1">₺299/ay • 200 daire kapasitesi</p>
                            </div>

                            <div className="space-y-2">
                                <h3 className="font-medium">Son Faturalar</h3>
                                {[
                                    { date: '01.02.2026', amount: '₺299', status: 'Ödendi' },
                                    { date: '01.01.2026', amount: '₺299', status: 'Ödendi' },
                                    { date: '01.12.2025', amount: '₺299', status: 'Ödendi' },
                                ].map((invoice, idx) => (
                                    <div key={idx} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                                        <span>{invoice.date}</span>
                                        <span className="font-medium">{invoice.amount}</span>
                                        <span className="text-green-600 text-sm">{invoice.status}</span>
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}
                </div>
            </div>

            {/* User Modal */}
            {isUserModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-2xl">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-900">
                                {editingUserId !== null ? 'Kullanıcıyı Düzenle' : 'Kullanıcı Ekle'}
                            </h2>
                            <button
                                onClick={() => { setIsUserModalOpen(false); setEditingUserId(null); }}
                                className="rounded-lg p-1 hover:bg-gray-100"
                            >
                                <X className="h-5 w-5 text-gray-500" />
                            </button>
                        </div>
                        <form onSubmit={handleAddUser} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">
                                    Ad Soyad
                                </label>
                                <div className="relative">
                                    <User className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                                    <input
                                        type="text"
                                        required
                                        value={newUser.name}
                                        onChange={(e) => setNewUser({ ...newUser, name: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 bg-white py-2 pl-10 pr-4 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                                        placeholder="Ali Veli"
                                    />
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">
                                    E-posta
                                </label>
                                <div className="relative">
                                    <Mail className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                                    <input
                                        type="email"
                                        required
                                        value={newUser.email}
                                        onChange={(e) => setNewUser({ ...newUser, email: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 bg-white py-2 pl-10 pr-4 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                                        placeholder="ali@email.com"
                                    />
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">
                                    Rol
                                </label>
                                <div className="relative">
                                    <Briefcase className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                                    <select
                                        value={newUser.role}
                                        onChange={(e) => setNewUser({ ...newUser, role: e.target.value })}
                                        className="w-full rounded-lg border border-gray-300 bg-white py-2 pl-10 pr-4 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                                    >
                                        <option>Site Görevlisi</option>
                                        <option>Muhasebeci</option>
                                        <option>Yönetim Kurulu Üyesi</option>
                                        <option>Yönetim Kurulu Başkanı</option>
                                    </select>
                                </div>
                            </div>
                            <div className="flex gap-3 pt-4">
                                <button
                                    type="button"
                                    onClick={() => { setIsUserModalOpen(false); setEditingUserId(null); }}
                                    className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
                                >
                                    İptal
                                </button>
                                <button
                                    type="submit"
                                    className="flex-1 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
                                >
                                    {editingUserId !== null ? 'Güncelle' : 'Ekle'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Delete User Confirm */}
            {deleteUserId !== null && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-sm rounded-xl bg-white p-6 shadow-2xl text-center">
                        <div className="flex justify-center mb-4"><div className="rounded-full bg-red-100 p-3"><Trash2 className="h-6 w-6 text-red-600" /></div></div>
                        <h2 className="text-lg font-bold text-gray-900 mb-2">Kullanıcıyı Sil</h2>
                        <p className="text-gray-500 text-sm mb-6">Bu kullanıcı erişimi kaldırılacak. Emin misiniz?</p>
                        <div className="flex gap-3">
                            <button onClick={() => setDeleteUserId(null)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">İptal</button>
                            <button onClick={handleDeleteUser} className="flex-1 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700">Sil</button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
