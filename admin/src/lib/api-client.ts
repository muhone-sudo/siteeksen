import axios, { AxiosInstance, AxiosError } from "axios";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8888/api/v1";

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
                const originalRequest = error.config as any;
                if (error.response?.status === 401 && !originalRequest._retry) {
                    originalRequest._retry = true;
                    try {
                        const refreshToken = typeof window !== "undefined"
                            ? localStorage.getItem("refresh_token")
                            : null;
                        if (!refreshToken) throw new Error("No refresh token");

                        const res = await this.client.post("/auth/refresh", { refresh_token: refreshToken });
                        const { access_token, refresh_token } = res.data;

                        this.setToken(access_token);
                        if (typeof window !== "undefined") {
                            localStorage.setItem("refresh_token", refresh_token);
                        }
                        originalRequest.headers["Authorization"] = `Bearer ${access_token}`;
                        return this.client(originalRequest);
                    } catch {
                        this.clearToken();
                        if (typeof window !== "undefined") {
                            localStorage.removeItem("refresh_token");
                            window.location.href = "/login";
                        }
                    }
                }
                return Promise.reject(error);
            }
        );
    }

    setToken(token: string, refreshToken?: string) {
        this.accessToken = token;
        if (typeof window !== "undefined") {
            localStorage.setItem("access_token", token);
            if (refreshToken) localStorage.setItem("refresh_token", refreshToken);
        }
    }

    clearToken() {
        this.accessToken = null;
        if (typeof window !== "undefined") {
            localStorage.removeItem("access_token");
            localStorage.removeItem("refresh_token");
        }
    }

    loadToken() {
        if (typeof window !== "undefined") {
            this.accessToken = localStorage.getItem("access_token");
        }
    }

    getActivePropertyId(): string | null {
        if (!this.accessToken) return null;
        try {
            const payload = JSON.parse(atob(this.accessToken.split(".")[1]));
            return payload.property_id ?? null;
        } catch {
            return null;
        }
    }

    // ============ AUTH ============
    async login(phone: string, password: string) {
        const response = await this.client.post("/auth/login", { phone, password });
        if (response.data.access_token) {
            this.setToken(response.data.access_token, response.data.refresh_token);
        }
        return response.data;
    }

    async logout() {
        await this.client.post("/auth/logout");
        this.clearToken();
    }

    async refreshAccessToken() {
        const refreshToken = typeof window !== "undefined"
            ? localStorage.getItem("refresh_token")
            : null;
        if (!refreshToken) throw new Error("No refresh token");

        const response = await this.client.post("/auth/refresh", { refresh_token: refreshToken });
        this.setToken(response.data.access_token, response.data.refresh_token);
        return response.data;
    }

    // ============ USERS ============
    async getCurrentUser() {
        const response = await this.client.get("/users/me");
        return response.data;
    }

    async getUserProperties() {
        const response = await this.client.get("/users/me/properties");
        return response.data as { property_id: string; property_name: string; unit_id: string; unit_name: string; role: string }[];
    }

    async setActiveProperty(propertyId: string) {
        const response = await this.client.post("/users/me/active-property", { property_id: propertyId });
        return response.data;
    }

    async createProperty(data: { name: string; type: string; address: string; city: string; district?: string }) {
        const response = await this.client.post("/users/me/properties", data);
        return response.data as { id: string; name: string; type: string; address: string; city: string };
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
        role: string;
        is_active: boolean;
    }>) {
        const response = await this.client.patch(`/residents/${id}`, data);
        return response.data;
    }

    async getUnits() {
        const response = await this.client.get("/units");
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

    async getAssessmentOverview(params?: { year?: number }) {
        const response = await this.client.get("/finance/assessments/overview", { params });
        return response.data;
    }

    async createAssessment(data: {
        period_year: number;
        period_month: number;
        due_date: string;
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

    async getDebtors() {
        const response = await this.client.get("/finance/debtors");
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

    // ============ EXPENSES ============
    async getExpenses(params?: { month?: string; category?: string; status?: string }) {
        const response = await this.client.get("/expenses", { params });
        return response.data;
    }

    async createExpense(data: {
        category: string;
        description: string;
        amount: number;
        expense_date: string;
        is_recurring?: boolean;
        vendor_name?: string;
    }) {
        const response = await this.client.post("/expenses", data);
        return response.data;
    }

    async getExpenseSummary() {
        const response = await this.client.get("/expenses/summary");
        return response.data;
    }

    // ============ NOTIFICATIONS ============
    async getNotifications(params?: { limit?: number; status?: string }) {
        const response = await this.client.get("/notifications", { params });
        return response.data;
    }

    async sendNotification(data: {
        title: string;
        message: string;
        channel: string;
        audience_type: string;
    }) {
        const response = await this.client.post("/notifications/send", data);
        return response.data;
    }

    async getNotificationHistory(params?: { limit?: number }) {
        const response = await this.client.get("/notifications/history", { params });
        return response.data;
    }

    // ============ CREDENTIALS (Settings Service) ============
    async getApiCredentials() {
        const response = await this.client.get("/credentials");
        return response.data;
    }

    async createApiCredential(data: {
        service_name: string;
        api_key: string;
        api_secret?: string;
        extra_config?: Record<string, string>;
        is_active?: boolean;
    }) {
        const response = await this.client.post("/credentials", data);
        return response.data;
    }

    async testApiCredential(id: string) {
        const response = await this.client.post(`/credentials/${id}/test`);
        return response.data;
    }

    async deleteApiCredential(id: string) {
        await this.client.delete(`/credentials/${id}`);
    }

    // ============ PARKING ============
    async getVehicles(params?: { unit_id?: string }) {
        const response = await this.client.get("/vehicles", { params });
        return response.data;
    }

    async createVehicle(data: { plate: string; type: string; unit_id?: string; owner_name?: string }) {
        const response = await this.client.post("/vehicles", data);
        return response.data;
    }

    async deleteVehicle(id: string) {
        await this.client.delete(`/vehicles/${id}`);
    }

    async getParkingZones() {
        const response = await this.client.get("/parking-zones");
        return response.data;
    }

    async getCurrentVehicles() {
        const response = await this.client.get("/parking-logs/current");
        return response.data;
    }

    async getParkingStats() {
        const response = await this.client.get("/parking-logs/stats");
        return response.data;
    }

    async recordEntry(data: { plate?: string; vehicle_id?: string; zone_id?: string }) {
        const response = await this.client.post("/parking-logs/entry", data);
        return response.data;
    }

    // ============ PERSONNEL ============
    async getEmployees() {
        const response = await this.client.get("/employees");
        return response.data;
    }

    async getEmployeeStats() {
        const response = await this.client.get("/employees/stats");
        return response.data;
    }

    async createEmployee(data: {
        first_name: string; last_name: string; role: string;
        salary: number; phone?: string; start_date?: string;
    }) {
        const response = await this.client.post("/employees", data);
        return response.data;
    }

    async deleteEmployee(id: string) {
        await this.client.delete(`/employees/${id}`);
    }

    async getLeaves(params?: { status?: string }) {
        const response = await this.client.get("/leaves", { params });
        return response.data;
    }

    async approveLeave(id: string) {
        const response = await this.client.post(`/leaves/${id}/approve`);
        return response.data;
    }

    // ============ RESERVATIONS ============
    async getFacilities() {
        const response = await this.client.get("/facilities");
        return response.data;
    }

    async getReservations(params?: { status?: string }) {
        const response = await this.client.get("/reservations", { params });
        return response.data;
    }

    async getTodayReservations() {
        const response = await this.client.get("/reservations/today");
        return response.data;
    }

    async createReservation(data: {
        facility_id: string; resident_id?: string; unit_number?: string;
        start_time: string; end_time: string; notes?: string;
    }) {
        const response = await this.client.post("/reservations", data);
        return response.data;
    }

    async cancelReservation(id: string) {
        await this.client.delete(`/reservations/${id}`);
    }

    // ============ VISITORS ============
    async getVisitors(params?: { status?: string }) {
        const response = await this.client.get("/visitors", { params });
        return response.data;
    }

    async getTodayVisitors() {
        const response = await this.client.get("/visitors/today");
        return response.data;
    }

    async getCurrentVisitors() {
        const response = await this.client.get("/visitors/inside");
        return response.data;
    }

    async getVisitorStats() {
        const response = await this.client.get("/visitors/stats");
        return response.data;
    }

    async createVisitor(data: {
        name: string; phone?: string; unit_number: string;
        visit_purpose?: string; expected_at?: string;
    }) {
        const response = await this.client.post("/visitors", data);
        return response.data;
    }

    async checkInVisitor(id: string) {
        const response = await this.client.post(`/visitors/${id}/checkin`);
        return response.data;
    }

    async checkOutVisitor(id: string) {
        const response = await this.client.post(`/visitors/${id}/checkout`);
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
