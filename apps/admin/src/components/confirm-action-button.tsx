"use client";

import { useState, useTransition } from "react";

export function ConfirmActionButton({
  label,
  confirmLabel,
  tone = "primary",
  onConfirm,
  askReason = false,
}: {
  label: string;
  confirmLabel?: string;
  tone?: "primary" | "danger" | "neutral";
  askReason?: boolean;
  onConfirm: (reason?: string) => Promise<{ ok: boolean; error?: string }>;
}) {
  const [pending, start] = useTransition();
  const [error, setError] = useState<string | null>(null);

  const className =
    tone === "danger"
      ? "rounded-lg bg-[#E5484D] px-2.5 py-1 text-xs font-medium text-white disabled:opacity-60"
      : tone === "neutral"
        ? "rounded-lg border border-[var(--fg-border)] px-2.5 py-1 text-xs disabled:opacity-60"
        : "rounded-lg bg-[var(--fg-primary)] px-2.5 py-1 text-xs font-medium text-white disabled:opacity-60";

  return (
    <div className="flex flex-col items-end gap-1">
      <button
        type="button"
        disabled={pending}
        className={className}
        onClick={() => {
          const reason = askReason
            ? window.prompt("Motivo del rechazo:")
            : undefined;
          if (askReason && (reason == null || reason.trim() === "")) return;
          if (
            confirmLabel &&
            !window.confirm(confirmLabel)
          ) {
            return;
          }
          start(async () => {
            const result = await onConfirm(reason?.trim());
            if (!result.ok) setError(result.error ?? "Error");
            else setError(null);
          });
        }}
      >
        {pending ? "…" : label}
      </button>
      {error ? <span className="text-[10px] text-[#C2292E]">{error}</span> : null}
    </div>
  );
}
