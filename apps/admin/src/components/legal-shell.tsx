import Link from "next/link";

export function LegalShell({
  title,
  updated,
  children,
}: {
  title: string;
  updated: string;
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-[var(--fg-bg)] text-[var(--fg-navy)]">
      <header className="border-b border-[var(--fg-border)] bg-white">
        <div className="mx-auto flex max-w-3xl items-center justify-between gap-4 px-4 py-4">
          <div>
            <p className="text-xs font-semibold tracking-[0.14em] text-[var(--fg-primary)] uppercase">
              FLETEGO
            </p>
            <p className="text-sm text-[var(--fg-muted)]">by Pick&Truck</p>
          </div>
          <nav className="flex gap-3 text-sm">
            <Link href="/privacy" className="hover:text-[var(--fg-primary)]">
              Privacidad
            </Link>
            <Link href="/terms" className="hover:text-[var(--fg-primary)]">
              Términos
            </Link>
            <Link href="/login" className="hover:text-[var(--fg-primary)]">
              Admin
            </Link>
          </nav>
        </div>
      </header>
      <main className="mx-auto max-w-3xl px-4 py-10">
        <h1 className="text-3xl font-semibold tracking-tight">{title}</h1>
        <p className="mt-2 text-sm text-[var(--fg-muted)]">
          Última actualización: {updated}
        </p>
        <article className="prose-legal mt-8 space-y-6 text-[15px] leading-relaxed text-[var(--fg-navy)]">
          {children}
        </article>
        <p className="mt-10 rounded-xl border border-[var(--fg-border)] bg-white p-4 text-sm text-[var(--fg-muted)]">
          Este documento es una plantilla operativa para el MVP de FLETEGO.
          Recomendamos revisión legal antes de un lanzamiento comercial amplio.
        </p>
      </main>
      <footer className="border-t border-[var(--fg-border)] py-6 text-center text-sm text-[var(--fg-muted)]">
        © {new Date().getFullYear()} FLETEGO by Pick&Truck · Bolivia
      </footer>
    </div>
  );
}

export function LegalSection({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section>
      <h2 className="mb-2 text-lg font-semibold">{title}</h2>
      <div className="space-y-3 text-[var(--fg-muted)] [&_ul]:list-disc [&_ul]:space-y-1 [&_ul]:pl-5 [&_strong]:text-[var(--fg-navy)]">
        {children}
      </div>
    </section>
  );
}
