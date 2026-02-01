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
        roles: string[];
        propertyId: string;
        phone: string;
    }
}
