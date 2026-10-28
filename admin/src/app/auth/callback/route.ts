import { NextResponse, type NextRequest } from "next/server";
import { database } from "@/lib/supabase";
export async function GET(request: NextRequest) {
  const code = request.nextUrl.searchParams.get("code");
  if (code) {
    const db = await database();
    const { error } = await db.auth.exchangeCodeForSession(code);
    if (!error)
      return NextResponse.redirect(new URL("/admin/settings", request.url));
  }
  return NextResponse.redirect(new URL("/login", request.url));
}
