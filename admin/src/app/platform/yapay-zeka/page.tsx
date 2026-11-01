"use client";

import { useEffect, useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, Input, Notice, Page, QueryView, Select } from "@/components/ui/kit";
import { dateTime } from "@/lib/format";
import type { AiSettings, AiSettingsInput } from "@/lib/types";

const DEFAULT_URL: Record<string, string> = { ANTHROPIC: "https://api.anthropic.com", OPENAI: "http://localhost:11434/v1" };

/** Fotoğraf denetiminde yapay zekâ sağlayıcısı (FAZ M13.4): açılıp kapanır. Anthropic ya da OpenAI uyumlu herhangi bir
 *  sağlayıcı (yerel: Ollama, LM Studio, vLLM; SaaS) seçilir; kimlik API anahtarı ya da kullanıcı adı/parola ile verilir. */
export default function PlatformAiPage() {
    const q = useApi(["mp-ai-settings"], api.market.platform.aiSettings);
    return (
        <Page title="Yapay zekâ ile fotoğraf denetimi" description="OCR'dan geçen fotoğraflar açıkken yapay zekâya sorulur; temiz olanlar otomatik onaylanır">
            <QueryView q={q}>{(d) => <AiForm current={d} />}</QueryView>
        </Page>
    );
}

function AiForm({ current }: { current: AiSettings }) {
    const act = useAction();
    const test = useAction();
    const [f, setF] = useState<AiSettingsInput>({ enabled: current.enabled, provider: current.provider, base_url: current.base_url, model: current.model,
        auth_type: current.auth_type, api_key: "", username: current.username, password: "" });
    useEffect(() => {
        setF((x) => ({ ...x, enabled: current.enabled }));
    }, [current.enabled]);
    const save = () => act.run(() => api.market.platform.saveAiSettings(f), { invalidate: ["mp-ai-settings"], success: "Ayar kaydedildi" })
        .then((r) => { if (r) setF((x) => ({ ...x, api_key: "", password: "", clear_api_key: false, clear_password: false })); });
    return (
        <>
            <ActionFeedback action={act} />
            <ActionFeedback action={test} />
            <Notice tone="amber" title="Kişisel veri (KVKK)">Fotoğraflar yurt dışındaki bir sağlayıcıya gönderilirse bu, kişisel verinin yurt dışına
                aktarımıdır (KVKK m.9): sağlayıcıyla standart sözleşme yapılmalı ve aydınlatma metinlerinde belirtilmelidir. Yerel bir model
                (ör. Ollama) kullanılırsa veri kurum dışına çıkmaz.</Notice>
            {!current.encryption_ready && <Notice tone="red">Şifreleme anahtarı (PII_ENCRYPTION_KEY) tanımlı değil: API anahtarı ve parola kaydedilemez.</Notice>}
            <Card title="Sağlayıcı">
                <div className="grid gap-3 sm:grid-cols-2">
                    <label className="flex items-center gap-2 text-sm sm:col-span-2">
                        <input type="checkbox" checked={f.enabled} onChange={(e) => setF({ ...f, enabled: e.target.checked })} />
                        Yapay zekâ denetimi açık {current.enabled ? <Badge tone="green">Açık</Badge> : <Badge>Kapalı</Badge>}
                    </label>
                    <Field label="Sağlayıcı türü">
                        <Select value={f.provider} onChange={(e) => setF({ ...f, provider: e.target.value, base_url: DEFAULT_URL[e.target.value] })}
                            options={[{ value: "ANTHROPIC", label: "Anthropic (Claude)" }, { value: "OPENAI", label: "OpenAI uyumlu (Ollama, LM Studio, vLLM, OpenAI…)" }]} />
                    </Field>
                    <Field label="Adres"><Input value={f.base_url} onChange={(e) => setF({ ...f, base_url: e.target.value })} /></Field>
                    <Field label="Model" hint={f.provider === "ANTHROPIC" ? "ör. claude-opus-5-5" : "ör. llava, qwen2.5-vl"}>
                        <Input value={f.model} onChange={(e) => setF({ ...f, model: e.target.value })} />
                    </Field>
                    <Field label="Kimlik">
                        <Select value={f.auth_type} onChange={(e) => setF({ ...f, auth_type: e.target.value })}
                            options={[{ value: "API_KEY", label: "API anahtarı" }, { value: "BASIC", label: "Kullanıcı adı ve parola" }, { value: "NONE", label: "Yok (yerel sunucu)" }]} />
                    </Field>
                    {f.auth_type === "API_KEY" && (
                        <Field label="API anahtarı" hint={current.api_key_set ? "Tanımlı — değiştirmek için yenisini girin" : "Tanımlı değil"}>
                            <Input type="password" autoComplete="off" value={f.api_key} onChange={(e) => setF({ ...f, api_key: e.target.value })} />
                        </Field>
                    )}
                    {f.auth_type === "BASIC" && (
                        <>
                            <Field label="Kullanıcı adı"><Input autoComplete="off" value={f.username} onChange={(e) => setF({ ...f, username: e.target.value })} /></Field>
                            <Field label="Parola" hint={current.password_set ? "Tanımlı — değiştirmek için yenisini girin" : "Tanımlı değil"}>
                                <Input type="password" autoComplete="off" value={f.password} onChange={(e) => setF({ ...f, password: e.target.value })} />
                            </Field>
                        </>
                    )}
                </div>
                <div className="mt-4 flex flex-wrap gap-2">
                    <Button disabled={act.pending} onClick={() => void save()}>Kaydet</Button>
                    <Button variant="secondary" disabled={test.pending}
                        onClick={() => test.run(() => api.market.platform.testAi(), { success: (r) => `Bağlantı çalışıyor (${r.provider} ${r.model}): ${r.verdict?.reason ?? ""}` })}>
                        Bağlantıyı sına
                    </Button>
                    {current.api_key_set && f.auth_type === "API_KEY" && (
                        <Button variant="ghost" disabled={act.pending}
                            onClick={() => act.run(() => api.market.platform.saveAiSettings({ ...f, enabled: false, clear_api_key: true }), { invalidate: ["mp-ai-settings"], success: "API anahtarı silindi; yapay zekâ kapatıldı" })}>
                            Anahtarı sil
                        </Button>
                    )}
                </div>
                <p className="mt-2 text-xs text-gray-500">&quot;Bağlantıyı sına&quot; kayıtlı ayarla düz renkli küçük bir görsel gönderir. Son değişiklik: {current.updated_at ? dateTime(current.updated_at) : "—"}</p>
            </Card>
            <Card title="Nasıl çalışır">
                <ol className="list-inside list-decimal space-y-1 text-sm text-gray-700">
                    <li>Her fotoğraf önce OCR ile okunur; telefon, e-posta ya da web adresi varsa otomatik reddedilir (yapay zekâya gitmez).</li>
                    <li>Açıksa yapay zekâ çıplaklık, şiddet, nefret, silah/uyuşturucu, iletişim bilgisi (QR, sosyal medya), kişisel veri gibi sınıflara bakar.</li>
                    <li>Temiz bulunan fotoğraf otomatik onaylanır; sakıncalı bulunan, sağlayıcının reddettiği ya da hata alınan fotoğraf &quot;Fotoğraf denetimi&quot; ekranında elle onaya düşer.</li>
                    <li>Kapalıyken her fotoğraf elle onaya düşer.</li>
                </ol>
            </Card>
        </>
    );
}
