/**
 * Rol bazlı erişim kontrolü (RBAC).
 *
 * NEDEN VAR (tasks/gap-analizi.md B28, todo 0.A.10 / 2.9):
 *
 * Panelde hiçbir erişim kontrolü yoktu: `session.user.roles` hiçbir sayfada
 * okunmuyordu. Giriş yapan HERKES — bir kiracı dahil — personel maaş bordrosunu,
 * sakinlerin kimlik bilgilerini ve sistem API anahtarlarını görebiliyordu.
 *
 * Kontrol iki katmanda uygulanır:
 *   1. `middleware.ts` — sunucu tarafında yönlendirme (adres çubuğuna elle yazarak
 *      erişim denemesi engellenir).
 *   2. `Sidebar` ve sayfa bileşenleri — kullanıcıya yetkisi olmayan menüyü hiç
 *      göstermemek için.
 *
 * ÖNEMLİ: Bu katman bir KOLAYLIKTIR, güvenlik sınırı DEĞİLDİR. Asıl yetki kontrolü
 * sunucudadır (`pkg/middleware.RequireRole`). Panel kontrolü yalnızca kullanıcıyı
 * erişemeyeceği ekranlara götürmemek içindir.
 *
 * Roller AKTİF SİTEYE göre çözümlenir (backend migration 013 + identity servisi).
 */

export const Roles = {
    SuperAdmin: "SUPER_ADMIN",
    Manager: "MANAGER",
    BoardMember: "BOARD_MEMBER",
    Auditor: "AUDITOR",
    Staff: "STAFF",
    Resident: "RESIDENT",
    Owner: "OWNER",
    Tenant: "TENANT",
} as const;

export type Role = (typeof Roles)[keyof typeof Roles];

/**
 * Yönetim yetkisi taşıyan roller.
 *
 * SUPER_ADMIN bilerek YOKTUR: platform rolü site verisine yetki vermez; sunucu
 * da tanımaz (pkg/middleware). Panel onu içeri alsaydı her ekran 403 dönerdi.
 */
export const MANAGEMENT: Role[] = [Roles.Manager, Roles.BoardMember];

/** Yönetim + denetçi (denetçi okur, yazamaz — KMK m.41). */
export const MANAGEMENT_AND_AUDIT: Role[] = [...MANAGEMENT, Roles.Auditor];

/** Yönetim + görevli personel (operasyonel ekranlar). */
export const MANAGEMENT_AND_STAFF: Role[] = [...MANAGEMENT, Roles.Staff];

/**
 * RBAC'ten MUAF yollar — panele girebilen herkese açıktır.
 *
 * NEDEN VAR: `/dashboard/forbidden` yetkisiz kullanıcının YÖNLENDİRİLDİĞİ
 * sayfadır. Bu sayfanın kendisi de rol kontrolünden geçerse, yetkisiz kullanıcı
 * forbidden sayfasına girer → kontrol yine başarısız olur → yine forbidden
 * sayfasına yönlendirilir. Sonuç: tarayıcıda ERR_TOO_MANY_REDIRECTS ve
 * `?from=/dashboard/forbidden` (sayfa kendini işaret eder).
 *
 * Bu sayfa hiçbir iş verisi göstermez — yalnızca kullanıcının kendi rollerini ve
 * erişemediği sayfanın gerektirdiği rolleri yazar — bu yüzden muafiyet güvenlik
 * açığı oluşturmaz.
 */
export const RBAC_EXEMPT_PREFIXES: string[] = ["/dashboard/forbidden"];

/** Yol RBAC kontrolünden muaf mı? */
export function isRbacExempt(pathname: string): boolean {
    return RBAC_EXEMPT_PREFIXES.some(
        (prefix) => pathname === prefix || pathname.startsWith(prefix + "/")
    );
}

/**
 * Yol → erişebilecek roller.
 *
 * En uzun eşleşen ön ek kazanır; listede olmayan `/dashboard` altı yollar
 * varsayılan olarak yönetim + denetçiye açıktır (fail-closed: sakine kapalı).
 */
