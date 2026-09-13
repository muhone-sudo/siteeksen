/**
 * TanStack Query kancaları.
 *
 * TEMİZLİK (2026-09-13, todo 0.A.8 / gap-analizi B93):
 * Bu dosyada 17 kanca vardı ve bunların 13'ü HİÇBİR yerden çağrılmıyordu.
 * Ölü kod, olmayan bir veri katmanı izlenimi verir: yeni geliştirici "veri
 * TanStack Query ile yönetiliyor" sanıp yanlış yerde arar. Kullanılmayanlar
 * kaldırıldı.
 *
 * KURAL: Buraya yalnızca GERÇEKTEN kullanılan kancalar eklenir. Bir ekran
 * doğrudan `apiClient` çağırıyorsa, "ileride lazım olur" diye kanca yazılmaz.
 */

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import apiClient from "@/lib/api-client";

// ============ TAHAKKUK / MALİ ============

export function useCreateAssessment() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: apiClient.createAssessment,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ["assessments"] });
            queryClient.invalidateQueries({ queryKey: ["assessment-overview"] });
            queryClient.invalidateQueries({ queryKey: ["debtors"] });
        },
    });
}

export function useExpenseCategories() {
    return useQuery({
        queryKey: ["expense-categories"],
        queryFn: () => apiClient.getExpenseCategories(),
    });
}

export function useAssessmentOverview(params?: { year?: number }) {
    return useQuery({
        queryKey: ["assessment-overview", params],
        queryFn: () => apiClient.getAssessmentOverview(params),
    });
}

export function useDebtors() {
    return useQuery({
        queryKey: ["debtors"],
        queryFn: () => apiClient.getDebtors(),
    });
}
