import { ConfirmActionButton } from "@/components/confirm-action-button";
import {
  EmptyState,
  PageHeader,
  Panel,
  StatusBadge,
} from "@/components/ui";
import { setVehicleTypeActive, upsertAppConfig } from "@/lib/actions";
import { createServiceClient } from "@/lib/supabase/admin";

export default async function ConfigPage() {
  const admin = createServiceClient();
  const [{ data: types }, { data: configs, error: configError }] =
    await Promise.all([
      admin
        .from("vehicle_types")
        .select(
          "id, code, name_es, name_en, is_active, typical_max_weight_kg, supports_container, supports_refrigeration",
        )
        .order("name_es"),
      admin.from("app_config").select("key, value, description, updated_at"),
    ]);

  const configMissing =
    configError?.message?.toLowerCase().includes("app_config") ||
    configError?.code === "PGRST205";

  return (
    <div className="space-y-6">
      <PageHeader
        title="Configuración"
        description="Catálogo de tipos de vehículo y flags de sistema."
      />

      <Panel title="Tipos de vehículo">
        {!types?.length ? (
          <EmptyState title="Vacío" message="No hay vehicle_types." />
        ) : (
          <ul className="divide-y divide-[var(--fg-border)]">
            {types.map((t) => (
              <li
                key={t.id}
                className="flex flex-wrap items-center justify-between gap-3 py-3"
              >
                <div>
                  <p className="font-medium">
                    {t.name_es}{" "}
                    <span className="text-[var(--fg-muted)]">({t.code})</span>
                  </p>
                  <p className="text-sm text-[var(--fg-muted)]">
                    {t.typical_max_weight_kg
                      ? `${t.typical_max_weight_kg} kg`
                      : "Sin peso típico"}
                    {t.supports_container ? " · contenedor" : ""}
                    {t.supports_refrigeration ? " · refrigerado" : ""}
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  <StatusBadge
                    label={t.is_active ? "activo" : "inactivo"}
                    tone={t.is_active ? "success" : "neutral"}
                  />
                  <ConfirmActionButton
                    label={t.is_active ? "Desactivar" : "Activar"}
                    tone={t.is_active ? "neutral" : "primary"}
                    onConfirm={() => setVehicleTypeActive(t.id, !t.is_active)}
                  />
                </div>
              </li>
            ))}
          </ul>
        )}
      </Panel>

      <Panel title="app_config">
        {configMissing ? (
          <EmptyState
            title="Tabla app_config pendiente"
            message="Aplica supabase/migrations/20260818070000_phase13_admin.sql"
          />
        ) : !configs?.length ? (
          <EmptyState title="Sin keys" message="No hay configuración." />
        ) : (
          <ul className="divide-y divide-[var(--fg-border)]">
            {configs.map((c) => (
              <li key={c.key} className="py-3">
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div>
                    <p className="font-medium">{c.key}</p>
                    <p className="text-sm text-[var(--fg-muted)]">
                      {c.description || "—"}
                    </p>
                    <pre className="mt-2 overflow-x-auto rounded-lg bg-[var(--fg-bg)] p-2 text-xs">
                      {JSON.stringify(c.value, null, 2)}
                    </pre>
                  </div>
                  {c.key === "marketplace" ? (
                    <ConfirmActionButton
                      label="Toggle matching"
                      onConfirm={async () => {
                        const value =
                          typeof c.value === "object" && c.value !== null
                            ? (c.value as Record<string, unknown>)
                            : {};
                        const enabled = value.matching_enabled !== false;
                        return upsertAppConfig(c.key, {
                          ...value,
                          matching_enabled: !enabled,
                        });
                      }}
                    />
                  ) : null}
                </div>
              </li>
            ))}
          </ul>
        )}
      </Panel>
    </div>
  );
}
