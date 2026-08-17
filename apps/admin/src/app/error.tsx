"use client";

import { useEffect } from "react";
import Link from "next/link";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <div className="mx-auto flex min-h-[50vh] max-w-lg flex-col justify-center px-4 py-10">
      <p className="text-xs font-semibold tracking-[0.14em] text-[var(--fg-primary)] uppercase">
        FLETEGO
      </p>
      <h1 className="mt-1 text-2xl font-semibold">Algo falló</h1>
      <p className="mt-2 text-sm text-[var(--fg-muted)]">{error.message}</p>
      <div className="mt-4 flex gap-2">
        <button
          type="button"
          onClick={reset}
          className="rounded-xl bg-[var(--fg-primary)] px-4 py-2 text-sm font-medium text-white"
        >
          Reintentar
        </button>
        <Link
          href="/login"
          className="rounded-xl border border-[var(--fg-border)] px-4 py-2 text-sm"
        >
          Login
        </Link>
      </div>
    </div>
  );
}
