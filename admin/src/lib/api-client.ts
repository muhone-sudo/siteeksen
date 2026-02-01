import axios, { AxiosInstance, AxiosError } from "axios";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api/v1";

class ApiClient {
    private client: AxiosInstance;
    private accessToken: string | null = null;

    constructor() {
        this.client = axios.create({
            baseURL: API_BASE_URL,
            headers: {
                "Content-Type": "application/json",
            },
        });

        this.client.interceptors.request.use((config) => {
            if (this.accessToken) {
                config.headers.Authorization = `Bearer ${this.accessToken}`;
            }
            return config;
        });

        this.client.interceptors.response.use(
            (response) => response,
            async (error: AxiosError) => {
                if (error.response?.status === 401) {
                    // Token expired, try refresh
                    // TODO: Implement refresh logic
                }
                return Promise.reject(error);
            }
        );
    }

    setToken(token: string) {
        this.accessToken = token;
        if (typeof window !== "undefined") {
            localStorage.setItem("access_token", token);
        }
    }

    clearToken() {
        this.accessToken = null;
        if (typeof window !== "undefined") {
            localStorage.removeItem("access_token");
        }
    }

    loadToken() {
        if (typeof window !== "undefined") {
            this.accessToken = localStorage.getItem("access_token");
        }
    }

    // ============ AUTH ============
    async login(phone: string, password: string) {
        const response = await this.client.post("/auth/login", { phone, password });
        if (response.data.access_token) {
            this.setToken(response.data.access_token);
        }
        return response.data;
    }

    async logout() {
        await this.client.post("/auth/logout");
        this.clearToken();
    }

    // ============ USERS ============
    async getCurrentUser() {
        const response = await this.client.get("/users/me");
        return response.data;
    }

    async getResidents(params?: { search?: string; block?: string; role?: string }) {
        const response = await this.client.get("/residents", { params });
        return response.data;
    }

    async createResident(data: {
        first_name: string;
        last_name: string;
        phone: string;
        email?: string;
        unit_id: string;
        role: string;
    }) {
        const response = await this.client.post("/residents", data);
        return response.data;
    }

    async updateResident(id: string, data: Partial<{
        first_name: string;
        last_name: string;
        phone: string;
        email: string;
    }>) {
        const response = await this.client.patch(`/residents/${id}`, data);
        return response.data;
    }

    // ============ FINANCE ============
    async getDebtStatus() {
        const response = await this.client.get("/finance/debt-status");
        return response.data;
    }

    async getAssessments(params?: { year?: number; month?: number }) {
        const response = await this.client.get("/finance/assessments", { params });
        return response.data;
    }

    async createAssessment(data: {
        period_year: number;
        period_month: number;
        expense_items: { category_id: string; amount: number }[];
    }) {
        const response = await this.client.post("/finance/assessments", data);
        return response.data;
    }

    async getPayments(params?: { status?: string; limit?: number }) {
        const response = await this.client.get("/finance/payments", { params });
        return response.data;
    }

    async getExpenseCategories() {
        const response = await this.client.get("/finance/expense-categories");
        return response.data;
    }

    // ============ METERS ============
    async getMeters(params?: { type?: string; block?: string }) {
        const response = await this.client.get("/meters", { params });
        return response.data;
    }

    async submitMeterReadings(data: {
        period_year: number;
        period_month: number;
        readings: { meter_id: string; value: number }[];
    }) {
        const response = await this.client.post("/meters/readings", data);
        return response.data;
    }

    async getConsumptionSummary(params?: { meter_type?: string }) {
        const response = await this.client.get("/finance/consumption/summary", { params });
        return response.data;
    }

    // ============ ANNOUNCEMENTS ============
    async getAnnouncements(params?: { category?: string }) {
        const response = await this.client.get("/announcements", { params });
        return response.data;
    }

    async createAnnouncement(data: {
        title: string;
        content: string;
        category: string;
        priority: string;
        is_pinned?: boolean;
    }) {
        const response = await this.client.post("/announcements", data);
        return response.data;
    }

    async deleteAnnouncement(id: string) {
        await this.client.delete(`/announcements/${id}`);
    }

    // ============ REQUESTS ============
    async getRequests(params?: { status?: string }) {
        const response = await this.client.get("/requests", { params });
        return response.data;
    }

    async updateRequestStatus(id: string, status: string, comment?: string) {
        const response = await this.client.patch(`/requests/${id}/status`, {
            status,
            comment,
        });
        return response.data;
    }

    async assignRequest(id: string, assigneeId: string) {
        const response = await this.client.patch(`/requests/${id}/assign`, {
            assignee_id: assigneeId,
        });
        return response.data;
    }

    // ============ DASHBOARD ============
    async getDashboardStats() {
        const response = await this.client.get("/dashboard/stats");
        return response.data;
    }

    async getRecentPayments(limit: number = 5) {
        const response = await this.client.get("/dashboard/recent-payments", {
            params: { limit },
        });
        return response.data;
    }

    async getRecentRequests(limit: number = 5) {
        const response = await this.client.get("/dashboard/recent-requests", {
            params: { limit },
        });
        return response.data;
    }

    // ============ REPORTS ============
    async generateReport(type: string, params: Record<string, unknown>) {
        const response = await this.client.post("/reports/generate", {
            type,
            ...params,
        });
        return response.data;
    }

    async downloadReport(reportId: string) {
        const response = await this.client.get(`/reports/${reportId}/download`, {
            responseType: "blob",
        });
        return response.data;
    }
}

export const apiClient = new ApiClient();
export default apiClient;
