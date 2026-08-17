"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { signOutAdmin } from "@/lib/actions";
import type { AdminProfile } from "@/lib/auth";

const nav = [
  { href: "/", label: "Resumen" },
  { href: "/verification", label: "Verificación" },
  { href: "/users", label: "Usuarios" },
  { href: "/trips", label: "Viajes" },
  { href: "/disputes", label: "Disputas" },
  { href: "/config", label: "Config" },
];

export function AdminShell({
  profile,
  children,
}: {
  profile: AdminProfile;
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const name =
    profile.display_name || profile.full_name || profile.email || "Admin";

  return (
    <div className="min-h-screen bg-[var(--fg-bg)] text-[var(--fg-navy)]">
      <header className="border-b border-[var(--fg-border)] bg-white">
        <div className="mx-auto flex max-w-6xl items-center justify-between gap-4 px-4 py-4">
          <div>
            <p className="text-xs font-semibold tracking-[0.14em] text-[var(--fg-primary)] uppercase">
              FLETEGO
            </p>
            <h1 className="text-lg font-semibold">Admin</h1>
          </div>
          <div className="flex items-center gap-3 text-sm">
            <span className="hidden text-[var(--fg-muted)] sm:inline">
              {name} · {profile.platform_role}
            </span>
            <form action={signOutAdmin}>
              <button
                type="submit"
                className="rounded-lg border border-[var(--fg-border)] px-3 py-1.5 hover:bg-[var(--fg-bg)]"
              >
                Salir
              </button>
            </form>
          </div>
        </div>
        <nav className="mx-auto flex max-w-6xl gap-1 overflow-x-auto px-4 pb-3">
          {nav.map((item) => {
            const active =
              item.href === "/"
                ? pathname === "/"
                : pathname.startsWith(item.href);
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`rounded-lg px-3 py-1.5 text-sm whitespace-nowrap ${
                  active
                    ? "bg-[var(--fg-primary)] text-white"
                    : "text-[var(--fg-muted)] hover:bg-white hover:text-[var(--fg-navy)]"
                }`}
              >
                {item.label}
              </Link>
            );
          })}
        </nav>
      </header>
      <main className="mx-auto max-w-6xl px-4 py-6">{children}</main>
    </div>
  );
}
