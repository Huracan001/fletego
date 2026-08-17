import {
  EmptyState,
  PageHeader,
  Panel,
  StatusBadge,
} from "@/components/ui";
import { createServiceClient } from "@/lib/supabase/admin";

export default async function TripsPage() {
  const admin = createServiceClient();
  const { data } = await admin
    .from("trips")
    .select(
      "id, status, customer_id, driver_id, company_id, assigned_at, created_at, cancel_reason",
    )
    .is("deleted_at", null)
    .order("created_at", { ascending: false })
    .limit(80);

  const disputed = (data ?? []).filter((t) => t.status === "disputed");

  return (
    <div className="space-y-6">
      <PageHeader
        title="Viajes"
        description="Vista operativa de trips recientes. Disputas detalladas en /disputes."
      />
      {disputed.length > 0 ? (
        <Panel title={`En disputa (${disputed.length})`}>
          <ul className="space-y-2 text-sm">
            {disputed.map((t) => (
              <li key={t.id} className="flex justify-between gap-3">
                <span className="font-mono text-xs">{t.id}</span>
                <StatusBadge label="disputed" tone="danger" />
              </li>
            ))}
          </ul>
        </Panel>
      ) : null}
      <Panel title={`${data?.length ?? 0} recientes`}>
        {!data?.length ? (
          <EmptyState title="Sin viajes" message="Aún no hay trips." />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[720px] text-left text-sm">
              <thead className="text-[var(--fg-muted)]">
                <tr className="border-b border-[var(--fg-border)]">
                  <th className="py-2 pr-3 font-medium">Trip</th>
                  <th className="py-2 pr-3 font-medium">Estado</th>
                  <th className="py-2 pr-3 font-medium">Customer</th>
                  <th className="py-2 pr-3 font-medium">Driver</th>
                  <th className="py-2 font-medium">Creado</th>
                </tr>
              </thead>
              <tbody>
                {data.map((row) => (
                  <tr
                    key={row.id}
                    className="border-b border-[var(--fg-border)] last:border-0"
                  >
                    <td className="py-3 pr-3 font-mono text-xs">{row.id}</td>
                    <td className="py-3 pr-3">
                      <StatusBadge
                        label={row.status}
                        tone={
                          row.status === "disputed"
                            ? "danger"
                            : row.status === "completed" ||
                                row.status === "delivered"
                              ? "success"
                              : row.status === "cancelled" ||
                                  row.status === "failed"
                                ? "neutral"
                                : "primary"
                        }
                      />
                    </td>
                    <td className="py-3 pr-3 font-mono text-xs">
                      {row.customer_id}
                    </td>
                    <td className="py-3 pr-3 font-mono text-xs">
                      {row.driver_id}
                    </td>
                    <td className="py-3 text-[var(--fg-muted)]">
                      {row.created_at
                        ? new Date(row.created_at).toLocaleString("es-BO")
                        : "—"}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Panel>
    </div>
  );
}
