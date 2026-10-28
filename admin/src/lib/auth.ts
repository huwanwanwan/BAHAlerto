import "server-only";
import { redirect } from "next/navigation";
import { configured, database } from "./supabase";
export async function administrator(permission?: string) {
  if (!configured()) return null;
  const db = await database();
  const {
    data: { user },
  } = await db.auth.getUser();
  if (!user) redirect("/login");
  const { data, error } = await db
    .from("admin_memberships")
    .select("permissions,active")
    .eq("user_id", user.id)
    .single();
  const { data: profile } = await db
    .from("profiles")
    .select("status")
    .eq("id", user.id)
    .single();
  if (
    error ||
    !data?.active ||
    profile?.status !== "active" ||
    (permission && !data.permissions.includes(permission))
  )
    throw new Error(
      "Administrator permission required. Contact the system owner.",
    );
  return {
    id: user.id,
    email: user.email,
    permissions: data.permissions as string[],
  };
}
export async function requireWrite(permission: string) {
  const admin = await administrator(permission);
  if (!admin) throw new Error("Connect Supabase before making changes.");
  return admin;
}
