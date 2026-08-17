export function StatusBadge({
  label,
  tone = "neutral",
}: {
  label: string;
  tone?: "primary" | "success" | "warning" | "danger" | "neutral";
}) {
  const styles = {
    primary: "bg-[#1769FF1F] text-[#1769FF]",
    success: "bg-[#20C77A1F] text-[#0F8A52]",
    warning: "bg-[#F5A5241F] text-[#9A6700]",
    danger: "bg-[#E5484D1F] text-[#C2292E]",
    neutral: "bg-[#E8EEF6] text-[#5B6B7C]",
  } as const;

  return (
    <span
      className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${styles[tone]}`}
    >
      {label}
    </span>
  );
}

export function verificationTone(
  status: string | null | undefined,
): "primary" | "success" | "warning" | "danger" | "neutral" {
  switch (status) {
    case "approved":
      return "success";
    case "pending":
      return "warning";
    case "rejected":
      return "danger";
    case "expired":
      return "neutral";
    default:
      return "neutral";
  }
}

export function PageHeader({
  title,
  description,
}: {
  title: string;
  description?: string;
}) {
  return (
    <div className="mb-6">
      <h2 className="text-2xl font-semibold tracking-tight">{title}</h2>
      {description ? (
        <p className="mt-1 text-sm text-[var(--fg-muted)]">{description}</p>
      ) : null}
    </div>
  );
}

export function EmptyState({
  title,
  message,
}: {
  title: string;
  message: string;
}) {
  return (
    <div className="rounded-2xl border border-dashed border-[var(--fg-border)] bg-white px-4 py-10 text-center">
      <p className="font-medium">{title}</p>
      <p className="mt-1 text-sm text-[var(--fg-muted)]">{message}</p>
    </div>
  );
}

export function Panel({
  title,
  children,
  action,
}: {
  title: string;
  children: React.ReactNode;
  action?: React.ReactNode;
}) {
  return (
    <section className="rounded-2xl border border-[var(--fg-border)] bg-white">
      <div className="flex items-center justify-between gap-3 border-b border-[var(--fg-border)] px-4 py-3">
        <h3 className="font-medium">{title}</h3>
        {action}
      </div>
      <div className="p-4">{children}</div>
    </section>
  );
}
