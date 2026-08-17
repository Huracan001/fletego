import { ConfirmActionButton } from "@/components/confirm-action-button";
import {
  EmptyState,
  PageHeader,
  Panel,
  StatusBadge,
  verificationTone,
} from "@/components/ui";
import {
  approveCompany,
  approveDriver,
  approveVehicle,
  rejectCompany,
  rejectDriver,
  rejectVehicle,
  setDocumentStatus,
} from "@/lib/actions";
import { createServiceClient } from "@/lib/supabase/admin";

export default async function VerificationPage() {
  const admin = createServiceClient();

  const [companies, drivers, vehicles, driverDocs, vehicleDocs] =
    await Promise.all([
      admin
        .from("companies")
        .select("id, name, nit, company_type, verification_status, created_at")
        .eq("verification_status", "pending")
        .is("deleted_at", null)
        .order("created_at", { ascending: false })
        .limit(40),
      admin
        .from("driver_profiles")
        .select(
          "id, license_number, verification_status, created_at, user_id, profiles:user_id(full_name, email)",
        )
        .eq("verification_status", "pending")
        .is("deleted_at", null)
        .order("created_at", { ascending: false })
        .limit(40),
      admin
        .from("vehicles")
        .select(
          "id, plate, brand, model, verification_status, created_at, company_id",
        )
        .eq("verification_status", "pending")
        .is("deleted_at", null)
        .order("created_at", { ascending: false })
        .limit(40),
      admin
        .from("driver_documents")
        .select("id, kind, verification_status, storage_path, created_at")
        .eq("verification_status", "pending")
        .order("created_at", { ascending: false })
        .limit(40),
      admin
        .from("vehicle_documents")
        .select("id, kind, verification_status, storage_path, created_at")
        .eq("verification_status", "pending")
        .order("created_at", { ascending: false })
        .limit(40),
    ]);

  return (
    <div className="space-y-6">
      <PageHeader
        title="Verificación"
        description="Aprueba o rechaza empresas, conductores, vehículos y documentos pendientes."
      />

      <Panel title={`Empresas (${companies.data?.length ?? 0})`}>
        {!companies.data?.length ? (
          <EmptyState title="Sin pendientes" message="No hay empresas en cola." />
        ) : (
          <ul className="divide-y divide-[var(--fg-border)]">
            {companies.data.map((row) => (
              <li
                key={row.id}
                className="flex flex-wrap items-center justify-between gap-3 py-3"
              >
                <div>
                  <p className="font-medium">{row.name}</p>
                  <p className="text-sm text-[var(--fg-muted)]">
                    {row.company_type}
                    {row.nit ? ` · NIT ${row.nit}` : ""}
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  <StatusBadge
                    label={row.verification_status}
                    tone={verificationTone(row.verification_status)}
                  />
                  <ConfirmActionButton
                    label="Aprobar"
                    onConfirm={() => approveCompany(row.id)}
                  />
                  <ConfirmActionButton
                    label="Rechazar"
                    tone="danger"
                    askReason
                    onConfirm={(reason) =>
                      rejectCompany(row.id, reason ?? "Rechazado")
                    }
                  />
                </div>
              </li>
            ))}
          </ul>
        )}
      </Panel>

      <Panel title={`Conductores (${drivers.data?.length ?? 0})`}>
        {!drivers.data?.length ? (
          <EmptyState
            title="Sin pendientes"
            message="No hay perfiles de conductor en cola."
          />
        ) : (
          <ul className="divide-y divide-[var(--fg-border)]">
            {drivers.data.map((row) => {
              const profile = Array.isArray(row.profiles)
                ? row.profiles[0]
                : row.profiles;
              return (
                <li
                  key={row.id}
                  className="flex flex-wrap items-center justify-between gap-3 py-3"
                >
                  <div>
                    <p className="font-medium">
                      {(profile as { full_name?: string } | null)?.full_name ||
                        "Conductor"}
                    </p>
                    <p className="text-sm text-[var(--fg-muted)]">
                      {(profile as { email?: string } | null)?.email ||
                        row.user_id}
                      {row.license_number
                        ? ` · Lic. ${row.license_number}`
                        : ""}
                    </p>
                  </div>
                  <div className="flex items-center gap-2">
                    <ConfirmActionButton
                      label="Aprobar"
                      onConfirm={() => approveDriver(row.id)}
                    />
                    <ConfirmActionButton
                      label="Rechazar"
                      tone="danger"
                      askReason
                      onConfirm={(reason) =>
                        rejectDriver(row.id, reason ?? "Rechazado")
                      }
                    />
                  </div>
                </li>
              );
            })}
          </ul>
        )}
      </Panel>

      <Panel title={`Vehículos (${vehicles.data?.length ?? 0})`}>
        {!vehicles.data?.length ? (
          <EmptyState title="Sin pendientes" message="No hay vehículos en cola." />
        ) : (
          <ul className="divide-y divide-[var(--fg-border)]">
            {vehicles.data.map((row) => (
              <li
                key={row.id}
                className="flex flex-wrap items-center justify-between gap-3 py-3"
              >
                <div>
                  <p className="font-medium">{row.plate}</p>
                  <p className="text-sm text-[var(--fg-muted)]">
                    {[row.brand, row.model].filter(Boolean).join(" ") ||
                      "Sin marca"}
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  <ConfirmActionButton
                    label="Aprobar"
                    onConfirm={() => approveVehicle(row.id)}
                  />
                  <ConfirmActionButton
                    label="Rechazar"
                    tone="danger"
                    askReason
                    onConfirm={(reason) =>
                      rejectVehicle(row.id, reason ?? "Rechazado")
                    }
                  />
                </div>
              </li>
            ))}
          </ul>
        )}
      </Panel>

      <Panel
        title={`Documentos (${(driverDocs.data?.length ?? 0) + (vehicleDocs.data?.length ?? 0)})`}
      >
        {!driverDocs.data?.length && !vehicleDocs.data?.length ? (
          <EmptyState
            title="Sin pendientes"
            message="No hay documentos por revisar."
          />
        ) : (
          <ul className="divide-y divide-[var(--fg-border)]">
            {(driverDocs.data ?? []).map((row) => (
              <li
                key={`d-${row.id}`}
                className="flex flex-wrap items-center justify-between gap-3 py-3"
              >
                <div>
                  <p className="font-medium">Driver · {row.kind}</p>
                  <p className="text-sm break-all text-[var(--fg-muted)]">
                    {row.storage_path || "Sin archivo"}
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  <ConfirmActionButton
                    label="Aprobar"
                    onConfirm={() =>
                      setDocumentStatus({
                        table: "driver_documents",
                        id: row.id,
                        status: "approved",
                      })
                    }
                  />
                  <ConfirmActionButton
                    label="Rechazar"
                    tone="danger"
                    askReason
                    onConfirm={(reason) =>
                      setDocumentStatus({
                        table: "driver_documents",
                        id: row.id,
                        status: "rejected",
                        rejectionReason: reason,
                      })
                    }
                  />
                </div>
              </li>
            ))}
            {(vehicleDocs.data ?? []).map((row) => (
              <li
                key={`v-${row.id}`}
                className="flex flex-wrap items-center justify-between gap-3 py-3"
              >
                <div>
                  <p className="font-medium">Vehicle · {row.kind}</p>
                  <p className="text-sm break-all text-[var(--fg-muted)]">
                    {row.storage_path || "Sin archivo"}
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  <ConfirmActionButton
                    label="Aprobar"
                    onConfirm={() =>
                      setDocumentStatus({
                        table: "vehicle_documents",
                        id: row.id,
                        status: "approved",
                      })
                    }
                  />
                  <ConfirmActionButton
                    label="Rechazar"
                    tone="danger"
                    askReason
                    onConfirm={(reason) =>
                      setDocumentStatus({
                        table: "vehicle_documents",
                        id: row.id,
                        status: "rejected",
                        rejectionReason: reason,
                      })
                    }
                  />
                </div>
              </li>
            ))}
          </ul>
        )}
      </Panel>
    </div>
  );
}
