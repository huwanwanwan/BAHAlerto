"use server";
import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { database, configured } from "@/lib/supabase";
import { requireWrite } from "@/lib/auth";
import { z } from "zod";
export type ActionState = { error?: string; success?: string };
function siteOrigin() {
  const origin = process.env.NEXT_PUBLIC_SITE_URL;
  return origin ? origin.replace(/\/$/, "") : null;
}
export async function signInWithGoogle(
  _: ActionState,
  _form: FormData,
): Promise<ActionState> {
  void _;
  void _form;
  if (!configured()) return { error: "Supabase is not configured." };
  const origin = siteOrigin();
  if (!origin) return { error: "Configure the trusted site URL first." };
  const db = await database();
  const { data, error } = await db.auth.signInWithOAuth({
    provider: "google",
    options: { redirectTo: `${origin}/auth/google/callback` },
  });
  if (error || !data.url)
    return { error: "Google sign-in could not start. Check the Supabase Google provider configuration." };
  redirect(data.url);
}
export async function linkGoogleAccount(
  _: ActionState,
  _form: FormData,
): Promise<ActionState> {
  void _;
  void _form;
  await requireWrite("account");
  const origin = siteOrigin();
  if (!origin) return { error: "Configure the trusted site URL first." };
  const db = await database();
  const { data, error } = await db.auth.linkIdentity({
    provider: "google",
    options: { redirectTo: `${origin}/auth/google/callback?intent=link` },
  });
  if (error)
    return { error: `Google account linking failed: ${error.message}` };
  if (!data.url)
    return { error: "Google account linking failed: Supabase did not return an authorization URL." };
  redirect(data.url);
}
export async function login(
  _: ActionState,
  form: FormData,
): Promise<ActionState> {
  const fields = z
    .object({ email: z.email(), password: z.string().min(1).max(256) })
    .safeParse(Object.fromEntries(form));
  if (!fields.success) return { error: "Enter a valid email and password." };
  if (!configured())
    return {
      error:
        "Supabase is not configured. Follow admin/README.md to connect the shared project.",
    };
  const db = await database();
  const { error } = await db.auth.signInWithPassword(fields.data);
  if (error)
    return {
      error: "Unable to sign in. Check your credentials or try again later.",
    };
  const {
    data: { user },
  } = await db.auth.getUser();
  const { data } = await db
    .from("admin_memberships")
    .select("active, permissions")
    .eq("user_id", user?.id ?? "")
    .single();
  const { data: profile } = await db
    .from("profiles")
    .select("status")
    .eq("id", user?.id ?? "")
    .single();
  if (!data?.active || profile?.status !== "active") {
    await db.auth.signOut();
    return { error: "This account does not have active administrator access." };
  }
  const { modules, permissions } = await import("@/lib/modules");
  const landing = modules.find((m) =>
    data.permissions.includes(permissions[m.slug]),
  );
  if (!landing) {
    await db.auth.signOut();
    return { error: "No administrator module permissions are assigned." };
  }
  redirect("/admin/" + landing.slug);
}
export async function logout() {
  if (configured()) {
    const db = await database();
    await db.auth.signOut();
  }
  redirect("/login");
}
export async function forgot(
  _: ActionState,
  form: FormData,
): Promise<ActionState> {
  const email = z.email().safeParse(form.get("email"));
  if (!email.success) return { error: "Enter a valid email address." };
  if (!configured()) return { error: "Supabase is not configured." };
  const db = await database();
  const origin = process.env.NEXT_PUBLIC_SITE_URL;
  if (!origin) return { error: "Configure the trusted site URL first." };
  const { error } = await db.auth.resetPasswordForEmail(email.data, {
    redirectTo: origin + "/auth/callback",
  });
  return error
    ? { error: "Recovery email could not be sent. Try later." }
    : { success: "If the account exists, a recovery link will be emailed." };
}
export async function changePassword(
  _: ActionState,
  form: FormData,
): Promise<ActionState> {
  await requireWrite("account");
  const result = z.string().min(12).max(128).safeParse(form.get("password"));
  if (!result.success)
    return { error: "Use a password between 12 and 128 characters." };
  const db = await database();
  const { error } = await db.auth.updateUser({ password: result.data });
  return error
    ? { error: "Password update failed. Request a new recovery link." }
    : { success: "Password updated." };
}
export async function review(
  _: ActionState,
  form: FormData,
): Promise<ActionState> {
  await requireWrite("reports");
  const parsed = z
    .object({
      id: z.uuid(),
      decision: z.enum(["verified", "rejected", "clarification"]),
      reason: z.string().trim().min(5).max(2000),
    })
    .safeParse(Object.fromEntries(form));
  if (!parsed.success)
    return {
      error: "Select a decision and enter a reason of at least 5 characters.",
    };
  const db = await database();
  const { error } = await db.rpc("review_flood_report", {
    report_id: parsed.data.id,
    decision: parsed.data.decision,
    reason: parsed.data.reason,
  });
  if (error)
    return {
      error:
        "Review failed. The report may already have been reviewed or your permission changed.",
    };
  revalidatePath("/admin", "layout");
  return {
    success:
      "Review saved and audited. Observations must be published separately.",
  };
}
export async function saveRecord(
  _: ActionState,
  form: FormData,
): Promise<ActionState> {
  const { saveSchema, capability, centerInputSchema } = await import("@/lib/validation");
  const input = Object.fromEntries(form);
  if (input.kind === "observation") {
    const observation = saveSchema.safeParse(input);
    if (!observation.success) return { error: observation.error.issues.map(issue => issue.message).join(" ") };
    const observationAdmin = await requireWrite("observations");
    const { catalogueRoad } = await import("@/lib/marilao-roads");
    const road = catalogueRoad(String(input.road_id));
    if (road) {
      const db = await database();
      const existing = await db.from("road_locations").select("id").eq("id", road.id).maybeSingle();
      if (existing.error) return { error: "The selected road could not be checked. Please try again." };
      if (!existing.data) {
        if (!observationAdmin.permissions.includes("roads")) return { error: "Road management permission is required to add this mapped road." };
        const { error } = await db.rpc("admin_save_record", {kind:"road",payload:{
          id:road.id,name:road.name,locality:road.locality,
          latitude:road.latitude,longitude:road.longitude,published:"true",
        }});
        if (error) return { error: "The selected mapped road could not be added. Please try again." };
      }
    }
  }
  if (input.kind === "center") {
    const center = centerInputSchema.safeParse(input);
    if (!center.success) return { error: "Complete the center's name, address, contact and availability details." };
    await requireWrite("emergency");
    const db = await database();
    let coordinates: { latitude: number; longitude: number } | undefined;
    if (center.data.id) {
      const { data: existing, error } = await db.from("evacuation_centers")
        .select("name,address,latitude,longitude").eq("id", center.data.id).single();
      if (error || !existing) return { error: "The center could not be loaded. Refresh and try again." };
      if (existing.name === center.data.name && existing.address === center.data.address) {
        coordinates = { latitude: existing.latitude, longitude: existing.longitude };
      }
    }
    if (!coordinates) {
      try {
        const { geocodeCenter } = await import("@/lib/geocoding");
        coordinates = await geocodeCenter(center.data.name, center.data.address);
      } catch (error) {
        return { error: error instanceof Error ? error.message : "Location lookup failed. Try again." };
      }
    }
    input.latitude = String(coordinates.latitude);
    input.longitude = String(coordinates.longitude);
  }
  const parsed = saveSchema.safeParse(input);
  if (!parsed.success)
    return { error: parsed.error.issues.map((i) => i.message).join(" ") };
  await requireWrite(capability[parsed.data.kind]);
  const db = await database();
  const { error } = await db.rpc("admin_save_record", {
    kind: parsed.data.kind,
    payload: parsed.data,
  });
  if (error)
    return {
      error:
        "Save failed. Check required fields, timestamps, constraints and permissions.",
    };
  revalidatePath("/admin", "layout");
  return { success: "Record saved. Audit entry recorded." };
}

