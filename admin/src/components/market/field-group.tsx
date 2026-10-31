import type { ReactNode } from "react";

/**
 * Birden çok denetim içeren alan (onay kutusu grubu, harita). `Field` içeriği <label> ile sarar; içine onay kutusu
 * grubu konursa etiketler iç içe geçer ve alan başlığına tıklamak ilk kutuyu işaretler. Bu bileşen <div> kullanır.
 */
export function FieldGroup({ label, hint, children, required }: { label: string; hint?: string; children: ReactNode; required?: boolean }) {
    return (
        <div role="group" aria-label={label}>
            <span className="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300">
                {label}
                {required && <span className="text-red-600"> *</span>}
            </span>
            {children}
            {hint && <span className="mt-1 block text-xs text-gray-500">{hint}</span>}
        </div>
    );
}
