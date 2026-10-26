import QRCode from "qrcode";

/**
 * Devriye noktası QR'larını yazdırılabilir sayfa olarak açar (075). Her sayfada nokta adı, konumu
 * ve QR; QR yenilenince eski baskı geçersiz olur.
 */
export async function printQr(points: { name: string; location?: string; building?: string; floor?: string; qr_value?: string }[]): Promise<void> {
    const items = points.filter((p) => p.qr_value);
    if (!items.length) return;
    const images = await Promise.all(items.map((p) => QRCode.toDataURL(p.qr_value!, { width: 480, margin: 2, errorCorrectionLevel: "M" })));
    const esc = (s: string) => s.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c] as string);
    const pages = items.map((p, i) => {
        const where = [p.building, p.floor, p.location].filter(Boolean).join(" · ");
        return `<section><h1>${esc(p.name)}</h1>${where ? `<p>${esc(where)}</p>` : ""}<img src="${images[i]}" alt="QR"/>
<p class="note">Devriye kontrol noktası — SiteEksen yönetici uygulamasıyla, noktanın yanında okutun.</p></section>`;
    }).join("");
    const w = window.open("", "_blank");
    if (!w) {
        window.alert("Yazdırma penceresi açılamadı; tarayıcının açılır pencere engelini kaldırın.");
        return;
    }
    w.document.write(`<!doctype html><html lang="tr"><head><meta charset="utf-8"><title>Devriye QR</title>
<style>body{font-family:sans-serif;margin:0}section{page-break-after:always;text-align:center;padding:40px 24px}
h1{font-size:32px;margin:0 0 8px}img{width:320px;height:320px}.note{font-size:12px;color:#555}</style></head>
<body>${pages}<script>window.onload=()=>{window.print()}</script></body></html>`);
    w.document.close();
}
