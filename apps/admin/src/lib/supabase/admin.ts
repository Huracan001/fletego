import { createClient } from "@supabase/supabase-js";
import { getAdminEnv } from "@/lib/env";

/** Service-role client — server only. Bypass RLS after admin gate. */
export function createServiceClient() {
  const env = getAdminEnv();
  return createClient(env.url, env.serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
