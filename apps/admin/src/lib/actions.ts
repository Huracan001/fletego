"use server";

import { revalidatePath } from "next/cache";
import { requireAdmin, writeAudit } from "@/lib/auth";
import { createServiceClient } from "@/lib/supabase/admin";

type VerificationStatus = "pending" | "approved" | "rejected" | "expired";

async function setEntityVerification(input: {
  table: "companies" | "driver_profiles" | "vehicles";
  id: string;
  status: VerificationStatus;
  rejectionReason?: string | null;
  path: string;
}) {
  const profile = await requireAdmin();
  const admin = createServiceClient();
  const { error } = await admin
    .from(input.table)
    .update({
      verification_status: input.status,
      reviewed_by: profile.id,
      reviewed_at: new Date().toISOString(),
      rejection_reason:
        input.status === "rejected" ? (input.rejectionReason ?? null) : null,
    })
    .eq("id", input.id);

  if (error) {
    return { ok: false as const, error: error.message };
  }

  await writeAudit({
    actorId: profile.id,
    action: `verification.${input.status}`,
    entityType: input.table,
    entityId: input.id,
    meta: { rejectionReason: input.rejectionReason ?? null },
  });

  revalidatePath(input.path);
  revalidatePath("/");
  return { ok: true as const };
}

export async function approveCompany(id: string) {
  return setEntityVerification({
    table: "companies",
    id,
    status: "approved",
    path: "/verification",
  });
}

export async function rejectCompany(id: string, reason: string) {
  return setEntityVerification({
    table: "companies",
    id,
    status: "rejected",
    rejectionReason: reason,
    path: "/verification",
  });
}

export async function approveDriver(id: string) {
  return setEntityVerification({
    table: "driver_profiles",
    id,
    status: "approved",
    path: "/verification",
  });
}

export async function rejectDriver(id: string, reason: string) {
  return setEntityVerification({
    table: "driver_profiles",
    id,
    status: "rejected",
    rejectionReason: reason,
    path: "/verification",
  });
}

export async function approveVehicle(id: string) {
  return setEntityVerification({
    table: "vehicles",
    id,
    status: "approved",
    path: "/verification",
  });
}

export async function rejectVehicle(id: string, reason: string) {
  return setEntityVerification({
    table: "vehicles",
    id,
    status: "rejected",
    rejectionReason: reason,
    path: "/verification",
  });
}

export async function setDocumentStatus(input: {
  table: "driver_documents" | "vehicle_documents";
  id: string;
  status: VerificationStatus;
  rejectionReason?: string | null;
}) {
  const profile = await requireAdmin();
  const admin = createServiceClient();
  const { error } = await admin
    .from(input.table)
    .update({
      verification_status: input.status,
      reviewed_by: profile.id,
      reviewed_at: new Date().toISOString(),
      rejection_reason:
        input.status === "rejected" ? (input.rejectionReason ?? null) : null,
    })
    .eq("id", input.id);

  if (error) return { ok: false as const, error: error.message };

  await writeAudit({
    actorId: profile.id,
    action: `document.${input.status}`,
    entityType: input.table,
    entityId: input.id,
  });

  revalidatePath("/verification");
  return { ok: true as const };
}

export async function setUserPlatformRole(
  userId: string,
  role: "user" | "admin" | "super_admin",
) {
  const profile = await requireAdmin();
  if (profile.platform_role !== "super_admin" && role === "super_admin") {
    return {
      ok: false as const,
      error: "Solo un super_admin puede otorgar super_admin.",
    };
  }

  const admin = createServiceClient();
  const { data: target } = await admin
    .from("profiles")
    .select("platform_role")
    .eq("id", userId)
    .maybeSingle();

  if (
    target?.platform_role === "super_admin" &&
    profile.platform_role !== "super_admin"
  ) {
    return {
      ok: false as const,
      error: "Solo un super_admin puede modificar a otro super_admin.",
    };
  }

  const { error } = await admin
    .from("profiles")
    .update({ platform_role: role })
    .eq("id", userId);

  if (error) return { ok: false as const, error: error.message };

  await writeAudit({
    actorId: profile.id,
    action: "user.platform_role",
    entityType: "profiles",
    entityId: userId,
    meta: { role },
  });

  revalidatePath("/users");
  return { ok: true as const };
}

