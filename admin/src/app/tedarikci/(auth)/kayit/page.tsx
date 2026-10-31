"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { signIn } from "next-auth/react";
import { Store } from "lucide-react";
import { api } from "@/lib/api";
import { toUserMessage } from "@/components/ui/data-state";

type State = "NEW" | "EXISTING" | "INACTIVE";

/**
 * Tedarikçi kaydı (076, FAZ M1) — OTURUM GEREKTİRMEZ.
 *
 * 1) Telefon → SMS kodu (sunucu numaranın kayıtlı olup olmadığını söylemez).
 * 2) Kod → hesap durumu: yeni numara hesap açar; SiteEksen'de hesabı olan (ör. sakin) mevcut şifresiyle
 *    hesabına tedarikçi panelini ekler; etkinleştirilmemiş hesap şifre belirler.
 * 3) Kayıt tamamlanınca aynı şifreyle oturum açılır ve tedarikçi paneline gidilir.
 */
export default function SupplierSignupPage() {
    const router = useRouter();
    const [phone, setPhone] = useState("");
    const [code, setCode] = useState("");
    const [sent, setSent] = useState(false);
    const [state, setState] = useState<State | null>(null);
    const [token, setToken] = useState("");
    const [next, setNext] = useState("");
    const [first, setFirst] = useState("");
    const [last, setLast] = useState("");
    const [email, setEmail] = useState("");
    const [pw, setPw] = useState("");
    const [pw2, setPw2] = useState("");
    const [terms, setTerms] = useState(false);
    const [pending, setPending] = useState(false);
    const [error, setError] = useState("");
    const [info, setInfo] = useState("");
    const [cooldown, setCooldown] = useState(0);
    useEffect(() => {
        if (cooldown <= 0) return;
        const t = setTimeout(() => setCooldown(cooldown - 1), 1000);
        return () => clearTimeout(t);
    }, [cooldown]);

    const needsNewPassword = state === "NEW" || state === "INACTIVE";
    const mismatch = needsNewPassword && pw2 !== "" && pw !== pw2;
    const input = "w-full rounded-lg border border-gray-300 bg-gray-50 px-4 py-3 focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20 dark:border-gray-600 dark:bg-gray-700";

    const run = async (fn: () => Promise<void>, fallback: string) => {
        setPending(true);
        setError("");
        try {
            await fn();
        } catch (err) {
            setError(toUserMessage(err, fallback));
        } finally {
            setPending(false);
        }
    };

    const sendCode = () =>
        run(async () => {
            setInfo("");
            const r = await api.identity.supplierSignupRequest(phone.trim());
            setInfo(r.message);
            setSent(true);
            setCooldown(r.retry_after_sec || 60);
        }, "Kod gönderilemedi.");

    const verify = () =>
        run(async () => {
            const r = await api.identity.supplierSignupVerify(phone.trim(), code.trim());
            setState(r.state);
            setToken(r.signup_token);
            setNext(r.next);
            setInfo("");
        }, "Kod doğrulanamadı.");

    const complete = () =>
        run(async () => {
            await api.identity.supplierSignupComplete({
                phone: phone.trim(), signup_token: token, password: pw, terms_accepted: terms,
                ...(state === "NEW" ? { first_name: first.trim(), last_name: last.trim(), email: email.trim() } : {}),
            });
            const res = await signIn("credentials", { phone: phone.trim(), password: pw, redirect: false });
            if (res?.error) {
                router.push("/tedarikci/giris");
                return;
            }
            router.push("/tedarikci");
        }, "Kayıt tamamlanamadı.");

    return (
        <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-amber-50 to-orange-100 px-4 py-8 dark:from-gray-900 dark:to-gray-800">
            <div className="w-full max-w-md rounded-2xl bg-white p-8 shadow-xl dark:bg-gray-800">
                <div className="mb-6 text-center">
                    <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-primary">
                        <Store className="h-8 w-8 text-white" />
                    </div>
                    <h1 className="text-xl font-bold text-gray-900 dark:text-white">Usta &amp; Hizmet tedarikçi kaydı</h1>
                    <p className="text-sm text-gray-500">Esnaf, dükkân ve hizmet verenler için. Telefonunuzu doğrulayın, hesabınızı açın.</p>
                </div>

                {error && <div className="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-700">{error}</div>}
                {info && <div className="mb-4 rounded-lg bg-blue-50 p-3 text-sm text-blue-800">{info}</div>}

                {state === null ? (
                    <form
                        className="space-y-4"
                        onSubmit={(e) => {
                            e.preventDefault();
                            if (sent) void verify();
                            else void sendCode();
                        }}
                    >
                        <div>
                            <label className="mb-1 block text-sm font-medium">Telefon numarası</label>
                            <input className={input} type="tel" value={phone} disabled={sent && pending}
                                onChange={(e) => setPhone(e.target.value.replace(/[^\d+ ]/g, ""))}
                                placeholder="0555 123 45 67" maxLength={20} required />
                        </div>
                        {sent && (
                            <div>
                                <label className="mb-1 block text-sm font-medium">SMS ile gelen kod</label>
                                <input className={input} value={code} onChange={(e) => setCode(e.target.value.toUpperCase())}
                                    placeholder="8 karakter" maxLength={8} autoComplete="one-time-code" required />
                                <button type="button" className="mt-2 text-sm text-primary hover:underline disabled:text-gray-400"
                                    disabled={cooldown > 0 || pending} onClick={() => void sendCode()}>
                                    {cooldown > 0 ? `Yeni kod ${cooldown} sn sonra istenebilir` : "Yeni kod gönder"}
                                </button>
                            </div>
                        )}
                        <button type="submit" disabled={pending}
                            className="w-full rounded-lg bg-primary py-3 font-medium text-white hover:bg-primary/90 disabled:opacity-50">
                            {pending ? "Bekleyin…" : sent ? "Kodu doğrula" : "Kod gönder"}
                        </button>
                    </form>
                ) : (
                    <form
                        className="space-y-4"
                        onSubmit={(e) => {
                            e.preventDefault();
                            if (!mismatch) void complete();
                        }}
                    >
                        <p className="rounded-lg bg-amber-50 p-3 text-sm text-amber-900">{next}</p>
                        {state === "NEW" && (
                            <>
                                <div className="grid grid-cols-2 gap-3">
                                    <div>
                                        <label className="mb-1 block text-sm font-medium">Ad</label>
                                        <input className={input} value={first} onChange={(e) => setFirst(e.target.value)} required />
                                    </div>
                                    <div>
                                        <label className="mb-1 block text-sm font-medium">Soyad</label>
                                        <input className={input} value={last} onChange={(e) => setLast(e.target.value)} required />
                                    </div>
                                </div>
                                <div>
                                    <label className="mb-1 block text-sm font-medium">E-posta (isteğe bağlı)</label>
                                    <input className={input} type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
                                </div>
                            </>
                        )}
                        <div>
                            <label className="mb-1 block text-sm font-medium">{state === "EXISTING" ? "Mevcut şifreniz" : "Şifre"}</label>
                            <input className={input} type="password" value={pw} onChange={(e) => setPw(e.target.value)} required
                                autoComplete={state === "EXISTING" ? "current-password" : "new-password"} />
                            {needsNewPassword && <p className="mt-1 text-xs text-gray-500">En az 8 karakter; harf ve rakam içermeli, telefon numaranızı içermemeli.</p>}
                        </div>
                        {needsNewPassword && (
                            <div>
                                <label className="mb-1 block text-sm font-medium">Şifre (tekrar)</label>
                                <input className={input} type="password" value={pw2} onChange={(e) => setPw2(e.target.value)} required autoComplete="new-password" />
                                {mismatch && <p className="mt-1 text-xs text-red-600">Şifreler aynı değil.</p>}
                            </div>
                        )}
                        <label className="flex items-start gap-2 text-sm">
                            <input type="checkbox" className="mt-1" checked={terms} onChange={(e) => setTerms(e.target.checked)} required />
                            <span>Usta &amp; Hizmet tedarikçi üyelik koşullarını ve kişisel verilerimin bu kapsamda işlenmesini kabul ediyorum.</span>
                        </label>
                        <button type="submit" disabled={pending || mismatch || !terms}
                            className="w-full rounded-lg bg-primary py-3 font-medium text-white hover:bg-primary/90 disabled:opacity-50">
                            {pending ? "Bekleyin…" : state === "EXISTING" ? "Tedarikçi panelini hesabıma ekle" : "Hesabımı aç"}
                        </button>
                    </form>
                )}

                <p className="mt-6 text-center text-sm text-gray-500">
                    Zaten kayıtlı mısınız?{" "}
                    <Link href="/tedarikci/giris" className="text-primary hover:underline">Giriş yapın</Link>
                </p>
            </div>
        </div>
    );
}
