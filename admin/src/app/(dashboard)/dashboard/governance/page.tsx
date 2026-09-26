import { redirect } from "next/navigation";

/** /dashboard/governance → işletme projesi (varsayılan alt sayfa). */
export default function GovernanceIndex() {
    redirect("/dashboard/governance/budgets");
}
