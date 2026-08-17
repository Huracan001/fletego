import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { createServiceClient } from "@/lib/supabase/admin";

export type AdminProfile = {
  id: string;
  email: string | null;
  full_name: string | null;
  display_name: string | null;
  platform_role: "user" | "admin" | "super_admin";
};

export async function requireAdmin(): Promise<AdminProfile> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  const admin = createServiceClient();
  const { data: profile, error } = await admin
    .from("profiles")
    .select("id, email, full_name, display_name, platform_role")
    .eq("id", user.id)
    .is("deleted_at", null)
    .maybeSingle();

  if (error || !profile) {
    redirect("/login?error=profile");
  }

  if (
    profile.platform_role !== "admin" &&
    profile.platform_role !== "super_admin"
  ) {
    redirect("/login?error=forbidden");
  }

  return profile as AdminProfile;
}

export async function writeAudit(input: {
  actorId: string;
  action: string;
  entityType: string;
  entityId?: string | null;
  meta?: Record<string, unknown>;
}) {
  const admin = createServiceClient();
  await admin.from("audit_logs").insert({
    actor_id: input.actorId,
    action: input.action,
    entity_type: input.entityType,
    entity_id: input.entityId ?? null,
    meta: input.meta ?? {},
  });
}
