import { ConfirmActionButton } from "@/components/confirm-action-button";
import {
  EmptyState,
  PageHeader,
  Panel,
  StatusBadge,
} from "@/components/ui";
import { resolveDispute } from "@/lib/actions";
import { createServiceClient } from "@/lib/supabase/admin";

export default async function DisputesPage() {
  const admin = createServiceClient();
  const { data: disputes, error } = await admin
    .from("disputes")
    .select(
      "id, trip_id, opened_by, reason, status, resolution, created_at, resolved_at",
    )
    .is("deleted_at", null)
    .order("created_at", { ascending: false })
    .limit(60);

  const { data: disputedTrips } = await admin
    .from("trips")
    .select("id, status, customer_id, driver_id, created_at, cancel_reason")
    .eq("status", "disputed")
    .is("deleted_at", null)
    .order("created_at", { ascending: false })
    .limit(40);

  const missingTable =
    error?.message?.toLowerCase().includes("disputes") ||
    error?.code === "42P01" ||
    error?.code === "PGRST205";

  return (
    <div className="space-y-6">
      <PageHeader
        title="Disputas"
        description="Casos abiertos y viajes en estado disputed."
      />

      <Panel title="Viajes disputed">
        {!disputedTrips?.length ? (
          <EmptyState
            title="Ninguno"
            message="No hay trips con status disputed."
          />
        ) : (
          <ul className="divide-y divide-[var(--fg-border)]">
            {disputedTrips.map((t) => (
              <li key={t.id} className="py-3 text-sm">
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <span className="font-mono text-xs">{t.id}</span>
                  <StatusBadge label="disputed" tone="danger" />
                </div>
                <p className="mt-1 text-[var(--fg-muted)]">
                  Customer {t.customer_id} · Driver {t.driver_id}
                  {t.cancel_reason ? ` · ${t.cancel_reason}` : ""}
                </p>
              </li>
            ))}
          </ul>
        )}
      </Panel>

      <Panel title={`Casos (${disputes?.length ?? 0})`}>
        {missingTable ? (
          <EmptyState
            title="Tabla disputes pendiente"
            message="Aplica supabase/migrations/20260818070000_phase13_admin.sql"
          />
        ) : !disputes?.length ? (
          <EmptyState
            title="Sin casos"
            message="Todavía no hay filas en disputes."
          />
        ) : (
          <ul className="divide-y divide-[var(--fg-border)]">
            {disputes.map((d) => (
              <li
                key={d.id}
                className="flex flex-wrap items-start justify-between gap-3 py-3"
              >
                <div className="min-w-0 flex-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <StatusBadge
                      label={d.status}
                      tone={
                        d.status === "open" || d.status === "under_review"
                          ? "warning"
                          : d.status === "resolved"
                            ? "success"
                            : "neutral"
                      }
                    />
                    <span className="font-mono text-xs text-[var(--fg-muted)]">
                      trip {d.trip_id}
                    </span>
                  </div>
                  <p className="mt-1 text-sm">{d.reason}</p>
                  {d.resolution ? (
                    <p className="mt-1 text-sm text-[var(--fg-muted)]">
                      Resolución: {d.resolution}
                    </p>
                  ) : null}
                </div>
                {d.status === "open" || d.status === "under_review" ? (
                  <div className="flex gap-2">
                    <ConfirmActionButton
                      label="Resolver"
                      askReason
                      onConfirm={(resolution) =>
                        resolveDispute({
                          disputeId: d.id,
                          status: "resolved",
                          resolution: resolution ?? "Resuelto",
                          tripId: d.trip_id,
                          closeTripAs: "completed",
                        })
                      }
                    />
                    <ConfirmActionButton
                      label="Descartar"
                      tone="danger"
                      askReason
                      onConfirm={(resolution) =>
                        resolveDispute({
                          disputeId: d.id,
                          status: "dismissed",
                          resolution: resolution ?? "Descartado",
                          tripId: d.trip_id,
                          closeTripAs: "cancelled",
                        })
                      }
                    />
                  </div>
                ) : null}
              </li>
            ))}
          </ul>
        )}
      </Panel>
    </div>
  );
}
