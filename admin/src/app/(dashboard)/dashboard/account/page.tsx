"use client";

import { useState } from "react";
import { signOut, useSession } from "next-auth/react";
import { api } from "@/lib/api";
import { useAction } from "@/lib/use-api";
import { Button, Card, Field, Input, Notice, Page } from "@/components/ui/kit";

/**
 * Şifre, telefon ve e-posta değişikliği (telefon/e-posta: beşinci tur B4).
 * Şifre ve telefon değişince sunucu BÜTÜN oturumları kapatır.
 */
export default function AccountPage() {
    const { data: session } = useSession();
    const act = useAction();
    const [current, setCurrent] = useState("");
    const [next, setNext] = useState("");
    const [again, setAgain] = useState("");
    const mismatch = again !== "" && next !== again;

    return (
        <Page title="Hesabım" description={session?.user?.phone ? `Oturum: ${session.user.phone}` : undefined}>
            <Card title="Şifre değiştir">
                <form
                    className="max-w-md space-y-4"
                    onSubmit={async (e) => {
                        e.preventDefault();
                        if (mismatch) return;
                        const r = await act.run(() => api.identity.changePassword(current, next), {
                            success: "Şifreniz değiştirildi",
                        });
                        // Sunucu bütün oturumları iptal etti; bu oturum da artık geçersiz.
                        if (r) setTimeout(() => void signOut({ callbackUrl: "/login" }), 2500);
                    }}
                >
                    {act.error && <Notice tone="red">{act.error}</Notice>}
                    {act.message && <Notice tone="green">{act.message} Giriş ekranına yönlendiriliyorsunuz…</Notice>}
                    <Field label="Mevcut şifre" required>
                        <Input type="password" autoComplete="current-password" required value={current} onChange={(e) => setCurrent(e.target.value)} />
                    </Field>
                    <Field label="Yeni şifre" required hint="En az 8 karakter; en az bir harf ve bir rakam. Telefon numaranızı içeremez.">
                        <Input type="password" autoComplete="new-password" required minLength={8} value={next} onChange={(e) => setNext(e.target.value)} />
                    </Field>
                    <Field label="Yeni şifre (tekrar)" required>
                        <Input type="password" autoComplete="new-password" required value={again} onChange={(e) => setAgain(e.target.value)} />
                    </Field>
                    {mismatch && <p className="text-sm text-red-600">Yeni şifreler aynı değil.</p>}
                    <Notice tone="blue">Şifre değişince bu cihaz dahil bütün cihazlardaki oturumlarınız kapatılır.</Notice>
                    <Button type="submit" disabled={act.pending || mismatch}>
                        {act.pending ? "Değiştiriliyor…" : "Şifreyi değiştir"}
                    </Button>
                </form>
            </Card>
            <PhoneCard />
            <EmailCard />
        </Page>
    );
}

/** Telefon: mevcut şifre + yeni numara → kod yeni numaraya SMS; kodla onay → bütün oturumlar kapanır. */
function PhoneCard() {
    const act = useAction();
    const [phone, setPhone] = useState("");
    const [password, setPassword] = useState("");
    const [code, setCode] = useState("");
    const [sent, setSent] = useState(false);
    return (
        <Card title="Telefon numarası">
            <form className="max-w-md space-y-4" onSubmit={async (e) => {
                e.preventDefault();
                if (!sent) {
                    const r = await act.run(() => api.identity.requestPhoneChange(password, phone.trim()), { success: (x) => x.message });
                    if (r) setSent(true);
                } else {
                    const r = await act.run(() => api.identity.confirmPhoneChange(code), { success: (x) => x.message });
                    if (r) setTimeout(() => void signOut({ callbackUrl: "/login" }), 2500);
                }
            }}>
                {act.error && <Notice tone="red">{act.error}</Notice>}
                {act.message && <Notice tone="green">{act.message}</Notice>}
                {!sent ? (
                    <>
                        <Field label="Yeni numara" required hint="Yurt dışı numara +ülke kodu ile">
                            <Input type="tel" required maxLength={20} value={phone} onChange={(e) => setPhone(e.target.value.replace(/[^\d+ ]/g, ""))} />
                        </Field>
                        <Field label="Mevcut şifre" required>
                            <Input type="password" autoComplete="current-password" required value={password} onChange={(e) => setPassword(e.target.value)} />
                        </Field>
                        <Button type="submit" disabled={act.pending}>Yeni numaraya kod gönder</Button>
                    </>
                ) : (
                    <>
                        <Field label="SMS ile gelen kod" required>
                            <Input required autoComplete="one-time-code" maxLength={12} className="font-mono uppercase tracking-widest" value={code} onChange={(e) => setCode(e.target.value.toUpperCase())} />
                        </Field>
                        <Notice tone="blue">Onaylayınca numaranız değişir, bütün cihazlardaki oturumlarınız kapanır ve eski numaranıza bilgi gider.</Notice>
                        <Button type="submit" disabled={act.pending}>Onayla</Button>
                    </>
                )}
            </form>
        </Card>
    );
}

/** E-posta: mevcut şifreyle değişir; eski adrese (varsa) bilgi gider. */
function EmailCard() {
    const act = useAction();
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    return (
        <Card title="E-posta adresi">
            <form className="max-w-md space-y-4" onSubmit={async (e) => {
                e.preventDefault();
                const r = await act.run(() => api.identity.changeEmail(password, email.trim()), { success: (x) => x.message });
                if (r) setPassword("");
            }}>
                {act.error && <Notice tone="red">{act.error}</Notice>}
                {act.message && <Notice tone="green">{act.message}</Notice>}
                <Field label="Yeni e-posta" required>
                    <Input type="email" required maxLength={254} value={email} onChange={(e) => setEmail(e.target.value)} />
                </Field>
                <Field label="Mevcut şifre" required>
                    <Input type="password" autoComplete="current-password" required value={password} onChange={(e) => setPassword(e.target.value)} />
                </Field>
                <Button type="submit" disabled={act.pending}>E-postayı güncelle</Button>
            </form>
        </Card>
    );
}
