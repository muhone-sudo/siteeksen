"use client";

import Link from "next/link";
import { LoginCard } from "@/components/auth/login-card";

export default function SupplierLoginPage() {
    return (
        <LoginCard
            title="Usta & Hizmet"
            subtitle="SiteEksen Tedarikçi Paneli"
            footer={
                <p>
                    Henüz kaydınız yok mu?{" "}
                    <Link href="/tedarikci/kayit" className="text-primary hover:underline">
                        Tedarikçi olarak kaydolun
                    </Link>
                </p>
            }
        />
    );
}
