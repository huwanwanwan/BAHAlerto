import { NextResponse, type NextRequest } from "next/server";
import { database } from "@/lib/supabase";
import { modules, permissions } from "@/lib/modules";

export async function GET(request: NextRequest) {
  const intent = request.nextUrl.searchParams.get("intent");
  const linking = intent === "link";
  const settingsUrl = new URL("/admin/settings", request.url);
  const loginUrl = new URL("/login?google=error", request.url);
  if (request.nextUrl.searchParams.has("error")) {
    return NextResponse.redirect(linking ? new URL("/admin/settings?google=error", request.url) : loginUrl);
  }

  const code = request.nextUrl.searchParams.get("code");
  if (!code) return NextResponse.redirect(linking ? new URL("/admin/settings?google=error", request.url) : loginUrl);

  const db = await database();
  const { error } = await db.auth.exchangeCodeForSession(code);
  if (error) return NextResponse.redirect(linking ? new URL("/admin/settings?google=error", request.url) : loginUrl);

  const { data: { user } } = await db.auth.getUser();
  if (!user) return NextResponse.redirect(linking ? new URL("/admin/settings?google=error", request.url) : loginUrl);

  const [membershipResult, profileResult] = await Promise.all([
    db.from("admin_memberships").select("active,permissions").eq("user_id", user.id).single(),
    db.from("profiles").select("status").eq("id", user.id).single(),
  ]);
  const membership = membershipResult.data;
  const profile = profileResult.data;
  if (
    membershipResult.error ||
    profileResult.error ||
    !membership?.active ||
    profile?.status !== "active" ||
    (linking && !membership.permissions.includes("account"))
  ) {
    if (!linking) await db.auth.signOut();
    return NextResponse.redirect(linking ? new URL("/admin/settings?google=error", request.url) : new URL("/login?google=unauthorized", request.url));
  }

  if (linking) {
    const linked = user.identities?.some(identity => identity.provider === "google");
    settingsUrl.searchParams.set("google", linked ? "linked" : "error");
    return NextResponse.redirect(settingsUrl);
  }

  const landing = modules.find(module =>
    membership.permissions.includes(permissions[module.slug]),
  );
  if (!landing) {
    await db.auth.signOut();
    return NextResponse.redirect(new URL("/login?google=unauthorized", request.url));
  }

  return NextResponse.redirect(new URL(`/admin/${landing.slug}`, request.url));
}
