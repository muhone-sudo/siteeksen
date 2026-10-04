"use client";

import { useState } from "react";
import { Trash2 } from "lucide-react";
import { api } from "@/lib/api";
import { useAction, useApi, useRoles } from "@/lib/use-api";
import { ActionFeedback, Badge, Button, Card, Field, FormModal, Grid, Input, Modal, Notice, Page, QueryView, Select, Table, Textarea } from "@/components/ui/kit";
import { date, dateTime, today } from "@/lib/format";
import type { EmergencyCard } from "@/lib/types";

const POINT_KIND: Record<string, string> = {
    ASSEMBLY_AREA: "Toplanma alanı", WATER_VALVE: "Ana su vanası", GAS_VALVE: "Gaz vanası", ELECTRIC_PANEL: "Elektrik panosu",
    GENERATOR: "Jeneratör", FIRE_PUMP: "Yangın pompası", FIRE_CABINET: "Yangın dolabı / tüp", FIRST_AID: "İlk yardım dolabı",
    SHELTER: "Sığınak", OTHER: "Diğer",
};
const CONTACT_CAT: Record<string, string> = {
    EMERGENCY: "Acil", UTILITY: "Altyapı arıza", HOSPITAL: "Hastane", MANAGEMENT: "Yönetim", SECURITY: "Güvenlik", TECHNICAL: "Teknik servis", OTHER: "Diğer",
};
const KIND: Record<string, string> = { FIRE: "Yangın", EARTHQUAKE: "Deprem", EVACUATION: "Tahliye", FLOOD: "Sel", OTHER: "Diğer" };
const opts = (m: Record<string, string>) => Object.entries(m).map(([value, label]) => ({ value, label }));

/**
 * Acil durum ve afet (FAZ 7.3). Sakin acil bilgi kartı özel nitelikli veridir (KVKK m.6):
 * yalnızca açık rızayla, şifreli tutulur; her görüntüleme denetim kaydına yazılır.
 */
