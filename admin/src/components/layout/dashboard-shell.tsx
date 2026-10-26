"use client";

import { useEffect, useRef, useState } from "react";
import { usePathname } from "next/navigation";
import { useSession } from "next-auth/react";
import { flush, initActivity, track } from "@/lib/activity";
import { Sidebar } from "@/components/layout/sidebar";
import { Header } from "@/components/layout/header";

/** Panel iskeleti: kenar menü (mobilde çekmece) + üst çubuk + içerik. */
export function DashboardShell({ children }: { children: React.ReactNode }) {
    const [menuOpen, setMenuOpen] = useState(false);
    const pathname = usePathname();
    const { status } = useSession();
    const ready = useRef(false);
    // TAM düzeyde ekran geçişleri işlem kaydına gider (073); düzey girişte bir kez sorulur.
    useEffect(() => {
        if (status !== "authenticated") return;
        void initActivity().then(() => {
            if (!ready.current) {
                ready.current = true;
                track("session.start", pathname);
            }
            track("screen.view", pathname);
        });
    }, [status, pathname]);
    useEffect(() => {
        const onHide = () => document.visibilityState === "hidden" && void flush();
        document.addEventListener("visibilitychange", onHide);
        return () => document.removeEventListener("visibilitychange", onHide);
    }, []);
    return (
        <div className="flex h-screen bg-gray-100 dark:bg-gray-900">
            <Sidebar mobileOpen={menuOpen} onClose={() => setMenuOpen(false)} />
            <div className="flex min-w-0 flex-1 flex-col overflow-hidden">
                <Header onMenu={() => setMenuOpen(true)} />
                <main className="flex-1 overflow-y-auto p-4 sm:p-6">{children}</main>
            </div>
        </div>
    );
}