export const ROUTE_ROLES: { prefix: string; roles: Role[]; reason: string }[] = [
    // Sistem API anahtarları: yalnızca yönetici. Kurul üyesi bile göremez —
    // anahtar sızması tüm entegrasyonları etkiler.
    { prefix: "/dashboard/credentials", roles: [Roles.Manager],
      reason: "Sistem entegrasyon anahtarları" },

    // Personel: maaş, TCKN, SGK bilgisi içerir (KVKK özel önem).
    { prefix: "/dashboard/personnel", roles: MANAGEMENT,
      reason: "Personel özlük ve maaş bilgileri" },

    // Mali ekranlar: denetçi de görebilmeli (KMK m.41 denetim görevi).
    { prefix: "/dashboard/accounting", roles: MANAGEMENT_AND_AUDIT, reason: "Mali kayıtlar" },
    { prefix: "/dashboard/expenses", roles: MANAGEMENT_AND_AUDIT, reason: "Gider kayıtları" },
    { prefix: "/dashboard/assessments", roles: MANAGEMENT_AND_AUDIT, reason: "Tahakkuk kayıtları" },
    { prefix: "/dashboard/reports", roles: MANAGEMENT_AND_AUDIT, reason: "Mali raporlar" },

    // Sakin listesi kimlik ve iletişim bilgisi içerir.
    { prefix: "/dashboard/residents", roles: MANAGEMENT_AND_STAFF, reason: "Sakin kimlik bilgileri" },
    // Bağımsız bölümler ve arsa payları: dağıtımın temeli; denetçi okur (KMK m.41).
    { prefix: "/dashboard/units", roles: MANAGEMENT_AND_AUDIT, reason: "Bağımsız bölüm ve arsa payı kayıtları" },
    // Görevlendirmeler: atama yalnızca yöneticinindir (sunucu da denetler); denetçi okur.
    { prefix: "/dashboard/roles", roles: MANAGEMENT_AND_AUDIT, reason: "Yönetim görevlendirmeleri" },
    { prefix: "/dashboard/kvkk", roles: MANAGEMENT_AND_AUDIT, reason: "KVKK ilgili kişi başvuruları (kişisel veri)" },

    // Operasyonel ekranlar: görevli personel de kullanır.
    { prefix: "/dashboard/meters", roles: MANAGEMENT_AND_STAFF, reason: "Sayaç okuma" },
    { prefix: "/dashboard/parking", roles: MANAGEMENT_AND_STAFF, reason: "Otopark yönetimi" },
    { prefix: "/dashboard/visitors", roles: MANAGEMENT_AND_STAFF, reason: "Ziyaretçi kayıtları" },
    { prefix: "/dashboard/reservations", roles: MANAGEMENT_AND_STAFF, reason: "Rezervasyon yönetimi" },
    { prefix: "/dashboard/requests", roles: MANAGEMENT_AND_STAFF, reason: "Talep yönetimi" },
    { prefix: "/dashboard/announcements", roles: MANAGEMENT_AND_STAFF, reason: "Duyuru yönetimi" },
    { prefix: "/dashboard/notifications", roles: MANAGEMENT, reason: "Toplu bildirim gönderimi" },
    { prefix: "/dashboard/settings", roles: MANAGEMENT, reason: "Site ayarları" },

    // Yönetişim (KMK): denetçi okur (m.41), yazamaz.
    { prefix: "/dashboard/governance", roles: MANAGEMENT_AND_AUDIT, reason: "Yönetişim kayıtları (işletme projesi, genel kurul, defterler)" },
    { prefix: "/dashboard/contracts", roles: MANAGEMENT_AND_AUDIT, reason: "Sözleşmeler" },
    { prefix: "/dashboard/documents", roles: MANAGEMENT_AND_AUDIT, reason: "Belge arşivi" },
    { prefix: "/dashboard/collection", roles: MANAGEMENT_AND_AUDIT, reason: "Tahsilat riski (kişisel mali veri)" },
    { prefix: "/dashboard/nps", roles: MANAGEMENT_AND_AUDIT, reason: "Memnuniyet sonuçları" },
    { prefix: "/dashboard/esg", roles: MANAGEMENT_AND_AUDIT, reason: "Karbon ayak izi" },

    // Operasyonel: görevli de kullanır.
    { prefix: "/dashboard/packages", roles: MANAGEMENT_AND_STAFF, reason: "Kargo kabul ve teslim" },
    { prefix: "/dashboard/assets", roles: [...MANAGEMENT_AND_AUDIT, Roles.Staff], reason: "Demirbaş ve bakım" },
    { prefix: "/dashboard/inventory", roles: [...MANAGEMENT_AND_AUDIT, Roles.Staff], reason: "Stok" },
    { prefix: "/dashboard/patrol", roles: [...MANAGEMENT_AND_AUDIT, Roles.Staff], reason: "Devriye" },
    { prefix: "/dashboard/energy", roles: [...MANAGEMENT_AND_AUDIT, Roles.Staff], reason: "Enerji analizi" },
    { prefix: "/dashboard/surveys", roles: MANAGEMENT, reason: "Anket yönetimi" },
    { prefix: "/dashboard/bulletins", roles: MANAGEMENT, reason: "İlan panosu onayı" },

    // Ana sayfa: panele girebilen herkes.
    { prefix: "/dashboard", roles: [...MANAGEMENT_AND_AUDIT, Roles.Staff], reason: "Yönetim paneli" },
];

/** Verilen yol için gereken rolleri döndürür (en uzun eşleşen ön ek). */
export function requiredRolesFor(pathname: string): { roles: Role[]; reason: string } | null {
    // Muaf yolların rol gereksinimi yoktur (bkz. RBAC_EXEMPT_PREFIXES).
    if (isRbacExempt(pathname)) return null;

    let best: { prefix: string; roles: Role[]; reason: string } | null = null;
    for (const rule of ROUTE_ROLES) {
        if (pathname === rule.prefix || pathname.startsWith(rule.prefix + "/")) {
            if (!best || rule.prefix.length > best.prefix.length) best = rule;
        }
    }
    return best ? { roles: best.roles, reason: best.reason } : null;
}

/** Kullanıcının verilen yola erişip erişemeyeceğini söyler. */
export function canAccess(pathname: string, roles: string[] | undefined | null): boolean {
    const rule = requiredRolesFor(pathname);
    if (!rule) return true; // Panel dışı yollar bu katmanın konusu değil
    if (!roles || roles.length === 0) return false; // Rolü bilinmiyorsa kapalı (fail-closed)
    return rule.roles.some((r) => roles.includes(r));
}

/** Kullanıcı yönetim yetkisine sahip mi? (yazma işlemleri için) */
export function isManagement(roles: string[] | undefined | null): boolean {
    if (!roles) return false;
    return MANAGEMENT.some((r) => roles.includes(r));
}

/** Kullanıcı yalnızca denetçi mi? (okuyabilir, yazamaz) */
export function isAuditorOnly(roles: string[] | undefined | null): boolean {
    if (!roles) return false;
    return roles.includes(Roles.Auditor) && !isManagement(roles);
}