export default function EmergencyPage() {
    const info = useApi(["emergency-info"], api.emergency.info);
    const drills = useApi(["emergency-drills"], api.emergency.drills);
    const checks = useApi(["emergency-checks"], api.emergency.checks);
    const act = useAction();
    const { canWrite } = useRoles();
    const [point, setPoint] = useState<{ kind: string; name: string; location: string; note: string } | null>(null);
    const [contact, setContact] = useState<{ category: string; name: string; phone: string; note: string; sort_order: number } | null>(null);
    const [drill, setDrill] = useState<{ kind: string; drill_date: string; participants: string; findings: string; corrective_actions: string } | null>(null);
    const [check, setCheck] = useState<{ kind: string; title: string } | null>(null);
    const [responsesOf, setResponsesOf] = useState<string | null>(null);
    const [cards, setCards] = useState<EmergencyCard[] | null>(null);

    return (
        <Page title="Acil durum ve afet" description="Toplanma alanı ve kritik altyapı, acil telefonlar, tatbikatlar, afet sonrası durum bildirimi.">
            <ActionFeedback action={act} />
            <Notice tone="red">Her türlü acil durumda 112 aranır. Bu sayfadaki bilgi kartı sakin uygulamasında çevrimdışı da görüntülenir.</Notice>

            <Card title="Durum bildirimi (afet sonrası)" actions={canWrite && <Button size="sm" variant="danger" onClick={() => setCheck({ kind: "EARTHQUAKE", title: "Deprem sonrası durum bildirimi" })}>Çağrı başlat</Button>} padded={false}>
                <QueryView q={checks} empty="Durum bildirimi çağrısı yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(s) => s.id} columns={[
                            { header: "Çağrı", cell: (s) => <b>{s.title}</b> },
                            { header: "Tür", cell: (s) => KIND[s.kind] ?? s.kind },
                            { header: "Açılış", cell: (s) => dateTime(s.opened_at) },
                            { header: "Durum", cell: (s) => (s.status === "OPEN" ? <Badge tone="red">Açık</Badge> : <Badge>Kapandı</Badge>) },
                            { header: "Yanıt", cell: (s) => `${s.responded} / ${s.units} daire` },
                            { header: "Yardım", cell: (s) => (s.need_help > 0 ? <Badge tone="red">{s.need_help} yardım talebi</Badge> : "—") },
                            { header: "", cell: (s) => <Button size="sm" variant="ghost" onClick={() => setResponsesOf(s.id)}>Yanıtlar</Button> },
                        ]} />
                    )}
                </QueryView>
            </Card>

            <Grid>
                <Card title="Toplanma alanı ve kritik altyapı" actions={canWrite && <Button size="sm" variant="secondary" onClick={() => setPoint({ kind: "ASSEMBLY_AREA", name: "", location: "", note: "" })}>Ekle</Button>} padded={false}>
                    <QueryView q={info} isEmpty={(d) => d.points.length === 0} empty="Kayıt yok">
                        {(d) => (
                            <Table rows={d.points} rowKey={(p) => p.id} columns={[
                                { header: "Tür", cell: (p) => POINT_KIND[p.kind] ?? p.kind },
                                { header: "Ad", cell: (p) => <b>{p.name}</b> },
                                { header: "Konum", cell: (p) => p.location },
                                ...(canWrite ? [{ header: "", cell: (p: { id: string }) => (
                                    <Button size="sm" variant="ghost" aria-label="Sil" onClick={() => act.run(() => api.emergency.deletePoint(p.id), { invalidate: ["emergency-info"], success: "Silindi" })}><Trash2 className="h-4 w-4" /></Button>
                                ) }] : []),
                            ]} />
                        )}
                    </QueryView>
                </Card>
                <Card title="Acil iletişim" actions={canWrite && <Button size="sm" variant="secondary" onClick={() => setContact({ category: "UTILITY", name: "", phone: "", note: "", sort_order: 0 })}>Ekle</Button>} padded={false}>
                    <QueryView q={info} isEmpty={(d) => d.contacts.length === 0} empty="Kayıt yok">
                        {(d) => (
                            <Table rows={d.contacts} rowKey={(c) => c.id} columns={[
                                { header: "Kategori", cell: (c) => CONTACT_CAT[c.category] ?? c.category },
                                { header: "Ad", cell: (c) => <b>{c.name}</b> },
                                { header: "Telefon", cell: (c) => c.phone },
                                ...(canWrite ? [{ header: "", cell: (c: { id: string }) => (
                                    <Button size="sm" variant="ghost" aria-label="Sil" onClick={() => act.run(() => api.emergency.deleteContact(c.id), { invalidate: ["emergency-info"], success: "Silindi" })}><Trash2 className="h-4 w-4" /></Button>
                                ) }] : []),
                            ]} />
                        )}
                    </QueryView>
                </Card>
            </Grid>

            <Card title="Tatbikatlar" actions={canWrite && <Button size="sm" variant="secondary" onClick={() => setDrill({ kind: "EARTHQUAKE", drill_date: today(), participants: "", findings: "", corrective_actions: "" })}>Tatbikat kaydet</Button>} padded={false}>
                <p className="px-4 pt-3 text-xs text-gray-500">Personel çalıştıran site yönetimi işverendir: yılda en az bir tatbikat yapılır ve eksiklikleri içeren rapor tutulur (İşyerlerinde Acil Durumlar Hk. Yönetmelik m.13). Süre geçince yönetime hatırlatma gider.</p>
                <QueryView q={drills} empty="Tatbikat kaydı yok">
                    {(d) => (
                        <Table rows={d.data} rowKey={(x) => x.id} columns={[
                            { header: "Tarih", cell: (x) => date(x.drill_date) },
                            { header: "Tür", cell: (x) => KIND[x.kind] ?? x.kind },
                            { header: "Katılım", cell: (x) => x.participants ?? "—" },
                            { header: "Görülen eksiklikler", cell: (x) => x.findings },
                            { header: "Düzeltici faaliyet", cell: (x) => x.corrective_actions ?? "—" },
                        ]} />
                    )}
                </QueryView>
            </Card>

            {canWrite && (
                <Card title="Sakin acil bilgi kartları">
                    <p className="text-sm text-gray-600 dark:text-gray-400">Tahliyede yardıma ihtiyacı olan sakinlerin kendi beyan ettiği bilgiler. Özel nitelikli kişisel veridir (KVKK m.6); yalnızca acil durum amacıyla görüntüleyin. Her görüntüleme denetim kaydına yazılır.</p>
                    <Button className="mt-3" variant="secondary" disabled={act.pending} onClick={async () => {
                        const r = await act.run(() => api.emergency.cards(), { success: (x) => x.note });
                        if (r) setCards(r.data);
                    }}>Kartları görüntüle (kayda geçer)</Button>
                    {cards && (
                        <Table rows={cards} rowKey={(c) => c.id} columns={[
                            { header: "Daire", cell: (c) => <b>{c.unit}</b> },
                            { header: "Sakin", cell: (c) => c.resident_name },
                            { header: "Yardım ihtiyacı", cell: (c) => c.needs },
                            { header: "Hane", cell: (c) => c.household_count ?? "—" },
                            { header: "Yakını", cell: (c) => [c.contact_name, c.contact_phone].filter(Boolean).join(" · ") || "—" },
                        ]} />
                    )}
                </Card>
            )}

            <FormModal open={!!point} onClose={() => setPoint(null)} title="Nokta ekle" pending={act.pending} error={act.error}
                onSubmit={async () => { if (!point) return; const r = await act.run(() => api.emergency.addPoint(point), { invalidate: ["emergency-info"], success: "Eklendi" }); if (r) setPoint(null); }}>
                {point && (<>
                    <Field label="Tür"><Select value={point.kind} onChange={(e) => setPoint({ ...point, kind: e.target.value })} options={opts(POINT_KIND)} /></Field>
                    <Field label="Ad" required><Input required value={point.name} onChange={(e) => setPoint({ ...point, name: e.target.value })} /></Field>
                    <Field label="Konum" required><Input required value={point.location} onChange={(e) => setPoint({ ...point, location: e.target.value })} placeholder="ör. B blok bodrum, kazan dairesi girişi solda" /></Field>
                    <Field label="Not"><Input value={point.note} onChange={(e) => setPoint({ ...point, note: e.target.value })} /></Field>
                </>)}
            </FormModal>
            <FormModal open={!!contact} onClose={() => setContact(null)} title="Acil iletişim ekle" pending={act.pending} error={act.error}
                onSubmit={async () => { if (!contact) return; const r = await act.run(() => api.emergency.addContact(contact), { invalidate: ["emergency-info"], success: "Eklendi" }); if (r) setContact(null); }}>
                {contact && (<>
                    <Field label="Kategori"><Select value={contact.category} onChange={(e) => setContact({ ...contact, category: e.target.value })} options={opts(CONTACT_CAT)} /></Field>
                    <Field label="Ad" required><Input required value={contact.name} onChange={(e) => setContact({ ...contact, name: e.target.value })} /></Field>
                    <Field label="Telefon" required><Input required value={contact.phone} onChange={(e) => setContact({ ...contact, phone: e.target.value })} /></Field>
                    <Field label="Not"><Input value={contact.note} onChange={(e) => setContact({ ...contact, note: e.target.value })} /></Field>
                </>)}
            </FormModal>
            <FormModal open={!!drill} onClose={() => setDrill(null)} title="Tatbikat raporu" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!drill) return;
                    const r = await act.run(() => api.emergency.addDrill({ ...drill, participants: drill.participants ? Number(drill.participants) : undefined }), { invalidate: ["emergency-drills"], success: "Tatbikat kaydedildi" });
                    if (r) setDrill(null);
                }}>
                {drill && (<>
                    <Grid>
                        <Field label="Tür"><Select value={drill.kind} onChange={(e) => setDrill({ ...drill, kind: e.target.value })} options={opts(KIND)} /></Field>
                        <Field label="Tarih" required><Input type="date" required value={drill.drill_date} onChange={(e) => setDrill({ ...drill, drill_date: e.target.value })} /></Field>
                        <Field label="Katılımcı sayısı"><Input type="number" min="0" value={drill.participants} onChange={(e) => setDrill({ ...drill, participants: e.target.value })} /></Field>
                    </Grid>
                    <Field label="Görülen eksiklikler" required hint="Eksiklik yoksa 'eksiklik görülmedi' yazın"><Textarea required value={drill.findings} onChange={(e) => setDrill({ ...drill, findings: e.target.value })} /></Field>
                    <Field label="Düzeltici ve önleyici faaliyetler"><Textarea value={drill.corrective_actions} onChange={(e) => setDrill({ ...drill, corrective_actions: e.target.value })} /></Field>
                </>)}
            </FormModal>
            <FormModal open={!!check} onClose={() => setCheck(null)} title="Durum bildirimi çağrısı" pending={act.pending} error={act.error}
                onSubmit={async () => {
                    if (!check) return;
                    const r = await act.run(() => api.emergency.openCheck(check), { invalidate: ["emergency-checks"], success: (x) => `Çağrı açıldı. ${x.notification.note}` });
                    if (r) { setCheck(null); setResponsesOf(r.check.id); }
                }}>
                {check && (<>
                    <Notice tone="amber">Bütün sakinlere &ldquo;Güvendeyim / Yardım gerekiyor&rdquo; yanıtı istenen bildirim gider. Yardım talepleri yönetime anında iletilir.</Notice>
                    <Field label="Tür"><Select value={check.kind} onChange={(e) => setCheck({ ...check, kind: e.target.value })} options={opts(KIND)} /></Field>
                    <Field label="Başlık" required><Input required value={check.title} onChange={(e) => setCheck({ ...check, title: e.target.value })} /></Field>
                </>)}
            </FormModal>
            {responsesOf && <Responses id={responsesOf} canWrite={canWrite} onClose={() => setResponsesOf(null)} />}
        </Page>
    );
}

