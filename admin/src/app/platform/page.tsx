"use client";

import Link from "next/link";
import { api } from "@/lib/api";
import { useApi } from "@/lib/use-api";
import { Card, Page, Stats } from "@/components/ui/kit";

/** Platform özeti (FAZ M4): bekleyen inceleme kuyrukları. */
export default function PlatformHomePage() {
    const acc = useApi(["mp-accounts", "REVIEW"], () => api.market.platform.accounts("REVIEW"));
    const biz = useApi(["mp-businesses", "REVIEW"], () => api.market.platform.businesses("REVIEW"));
    const n = (q: { data?: { data: unknown[] } }) => (q.data ? q.data.data.length : "—");
    return (
        <Page title="Platform yönetimi" description="Usta & Hizmet pazaryeri">
            <Stats items={[
                { label: "İncelemedeki tedarikçi hesabı", value: n(acc), tone: "amber" },
                { label: "Yayın onayı bekleyen işletme", value: n(biz), tone: "amber" },
            ]} />
            <Card title="Kuyruklar">
                <ul className="list-inside list-disc space-y-1 text-sm">
                    <li><Link className="text-primary hover:underline" href="/platform/hesaplar">Tedarikçi hesapları ve belgeler</Link></li>
                    <li><Link className="text-primary hover:underline" href="/platform/isletmeler">İşletme yayın onayı</Link></li>
                </ul>
            </Card>
        </Page>
    );
}
