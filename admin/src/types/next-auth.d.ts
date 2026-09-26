import "next-auth";

declare module "next-auth" {
    interface User {
        id: string;
        name: string;
        email?: string;
        phone: string;
        roles: string[];
        accessToken: string;
        refreshToken: string;
        propertyId: string;
    }

    interface Session {
        accessToken: string;
        refreshToken: string;
        /** Sunucu tarafı jeton yenilemesi başarısız olduysa dolu (oturum kapatılır). */
        error?: string;
        user: {
            id: string;
            name: string;
            email?: string;
            phone: string;
            roles: string[];
            propertyId: string;
        };
    }
}

declare module "next-auth/jwt" {
    interface JWT {
        accessToken: string;
        refreshToken: string;
        /** Erişim jetonunun bitiş anı (ms). */
        accessExpires?: number;
        roles: string[];
        propertyId: string;
        phone: string;
        error?: string;
    }
}