function Responses({ id, canWrite, onClose }: { id: string; canWrite: boolean; onClose: () => void }) {
    const q = useApi(["emergency-checks", id], () => api.emergency.responses(id));
    const act = useAction();
    return (
        <Modal open onClose={onClose} title="Durum yanıtları" wide>
            <QueryView q={q} isEmpty={() => false}>
                {(d) => (
                    <div className="space-y-4">
                        <div className="flex flex-wrap gap-3 text-sm">
                            <b>{d.check.title}</b>
                            <Badge tone="green">{d.check.safe} güvende</Badge>
                            <Badge tone="red">{d.check.need_help} yardım</Badge>
                            <span>{d.check.responded} / {d.check.units} daire yanıt verdi</span>
                        </div>
                        <ActionFeedback action={act} />
                        <Table rows={d.data} rowKey={(x) => x.user_id} columns={[
                            { header: "Durum", cell: (x) => (x.status === "NEED_HELP" ? <Badge tone="red">Yardım gerekiyor</Badge> : <Badge tone="green">Güvende</Badge>) },
                            { header: "Daire", cell: (x) => x.unit || "—" },
                            { header: "Sakin", cell: (x) => x.name },
                            { header: "Not", cell: (x) => x.note ?? "" },
                            { header: "Zaman", cell: (x) => dateTime(x.responded_at) },
                        ]} />
                        {d.silent_units.length > 0 && <Notice tone="amber" title="Henüz yanıt vermeyen daireler">{d.silent_units.join(", ")}</Notice>}
                        {canWrite && d.check.status === "OPEN" && (
                            <Button variant="secondary" disabled={act.pending} onClick={() => act.run(() => api.emergency.closeCheck(id), { invalidate: ["emergency-checks"], success: "Çağrı kapatıldı" })}>Çağrıyı kapat</Button>
                        )}
                    </div>
                )}
            </QueryView>
        </Modal>
    );
}
