"use server";
import { administrator } from "@/lib/auth";
import { configured, database } from "@/lib/supabase";

export async function loadNotifications() {
  if (!configured()) return { items: [], unread: 0, registrations: 0, error: "Connect Supabase to receive notifications." };
  const admin = await administrator();
  if (!admin) throw new Error("Sign in as an administrator.");
  const db = await database();
  const [recent, unread, registrations] = await Promise.all([
    db.from("admin_notifications").select("id,kind,record_id,title,created_at,read_at")
      .eq("recipient_id", admin.id).order("created_at", { ascending: false }).limit(20),
    db.from("admin_notifications").select("id", { count: "exact", head: true })
      .eq("recipient_id", admin.id).is("read_at", null),
    db.from("admin_notifications").select("id", { count: "exact", head: true })
      .eq("recipient_id", admin.id).eq("kind", "account_registered").is("read_at", null),
  ]);
  if (recent.error || unread.error || registrations.error) return { items: [], unread: 0, registrations: 0, error: "Notifications unavailable. Check migration 005 and database permissions." };
  return {
    items: (recent.data ?? []).map(item => ({ ...item,
      href: item.kind === "report_submitted"
        ? (admin.permissions.includes("reports") ? "/admin/reports" : "/admin/dashboard")
        : (admin.permissions.includes("users") ? `/admin/users/${item.record_id}` : "/admin/dashboard"),
    })),
    unread: unread.count ?? 0, registrations: registrations.count ?? 0, error: null,
  };
}

export async function markNotificationsRead(ids: string[]) {
  const admin = await administrator();
  if (!admin || !Array.isArray(ids) || ids.length > 20 || ids.some(id => typeof id !== "string" || !/^[a-f0-9-]{36}$/i.test(id))) {
    throw new Error("Invalid notification request.");
  }
  if (!ids.length) return;
  const db = await database();
  const { error } = await db.from("admin_notifications").update({ read_at: new Date().toISOString() })
    .eq("recipient_id", admin.id).in("id", ids).is("read_at", null);
  if (error) throw new Error("Could not mark notifications as read.");
}
