"use client";

import { useState } from "react";
import Link from "next/link";
import { Building2 } from "lucide-react";
import { api } from "@/lib/api";
import { toUserMessage } from "@/components/ui/data-state";

/**
 * Hesap etkinleştirme / şifre sıfırlama — OTURUM GEREKTİRMEZ.
 *
 * Kodu site yönetimi üretir ve kişiye iletir (SMS sağlayıcısı bağlı değildir).
 * Kod 7 gün geçerlidir, tek kullanımlıktır ve 5 hatalı denemede kilitlenir.
 */
export default function ActivatePage() {
    const [phone, setPhone] = useState("");
    const [code, setCode] = useState("");
    const [pw, setPw] = useState("");
    const [pw2, setPw2] = useState("");
    const [pending, setPending] = useState(false);
    const [error, setError] = useState("");
    const [done, setDone] = useState(false);
    const mismatch = pw2 !== "" && pw !== pw2;

    const input = "w-full rounded-lg border border-gray-300 bg-gray-50 px-4 py-3 focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20 dark:border-gray-600 dark:bg-gray-700";

    return (
        <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 px-4 dark:from-gray-900 dark:to-gray-800">
            <div className="w-full max-w-md rounded-2xl bg-white p-8 shadow-xl dark:bg-gray-800">
                <div className="mb-6 text-center">
                    <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-primary">
                        <Building2 className="h-8 w-8 text-white" />
                    </div>
                    <h1 className="text-xl font-bold text-gray-900 dark:text-white">Şifre belirle</h1>
                    <p className="text-sm text-gray-500">Site yönetiminin size ilettiği kodla hesabınızı etkinleştirin ya da şifrenizi sıfırlayın.</p>
                </div>

                {done ? (
                    <div className="space-y-4 text-center">
                        <p className="rounded-lg bg-green-50 p-4 text-sm text-green-800">Şifreniz belirlendi. Açık oturumlarınız kapatıldı.</p>
                        <Link href="/login" className="inline-block rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white">Giriş yap</Link>
                    </div>
                ) : (
                    <form
                        className="space-y-4"
                        onSubmit={async (e) => {
                            e.preventDefault();
                            if (mismatch) return;
                            setPending(true);
                            setError("");
                            try {
                                await api.identity.activate(phone.startsWith("+90") ? phone : `+90${phone}`, code, pw);
                                setDone(true);
                            } catch (err) {
                                setError(toUserMessage(err, "Şifre belirlenemedi."));
                            } finally {
                                setPending(false);
                            }
                        }}
                    >
                        {error && <p role="alert" className="rounded-lg bg-red-50 p-3 text-sm text-red-700">{error}</p>}
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                            Telefon numarası (+90 olmadan)
                            <input type="tel" required maxLength={10} placeholder="5551234567" className={input + " mt-1"}
                                value={phone} onChange={(e) => setPhone(e.target.value.replace(/\D/g, ""))} />
                        </label>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                            Kod
                            <input required autoComplete="one-time-code" maxLength={12} className={input + " mt-1 font-mono uppercase tracking-widest"}
                                value={code} onChange={(e) => setCode(e.target.value.toUpperCase())} />
                        </label>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                            Yeni şifre
                            <input type="password" required minLength={8} autoComplete="new-password" className={input + " mt-1"}
                                value={pw} onChange={(e) => setPw(e.target.value)} />
                            <span className="mt-1 block text-xs font-normal text-gray-500">En az 8 karakter; en az bir harf ve bir rakam. Telefon numaranızı içeremez.</span>
                        </label>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                            Yeni şifre (tekrar)
                            <input type="password" required autoComplete="new-password" className={input + " mt-1"}
                                value={pw2} onChange={(e) => setPw2(e.target.value)} />
                        </label>
                        {mismatch && <p className="text-sm text-red-600">Şifreler aynı değil.</p>}
                        <button type="submit" disabled={pending || mismatch}
                            className="w-full rounded-lg bg-primary py-3 font-medium text-white hover:bg-primary/90 disabled:opacity-50">
                            {pending ? "Kaydediliyor…" : "Şifremi belirle"}
                        </button>
                        <p className="text-center text-sm"><Link href="/login" className="text-primary hover:underline">Girişe dön</Link></p>
                    </form>
                )}
            </div>
        </div>
    );
}
