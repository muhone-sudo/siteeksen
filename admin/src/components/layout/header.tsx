"use client";

import { Bell, Menu, Search, User } from "lucide-react";

export function Header() {
    return (
        <header className="flex h-16 items-center justify-between border-b border-gray-200 bg-white px-6 dark:border-gray-700 dark:bg-gray-800">
            {/* Mobile menu button */}
            <button className="lg:hidden">
                <Menu className="h-6 w-6" />
            </button>

            {/* Search */}
            <div className="flex flex-1 items-center px-4 lg:px-0">
                <div className="relative w-full max-w-md">
                    <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                    <input
                        type="text"
                        placeholder="Ara..."
                        className="w-full rounded-lg border border-gray-300 bg-gray-50 py-2 pl-10 pr-4 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                    />
                </div>
            </div>

            {/* Right side */}
            <div className="flex items-center gap-4">
                {/* Notifications */}
                <button className="relative rounded-lg p-2 hover:bg-gray-100 dark:hover:bg-gray-700">
                    <Bell className="h-5 w-5 text-gray-600 dark:text-gray-300" />
                    <span className="absolute right-1 top-1 h-2 w-2 rounded-full bg-red-500" />
                </button>

                {/* Profile */}
                <div className="flex items-center gap-3">
                    <div className="hidden text-right sm:block">
                        <p className="text-sm font-medium text-gray-900 dark:text-white">
                            Ahmet Yılmaz
                        </p>
                        <p className="text-xs text-gray-500 dark:text-gray-400">
                            Yönetim Kurulu Başkanı
                        </p>
                    </div>
                    <button className="flex h-10 w-10 items-center justify-center rounded-full bg-primary text-white">
                        <User className="h-5 w-5" />
                    </button>
                </div>
            </div>
        </header>
    );
}
