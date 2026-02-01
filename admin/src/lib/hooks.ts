import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import apiClient from "@/lib/api-client";

// ============ DASHBOARD ============
export function useDashboardStats() {
    return useQuery({
        queryKey: ["dashboard", "stats"],
        queryFn: () => apiClient.getDashboardStats(),
    });
}

export function useRecentPayments(limit = 5) {
    return useQuery({
        queryKey: ["dashboard", "recent-payments", limit],
        queryFn: () => apiClient.getRecentPayments(limit),
    });
}

export function useRecentRequests(limit = 5) {
    return useQuery({
        queryKey: ["dashboard", "recent-requests", limit],
        queryFn: () => apiClient.getRecentRequests(limit),
    });
}

// ============ RESIDENTS ============
export function useResidents(params?: { search?: string; block?: string; role?: string }) {
    return useQuery({
        queryKey: ["residents", params],
        queryFn: () => apiClient.getResidents(params),
    });
}

export function useCreateResident() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: apiClient.createResident,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ["residents"] });
        },
    });
}

// ============ ASSESSMENTS ============
export function useAssessments(params?: { year?: number }) {
    return useQuery({
        queryKey: ["assessments", params],
        queryFn: () => apiClient.getAssessments(params),
    });
}

export function useCreateAssessment() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: apiClient.createAssessment,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ["assessments"] });
        },
    });
}

export function useExpenseCategories() {
    return useQuery({
        queryKey: ["expense-categories"],
        queryFn: () => apiClient.getExpenseCategories(),
    });
}

// ============ METERS ============
export function useMeters(params?: { type?: string }) {
    return useQuery({
        queryKey: ["meters", params],
        queryFn: () => apiClient.getMeters(params),
    });
}

export function useSubmitMeterReadings() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: apiClient.submitMeterReadings,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ["meters"] });
        },
    });
}

// ============ ANNOUNCEMENTS ============
export function useAnnouncements(params?: { category?: string }) {
    return useQuery({
        queryKey: ["announcements", params],
        queryFn: () => apiClient.getAnnouncements(params),
    });
}

export function useCreateAnnouncement() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: apiClient.createAnnouncement,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ["announcements"] });
        },
    });
}

// ============ REQUESTS ============
export function useRequests(params?: { status?: string }) {
    return useQuery({
        queryKey: ["requests", params],
        queryFn: () => apiClient.getRequests(params),
    });
}

export function useUpdateRequestStatus() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: ({ id, status, comment }: { id: string; status: string; comment?: string }) =>
            apiClient.updateRequestStatus(id, status, comment),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ["requests"] });
        },
    });
}

// ============ REPORTS ============
export function useGenerateReport() {
    return useMutation({
        mutationFn: ({ type, params }: { type: string; params: Record<string, unknown> }) =>
            apiClient.generateReport(type, params),
    });
}
