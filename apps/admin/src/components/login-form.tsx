"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { useRouter } from "next/navigation";

export function LoginForm({ initialError }: { initialError?: string | null }) {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(initialError ?? null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    const supabase = createClient();
    const { error: signError } = await supabase.auth.signInWithPassword({
      email: email.trim(),
      password,
    });
    setLoading(false);
    if (signError) {
      setError(signError.message);
      return;
    }
    router.replace("/");
    router.refresh();
  }

  return (
    <form onSubmit={onSubmit} className="space-y-4">
      <div>
        <label className="mb-1 block text-sm font-medium">Correo</label>
        <input
          type="email"
          required
          autoComplete="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="w-full rounded-xl border border-[var(--fg-border)] bg-white px-3 py-2 outline-none focus:border-[var(--fg-primary)]"
        />
      </div>
      <div>
        <label className="mb-1 block text-sm font-medium">Contraseña</label>
        <input
          type="password"
          required
          autoComplete="current-password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="w-full rounded-xl border border-[var(--fg-border)] bg-white px-3 py-2 outline-none focus:border-[var(--fg-primary)]"
        />
      </div>
      {error ? (
        <p className="rounded-lg bg-[#E5484D1F] px-3 py-2 text-sm text-[#C2292E]">
          {error}
        </p>
      ) : null}
      <button
        type="submit"
        disabled={loading}
        className="w-full rounded-xl bg-[var(--fg-primary)] px-4 py-2.5 font-medium text-white disabled:opacity-60"
      >
        {loading ? "Entrando…" : "Entrar"}
      </button>
      <p className="text-center text-xs text-[var(--fg-muted)]">
        <a href="/privacy" className="underline hover:text-[var(--fg-navy)]">
          Privacidad
        </a>
        {" · "}
        <a href="/terms" className="underline hover:text-[var(--fg-navy)]">
          Términos
        </a>
      </p>
    </form>
  );
}
