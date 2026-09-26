"use client";

import { useState } from "react";
import { signOut, useSession } from "next-auth/react";
import { api } from "@/lib/api";
import { useAction } from "@/lib/use-api";
import { Button, Card, Field, Input, Notice, Page } from "@/components/ui/kit";

/** Şifre değiştirme. Başarılı olunca sunucu BÜTÜN oturumları kapatır. */
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
        </Page>
    );
}
