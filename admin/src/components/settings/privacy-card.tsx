"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useAction, useApi } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Notice, QueryView, Select, Table, Textarea } from "@/components/ui/kit";

const AREA: Record<string, string> = {
    ENTRANCE: "Giriş", PERIMETER: "Çevre", PARKING: "Otopark", GARDEN: "Bahçe", LOBBY: "Lobi", CORRIDOR: "Koridor", ELEVATOR: "Asansör", OTHER: "Diğer",
};
const METHOD: Record<string, string> = { FINGERPRINT: "Parmak izi", FACE: "Yüz", PALM: "Avuç içi", IRIS: "İris", OTHER: "Diğer" };
const blankCamera = { location: "", area_type: "ENTRANCE", purpose: "", retention_days: 15, notice_posted: false, masked: false, audio_recording: false, face_recognition: false, intensive_justification: "", decision_ref: "", access_note: "" };

/**
 * Kamera ve biyometrik sistem envanteri (FAZ 7.8). KVK Kurumu apartman kamera duyurusu
 * (08/06/2026): mahremiyet alanına kamera konmaz, aydınlatma levhası asılır, ses kaydı ve
 * yüz tanımadan kaçınılır, kayıtlar gerektiği kadar saklanır. Biyometrik sistem açık rıza
 * ve alternatif yöntem ister (KVKK m.6).
 */
