import { ConfirmActionButton } from "@/components/confirm-action-button";
import {
  EmptyState,
  PageHeader,
  Panel,
  StatusBadge,
} from "@/components/ui";
import { setUserPlatformRole, softDeleteUser } from "@/lib/actions";
import { requireAdmin } from "@/lib/auth";
import { createServiceClient } from "@/lib/supabase/admin";

export default async function UsersPage() {
  const me = await requireAdmin();
  const admin = createServiceClient();
  const { data } = await admin
    .from("profiles")
    .select(
      "id, email, full_name, display_name, platform_role, is_driver, is_customer, onboarding_intent, created_at",
    )
    .is("deleted_at", null)
    .order("created_at", { ascending: false })
    .limit(100);

  return (
    <div>
      <PageHeader
        title="Usuarios"
        description="Perfiles de la plataforma. Solo super_admin puede otorgar super_admin."
      />
      <Panel title={`${data?.length ?? 0} perfiles`}>
        {!data?.length ? (
          <EmptyState title="Sin usuarios" message="No hay perfiles." />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[720px] text-left text-sm">
              <thead className="text-[var(--fg-muted)]">
                <tr className="border-b border-[var(--fg-border)]">
                  <th className="py-2 pr-3 font-medium">Usuario</th>
                  <th className="py-2 pr-3 font-medium">Rol</th>
                  <th className="py-2 pr-3 font-medium">Flags</th>
                  <th className="py-2 font-medium">Acciones</th>
                </tr>
              </thead>
              <tbody>
                {data.map((row) => (
                  <tr
                    key={row.id}
                    className="border-b border-[var(--fg-border)] last:border-0"
                  >
                    <td className="py-3 pr-3">
                      <p className="font-medium">
                        {row.display_name || row.full_name || "—"}
                      </p>
                      <p className="text-[var(--fg-muted)]">
                        {row.email || row.id}
                      </p>
                    </td>
                    <td className="py-3 pr-3">
                      <StatusBadge
                        label={row.platform_role}
                        tone={
                          row.platform_role === "user" ? "neutral" : "primary"
                        }
                      />
                    </td>
                    <td className="py-3 pr-3 text-[var(--fg-muted)]">
                      {[
                        row.is_driver ? "driver" : null,
                        row.is_customer ? "customer" : null,
                        row.onboarding_intent,
                      ]
                        .filter(Boolean)
                        .join(" · ") || "—"}
                    </td>
                    <td className="py-3">
                      <div className="flex flex-wrap gap-2">
                        {row.platform_role !== "admin" ? (
                          <ConfirmActionButton
                            label="Hacer admin"
                            confirmLabel="¿Promover a admin?"
                            onConfirm={() =>
                              setUserPlatformRole(row.id, "admin")
                            }
                          />
                        ) : null}
                        {me.platform_role === "super_admin" &&
                        row.platform_role !== "super_admin" ? (
                          <ConfirmActionButton
                            label="Super admin"
                            confirmLabel="¿Promover a super_admin?"
                            onConfirm={() =>
                              setUserPlatformRole(row.id, "super_admin")
                            }
                          />
                        ) : null}
                        {row.platform_role !== "user" ? (
                          <ConfirmActionButton
                            label="Quitar admin"
                            tone="neutral"
                            confirmLabel="¿Devolver a user?"
                            onConfirm={() =>
                              setUserPlatformRole(row.id, "user")
                            }
                          />
                        ) : null}
                        {row.id !== me.id ? (
                          <ConfirmActionButton
                            label="Desactivar"
                            tone="danger"
                            confirmLabel="¿Soft-delete este usuario?"
                            onConfirm={() => softDeleteUser(row.id)}
                          />
                        ) : null}
                      </div>
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