export async function softDeleteUser(userId: string) {
  const profile = await requireAdmin();
  const admin = createServiceClient();
  const { error } = await admin
    .from("profiles")
    .update({ deleted_at: new Date().toISOString() })
    .eq("id", userId);

  if (error) return { ok: false as const, error: error.message };

  await writeAudit({
    actorId: profile.id,
    action: "user.soft_delete",
    entityType: "profiles",
    entityId: userId,
  });

  revalidatePath("/users");
  return { ok: true as const };
}

export async function resolveDispute(input: {
  disputeId: string;
  status: "resolved" | "dismissed";
  resolution: string;
  tripId: string;
  closeTripAs?: "completed" | "cancelled" | null;
}) {
  const profile = await requireAdmin();
  const admin = createServiceClient();

  const { error } = await admin
    .from("disputes")
    .update({
      status: input.status,
      resolution: input.resolution,
      resolved_by: profile.id,
      resolved_at: new Date().toISOString(),
    })
    .eq("id", input.disputeId);

  if (error) return { ok: false as const, error: error.message };

  if (input.closeTripAs) {
    const { data: trip } = await admin
      .from("trips")
      .select("id, status")
      .eq("id", input.tripId)
      .maybeSingle();

    if (trip) {
      await admin
        .from("trips")
        .update({
          status: input.closeTripAs,
          completed_at: new Date().toISOString(),
          cancel_reason:
            input.closeTripAs === "cancelled"
              ? `Dispute ${input.status}: ${input.resolution}`
              : null,
        })
        .eq("id", input.tripId);

      await admin.from("trip_status_history").insert({
        trip_id: input.tripId,
        from_status: trip.status,
        to_status: input.closeTripAs,
        changed_by: profile.id,
        note: `Admin dispute ${input.status}: ${input.resolution}`,
      });
    }
  }

  await writeAudit({
    actorId: profile.id,
    action: `dispute.${input.status}`,
    entityType: "disputes",
    entityId: input.disputeId,
    meta: { closeTripAs: input.closeTripAs ?? null },
  });

  revalidatePath("/disputes");
  revalidatePath("/trips");
  return { ok: true as const };
}

export async function setVehicleTypeActive(id: string, isActive: boolean) {
  const profile = await requireAdmin();
  const admin = createServiceClient();
  const { error } = await admin
    .from("vehicle_types")
    .update({ is_active: isActive })
    .eq("id", id);

  if (error) return { ok: false as const, error: error.message };

  await writeAudit({
    actorId: profile.id,
    action: "config.vehicle_type",
    entityType: "vehicle_types",
    entityId: id,
    meta: { isActive },
  });

  revalidatePath("/config");
  return { ok: true as const };
}

export async function upsertAppConfig(
  key: string,
  value: Record<string, unknown>,
  description?: string,
) {
  const profile = await requireAdmin();
  const admin = createServiceClient();
  const { error } = await admin.from("app_config").upsert({
    key,
    value,
    description: description ?? null,
    updated_at: new Date().toISOString(),
    updated_by: profile.id,
  });

  if (error) return { ok: false as const, error: error.message };

  await writeAudit({
    actorId: profile.id,
    action: "config.upsert",
    entityType: "app_config",
    entityId: null,
    meta: { key, value },
  });

  revalidatePath("/config");
  return { ok: true as const };
}

export async function signOutAdmin() {
  const { createClient } = await import("@/lib/supabase/server");
  const { redirect } = await import("next/navigation");
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/login");
}
