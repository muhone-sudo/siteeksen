/**
 * Panelin okuduğu her ucu GERÇEK gateway'e karşı sınar.
 *
 *   GATEWAY=http://127.0.0.1:8888/api/v1 node scripts/verify-endpoints.ts
 *
 * NEDEN VAR: panel sayfaları FAZ 5'te arka uç gerçeğe çevrildikten sonra hiç
 * ona göre güncellenmemişti; ~20 yöntem olmayan yollara gidiyordu ve bunu
 * yakalayan bir şey yoktu. Bu betik `src/lib/endpoints.ts` içindeki READS
 * listesini dolaşır: her uç 200 dönmeli ve sayfaların kullandığı alanlar
 * yanıtta bulunmalıdır. Yol ya da alan adı kayarsa çıkış kodu 1 olur.
 */
import { READS } from "../src/lib/endpoints.ts";

const GATEWAY = process.env.GATEWAY ?? "http://127.0.0.1:8888/api/v1";
const PHONE = process.env.PANEL_PHONE ?? "5551234567";
const PASSWORD = process.env.PANEL_PASSWORD ?? "Demo123!";

async function main(): Promise<number> {
    const login = await fetch(`${GATEWAY}/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ phone: PHONE, password: PASSWORD }),
    });
    if (!login.ok) {
        console.error(`giriş başarısız: HTTP ${login.status}`);
        return 1;
    }
    const token = ((await login.json()) as { access_token: string }).access_token;

    const failures: string[] = [];
    let emptyLists = 0;
    for (const r of READS) {
        const res = await fetch(`${GATEWAY}${r.path}`, { headers: { Authorization: `Bearer ${token}` } });
        if (res.status !== 200) {
            const body = (await res.text()).slice(0, 120).replace(/\s+/g, " ");
            failures.push(`${r.path}  → HTTP ${res.status}  ${body}`);
            continue;
        }
        const json = (await res.json()) as Record<string, unknown>;
        let target: Record<string, unknown> | undefined = json;
        if (r.list) {
            const data = json.data;
            if (!Array.isArray(data)) {
                failures.push(`${r.path}  → {data:[...]} bekleniyordu, gelen: ${JSON.stringify(json).slice(0, 80)}`);
                continue;
            }
            if (data.length === 0) {
                emptyLists++;
                continue; // boş liste geçerlidir; alanlar denetlenemez
            }
            target = data[0] as Record<string, unknown>;
        }
        const missing = r.keys.filter((k) => !(k in (target ?? {})));
        if (missing.length) failures.push(`${r.path}  → eksik alan: ${missing.join(", ")}`);
    }

    if (failures.length) {
        console.log(failures.join("\n"));
        console.log(`\n${failures.length}/${READS.length} uç sözleşmeye uymuyor`);
        return 1;
    }
    console.log(`${READS.length} ucun tamamı sözleşmeye uygun (${emptyLists} boş liste, alanları denetlenemedi)`);
    return 0;
}

main().then((code) => process.exit(code)).catch((e) => {
    console.error(e);
    process.exit(1);
});
