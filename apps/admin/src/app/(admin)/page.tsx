import Link from "next/link";
import { PageHeader, Panel, StatusBadge } from "@/components/ui";
import { createServiceClient } from "@/lib/supabase/admin";

export default async function DashboardPage() {
  const admin = createServiceClient();

  const [
    pendingCompanies,
    pendingDrivers,
    pendingVehicles,
    openDisputes,
    activeTrips,
    users,
  ] = await Promise.all([
    admin
      .from("companies")
      .select("id", { count: "exact", head: true })
      .eq("verification_status", "pending")
      .is("deleted_at", null),
    admin
      .from("driver_profiles")
      .select("id", { count: "exact", head: true })
      .eq("verification_status", "pending")
      .is("deleted_at", null),
    admin
      .from("vehicles")
      .select("id", { count: "exact", head: true })
      .eq("verification_status", "pending")
      .is("deleted_at", null),
    admin
      .from("disputes")
      .select("id", { count: "exact", head: true })
      .in("status", ["open", "under_review"])
      .is("deleted_at", null),
    admin
      .from("trips")
      .select("id", { count: "exact", head: true })
      .not("status", "in", "(completed,cancelled,failed,delivered)")
      .is("deleted_at", null),
    admin
      .from("profiles")
      .select("id", { count: "exact", head: true })
      .is("deleted_at", null),
  ]);

  const cards = [
    {
      label: "Empresas pendientes",
      value: pendingCompanies.count ?? 0,
      href: "/verification",
    },
    {
      label: "Conductores pendientes",
      value: pendingDrivers.count ?? 0,
      href: "/verification",
    },
    {
      label: "Vehículos pendientes",
      value: pendingVehicles.count ?? 0,
      href: "/verification",
    },
    {
      label: "Disputas abiertas",
      value: openDisputes.count ?? 0,
      href: "/disputes",
    },
    {
      label: "Viajes no terminales",
      value: activeTrips.count ?? 0,
      href: "/trips",
    },
    {
      label: "Usuarios",
      value: users.count ?? 0,
      href: "/users",
    },
  ];

  return (
    <div>
      <PageHeader
        title="Resumen operativo"
        description="Cola de verificación, viajes y disputas."
      />
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {cards.map((card) => (
          <Link
            key={card.label}
            href={card.href}
            className="rounded-2xl border border-[var(--fg-border)] bg-white p-4 transition hover:border-[var(--fg-primary)]"
          >
            <p className="text-sm text-[var(--fg-muted)]">{card.label}</p>
            <p className="mt-2 text-3xl font-semibold tabular-nums">
              {card.value}
            </p>
          </Link>
        ))}
      </div>
      <div className="mt-6">
        <Panel title="Estado">
          <div className="flex flex-wrap gap-2">
            <StatusBadge label="Service role activo" tone="success" />
            <StatusBadge label="Solo platform admin" tone="primary" />
          </div>
          <p className="mt-3 text-sm text-[var(--fg-muted)]">
            Para promover un admin: actualiza{" "}
            <code className="rounded bg-[var(--fg-bg)] px-1">profiles.platform_role</code>{" "}
            a <code className="rounded bg-[var(--fg-bg)] px-1">admin</code> (o usa
            Usuarios si ya eres super_admin).
          </p>
        </Panel>
      </div>
    </div>
  );
}
