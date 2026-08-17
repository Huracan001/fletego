export class AdminEnvError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "AdminEnvError";
  }
}

export type AdminEnv = {
  url: string;
  anonKey: string;
  serviceRoleKey: string;
};

export function getAdminEnv(): AdminEnv {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL?.trim() ?? "";
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY?.trim() ?? "";
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY?.trim() ?? "";

  if (!url || !anonKey) {
    throw new AdminEnvError(
      "Faltan NEXT_PUBLIC_SUPABASE_URL o NEXT_PUBLIC_SUPABASE_ANON_KEY en apps/admin/.env.local",
    );
  }
  if (!serviceRoleKey) {
    throw new AdminEnvError(
      "Falta SUPABASE_SERVICE_ROLE_KEY en apps/admin/.env.local (Settings → API → service_role)",
    );
  }

  return { url, anonKey, serviceRoleKey };
}

export function hasAdminEnv(): boolean {
  try {
    getAdminEnv();
    return true;
  } catch {
    return false;
  }
}
