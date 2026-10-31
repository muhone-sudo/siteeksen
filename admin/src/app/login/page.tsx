"use client";

import Link from "next/link";
import { LoginCard } from "@/components/auth/login-card";

export default function LoginPage() {
    return (
        <LoginCard
            title="SiteEksen"
            subtitle="Yönetim Paneli"
            footer={
                <>
                    <p>
                        Hesabınız yok mu? Site yönetiminize başvurun.{" "}
                        <Link href="/activate" className="text-primary hover:underline">
                            Etkinleştirme kodum var
                        </Link>
                    </p>
                    <p className="mt-2">
                        Esnaf ya da tedarikçi misiniz?{" "}
                        <Link href="/tedarikci/kayit" className="text-primary hover:underline">
                            Usta &amp; Hizmet&apos;e kaydolun
                        </Link>
                    </p>
                </>
            }
        />
    );
}
