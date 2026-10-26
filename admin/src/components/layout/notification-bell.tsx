"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useSession } from "next-auth/react";
import { Bell } from "lucide-react";
import { api } from "@/lib/api";
import { dateTime } from "@/lib/format";

/**
 * Kişisel bildirim kutusu (073, FAZ H.2). Okunmamış sayısı dakikada bir tazelenir;
 * açılır listede son 10 bildirim, tıklanınca okundu sayılır.
 */
export function NotificationBell() {
    const { status } = useSession();
    const qc = useQueryClient();
    const [open, setOpen] = useState(false);
    const box = useRef<HTMLDivElement>(null);
    const auth = status === "authenticated";
    const count = useQuery({ queryKey: ["inbox", "count"], queryFn: api.notifications.unreadCount, enabled: auth, refetchInterval: 60000 });
    const list = useQuery({ queryKey: ["inbox", "latest"], queryFn: () => api.notifications.inbox({ limit: 10 }), enabled: auth && open });

    useEffect(() => {
        if (!open) return;
        const close = (e: MouseEvent) => {
            if (box.current && !box.current.contains(e.target as Node)) setOpen(false);
        };
        document.addEventListener("mousedown", close);
        return () => document.removeEventListener("mousedown", close);
    }, [open]);

    const markRead = async (id: string) => {
        try {
            await api.notifications.markRead(id);
        } finally {
            void qc.invalidateQueries({ queryKey: ["inbox"] });
        }
    };
    const unread = count.data?.unread ?? 0;

    return (
        <div className="relative" ref={box}>
            <button
                onClick={() => setOpen((v) => !v)}
                className="relative rounded-lg p-2 hover:bg-gray-100 dark:hover:bg-gray-700"
                title="Bildirimlerim"
                aria-label={unread ? `Bildirimlerim, ${unread} okunmamış` : "Bildirimlerim"}
                aria-haspopup="menu"
                aria-expanded={open}
            >
                <Bell className="h-5 w-5 text-gray-600 dark:text-gray-300" />
                {unread > 0 && (
                    <span className="absolute -right-0.5 -top-0.5 min-w-[1.1rem] rounded-full bg-red-600 px-1 text-center text-[10px] font-semibold leading-[1.1rem] text-white">
                        {unread > 99 ? "99+" : unread}
                    </span>
                )}
            </button>
            {open && (
                <div role="menu" className="absolute right-0 z-50 mt-2 w-80 max-w-[calc(100vw-2rem)] rounded-xl border border-gray-200 bg-white shadow-lg dark:border-gray-700 dark:bg-gray-800">
                    <div className="flex items-center justify-between border-b border-gray-100 px-4 py-2 dark:border-gray-700">
                        <span className="text-sm font-semibold">Bildirimlerim</span>
                        {unread > 0 && (
                            <button
                                className="text-xs text-blue-600 hover:underline"
                                onClick={async () => {
                                    await api.notifications.markAllRead();
                                    void qc.invalidateQueries({ queryKey: ["inbox"] });
                                }}
                            >
                                Tümünü okundu say
                            </button>
                        )}
                    </div>
                    <ul className="max-h-96 overflow-y-auto">
                        {list.isLoading && <li className="px-4 py-3 text-sm text-gray-500">Yükleniyor…</li>}
                        {list.isError && <li className="px-4 py-3 text-sm text-red-600">Bildirimler alınamadı</li>}
                        {list.data && list.data.data.length === 0 && <li className="px-4 py-3 text-sm text-gray-500">Bildirim yok</li>}
                        {list.data?.data.map((n) => (
                            <li key={n.id}>
                                <button
                                    onClick={() => !n.read_at && void markRead(n.id)}
                                    className={`block w-full px-4 py-2 text-left text-sm hover:bg-gray-50 dark:hover:bg-gray-700 ${n.read_at ? "text-gray-500" : "font-medium"}`}
                                >
                                    <span className="flex items-start gap-2">
                                        {!n.read_at && <span className="mt-1.5 h-2 w-2 shrink-0 rounded-full bg-blue-600" aria-label="okunmamış" />}
                                        <span className="min-w-0">
                                            <span className="block truncate">{n.subject || n.topic}</span>
                                            <span className="block text-xs text-gray-500">{dateTime(n.created_at)}</span>
                                        </span>
                                    </span>
                                </button>
                            </li>
                        ))}
                    </ul>
                    <Link href="/dashboard/inbox" onClick={() => setOpen(false)} className="block border-t border-gray-100 px-4 py-2 text-center text-sm text-blue-600 hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-gray-700">
                        Tümünü gör
                    </Link>
                </div>
            )}
        </div>
    );
}
