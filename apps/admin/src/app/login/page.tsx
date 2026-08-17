import { LoginForm } from "@/components/login-form";

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string }>;
}) {
  const params = await searchParams;
  const message =
    params.error === "forbidden"
      ? "Tu cuenta no tiene rol de administrador. Pide a un super_admin que te promueva (profiles.platform_role)."
      : params.error === "profile"
        ? "No encontramos tu perfil."
        : null;

  return (
    <div className="flex min-h-screen items-center justify-center bg-[var(--fg-bg)] px-4">
      <div className="w-full max-w-md rounded-2xl border border-[var(--fg-border)] bg-white p-6 shadow-sm">
        <p className="text-xs font-semibold tracking-[0.14em] text-[var(--fg-primary)] uppercase">
          FLETEGO
        </p>
        <h1 className="mt-1 text-2xl font-semibold text-[var(--fg-navy)]">
          Admin
        </h1>
        <p className="mt-1 mb-6 text-sm text-[var(--fg-muted)]">
          Acceso solo para platform admin / super_admin.
        </p>
        <LoginForm initialError={message} />
      </div>
    </div>
  );
}
