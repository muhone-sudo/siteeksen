export interface Site {
    id: string;
    name: string;
}

export const SITES: Site[] = [
    { id: "11111111-1111-1111-1111-111111111111", name: "Güneş Sitesi" },
    { id: "22222222-2222-2222-2222-222222222222", name: "Yıldız Apartmanı" },
];

export const ACTIVE_SITE_STORAGE_KEY = "active_property_id";

export function getActiveSiteId(): string {
    if (typeof window === "undefined") return SITES[0].id;
    return localStorage.getItem(ACTIVE_SITE_STORAGE_KEY) || SITES[0].id;
}

export function getActiveSite(): Site {
    const id = getActiveSiteId();
    return SITES.find((s) => s.id === id) ?? SITES[0];
}

export function setActiveSiteId(id: string) {
    if (typeof window !== "undefined") {
        localStorage.setItem(ACTIVE_SITE_STORAGE_KEY, id);
    }
}