export function PrivacyCard() {
    const cams = useApi(["cameras"], api.settings.cameras);
    const bios = useApi(["biometrics"], api.settings.biometrics);
    const act = useAction();
    const [cam, setCam] = useState<typeof blankCamera | null>(null);
    const [bio, setBio] = useState<{ name: string; method: string; purpose: string; alternative_method: string; retention_note: string } | null>(null);
    const flag = (k: keyof typeof blankCamera, label: string) => cam && (
        <label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={Boolean(cam[k])} onChange={(e) => setCam({ ...cam, [k]: e.target.checked })} /> {label}</label>
    );

    return (
        <>
            <ActionFeedback action={act} />
            <Card title="Kamera envanteri" actions={<Button size="sm" variant="secondary" onClick={() => setCam(blankCamera)}>Kamera ekle</Button>} padded={false}>
                <QueryView q={cams} empty="Kamera kaydı yok">
                    {(d) => (
                        <>
                            <Table rows={d.data} rowKey={(x) => x.id} columns={[
                                { header: "Konum", cell: (x) => <><b>{x.location}</b><div className="text-xs text-gray-500">{AREA[x.area_type] ?? x.area_type}</div></> },
                                { header: "Amaç", cell: (x) => x.purpose },
                                { header: "Saklama", cell: (x) => `${x.retention_days} gün` },
                                { header: "Uygunluk", cell: (x) => (x.issues?.length ? <ul className="list-disc pl-4 text-xs text-amber-700">{x.issues.map((i) => <li key={i}>{i}</li>)}</ul> : <Badge tone="green">Sorun yok</Badge>) },
                            ]} />
                            {d.open_issues ? <p className="px-4 py-3 text-xs text-amber-700">{d.open_issues} açık uygunluk notu.</p> : null}
                        </>
                    )}
                </QueryView>
            </Card>
            <Card title="Biyometrik sistemler" actions={<Button size="sm" variant="secondary" onClick={() => setBio({ name: "", method: "FINGERPRINT", purpose: "", alternative_method: "", retention_note: "" })}>Sistem ekle</Button>} padded={false}>
                <QueryView q={bios} empty="Biyometrik sistem yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(x) => x.id} columns={[
                            { header: "Sistem", cell: (x) => <b>{x.name}</b> },
                            { header: "Yöntem", cell: (x) => METHOD[x.method] ?? x.method },
                            { header: "Amaç", cell: (x) => x.purpose },
                            { header: "Alternatif", cell: (x) => x.alternative_method },
                        ]} />
                    )}
                </QueryView>
            </Card>
            <FormModal open={!!cam} onClose={() => setCam(null)} title="Kamera ekle" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!cam) return;
                    const r = await act.run(() => api.settings.createCamera(cam), { invalidate: ["cameras"], success: (x) => (x.issues.length ? `Kaydedildi; ${x.issues.length} uygunluk notu var` : "Kaydedildi") });
                    if (r) setCam(null);
                }}>
                {cam && (<>
                    <Notice tone="amber">Bağımsız bölüm içini/kapı önünü, tuvalet, soyunma ve ibadet yerlerini gören kamera konulamaz. Ses kaydı, yüz tanıma ve asansör kamerası için somut gerekçe gerekir.</Notice>
                    <Grid>
                        <Field label="Konum" required><Input required value={cam.location} onChange={(e) => setCam({ ...cam, location: e.target.value })} /></Field>
                        <Field label="Alan türü"><Select value={cam.area_type} onChange={(e) => setCam({ ...cam, area_type: e.target.value })} options={Object.entries(AREA).map(([value, label]) => ({ value, label }))} /></Field>
                        <Field label="Saklama (gün)" required><Input type="number" min="1" max="365" required value={cam.retention_days} onChange={(e) => setCam({ ...cam, retention_days: Number(e.target.value) })} /></Field>
                        <Field label="Genel kurul kararı"><Input value={cam.decision_ref} onChange={(e) => setCam({ ...cam, decision_ref: e.target.value })} /></Field>
                    </Grid>
                    <Field label="Amaç" required><Input required value={cam.purpose} onChange={(e) => setCam({ ...cam, purpose: e.target.value })} /></Field>
                    <Field label="Kayıtlara kimler erişir"><Input value={cam.access_note} onChange={(e) => setCam({ ...cam, access_note: e.target.value })} /></Field>
                    <div className="grid gap-1 sm:grid-cols-2">{flag("notice_posted", "Aydınlatma levhası asılı")}{flag("masked", "Gereksiz alanlar maskelendi")}{flag("audio_recording", "Ses kaydı yapıyor")}{flag("face_recognition", "Yüz tanıma var")}</div>
                    {(cam.audio_recording || cam.face_recognition || cam.area_type === "ELEVATOR") && (
                        <Field label="Somut gerekçe" required><Textarea required value={cam.intensive_justification} onChange={(e) => setCam({ ...cam, intensive_justification: e.target.value })} /></Field>
                    )}
                </>)}
            </FormModal>
            <FormModal open={!!bio} onClose={() => setBio(null)} title="Biyometrik sistem" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!bio) return;
                    const r = await act.run(() => api.settings.createBiometric({ ...bio, consent_based: true }), { invalidate: ["biometrics"], success: "Kaydedildi" });
                    if (r) setBio(null);
                }}>
                {bio && (<>
                    <Notice tone="amber">Biyometrik veri özel nitelikli kişisel veridir: kullanıcının açık rızası gerekir ve rıza vermeyene alternatif geçiş yöntemi sunulmalıdır (KVKK m.6).</Notice>
                    <Grid>
                        <Field label="Sistem adı" required><Input required value={bio.name} onChange={(e) => setBio({ ...bio, name: e.target.value })} /></Field>
                        <Field label="Yöntem"><Select value={bio.method} onChange={(e) => setBio({ ...bio, method: e.target.value })} options={Object.entries(METHOD).map(([value, label]) => ({ value, label }))} /></Field>
                    </Grid>
                    <Field label="Amaç" required><Input required value={bio.purpose} onChange={(e) => setBio({ ...bio, purpose: e.target.value })} /></Field>
                    <Field label="Alternatif yöntem" required><Input required value={bio.alternative_method} onChange={(e) => setBio({ ...bio, alternative_method: e.target.value })} placeholder="Kartlı geçiş, şifre, görevli eşliği" /></Field>
                    <Field label="Saklama notu"><Input value={bio.retention_note} onChange={(e) => setBio({ ...bio, retention_note: e.target.value })} /></Field>
                </>)}
            </FormModal>
        </>
    );
}
