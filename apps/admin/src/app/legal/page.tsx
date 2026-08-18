import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Legal · FLETEGO",
  description: "Términos y política de privacidad de FLETEGO by Pick&Truck.",
};

export default function LegalIndexPage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-[var(--fg-bg)] px-4">
      <div className="w-full max-w-md rounded-2xl border border-[var(--fg-border)] bg-white p-6">
        <p className="text-xs font-semibold tracking-[0.14em] text-[var(--fg-primary)] uppercase">
          FLETEGO
        </p>
        <h1 className="mt-1 text-2xl font-semibold">Documentos legales</h1>
        <p className="mt-2 text-sm text-[var(--fg-muted)]">
          Documentación pública requerida para tiendas y usuarios.
        </p>
        <ul className="mt-6 space-y-3">
          <li>
            <Link
              href="/privacy"
              className="block rounded-xl border border-[var(--fg-border)] px-4 py-3 hover:border-[var(--fg-primary)]"
            >
              Política de Privacidad
            </Link>
          </li>
          <li>
            <Link
              href="/terms"
              className="block rounded-xl border border-[var(--fg-border)] px-4 py-3 hover:border-[var(--fg-primary)]"
            >
              Términos de Uso
            </Link>
          </li>
        </ul>
      </div>
    </div>
  );
}