export async function observationChoices() {
  await requireWrite("observations");
  const db = await database();
  const [roads, reports] = await Promise.all([
    (async () => {
      const rows: {id:string;name:string;locality:string|null}[] = [];
      for (let start = 0; ; start += 500) {
        const page = await db.from("road_locations").select("id,name,locality").order("id").range(start,start+499);
        if (page.error) throw new Error("Roads could not be loaded. Close the form and try again.");
        rows.push(...(page.data ?? []));
        if ((page.data?.length ?? 0) < 500) return rows;
      }
    })(),
    db.from("flood_reports").select("id,road_id,depth_cm,observed_at,road_locations(name)").eq("status", "verified").order("observed_at", { ascending: false }).limit(100),
  ]);
  const { marilaoRoadChoices } = await import("@/lib/marilao-roads");
  return {
    roads: marilaoRoadChoices(roads),
    reports: (reports.data ?? []).map(report => ({ value: report.id as string, roadId: report.road_id as string, label: `${(report.road_locations as unknown as {name: string} | null)?.name ?? "Reported road"} · ${report.depth_cm} cm · ${new Date(report.observed_at).toLocaleString("en-PH", {timeZone:"Asia/Manila"})}` })),
  };
}

export async function deleteOrArchiveRecord(
  kind: string,
  row: Record<string, unknown>,
  archive = true,
): Promise<ActionState> {
  const { capability } = await import("@/lib/validation");
  await requireWrite(capability[kind]);
  const db = await database();

  let payload: Record<string, unknown>;

  if (kind === "road") {
    payload = {
      ...row,
      id: String(row.id),
      published: !archive,
    };
  } else if (kind === "alert") {
    payload = {
      ...row,
      id: String(row.id),
      status: archive ? "expired" : "published",
    };
  } else if (kind === "user") {
    payload = {
      ...row,
      id: String(row.id),
      status: archive ? "suspended" : "active",
      reason: archive
        ? "Account suspended by administrator"
        : "Account reactivated by administrator",
    };
  } else {
    // observation, contact, center
    payload = {
      ...row,
      id: String(row.id),
      archived: archive,
      published: archive ? false : Boolean(row.published),
    };
  }

  const { error } = await db.rpc("admin_save_record", {
    kind,
    payload,
  });

  if (error) {
    return { error: "Action failed: " + error.message };
  }

  revalidatePath("/admin", "layout");
  return {
    success: archive
      ? "Record archived and removed from public view."
      : "Record restored.",
  };
}
