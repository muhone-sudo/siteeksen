"use client";

import { useState } from "react";
import { Sidebar } from "@/components/layout/sidebar";
import { Header } from "@/components/layout/header";

/** Panel iskeleti: kenar menü (mobilde çekmece) + üst çubuk + içerik. */
export function DashboardShell({ children }: { children: React.ReactNode }) {
    const [menuOpen, setMenuOpen] = useState(false);
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