import { notFound } from "next/navigation";
import Link from "next/link";
import { administrator } from "@/lib/auth";
import { database, configured } from "@/lib/supabase";
import { RecordsTable } from "@/components/records-table";
import { RecordForm } from "@/components/record-form";
export default async function UserDetails({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  await administrator("users");
  if (!configured()) notFound();
  const { id } = await params;
  if (!/^[a-f0-9-]{36}$/i.test(id)) notFound();
  const db = await database();
  const { data: user } = await db
    .from("profiles")
    .select("id,full_name,phone,preferred_area,status,created_at,last_sign_in_at")
    .eq("id", id)
    .single();
  if (!user) notFound();
  const { data: reports, error } = await db
    .from("flood_reports")
    .select("id,road_id,depth_cm,status,created_at,road_locations(name)")
    .eq("owner_id", id)
    .order("created_at", { ascending: false })
    .limit(1000);
  return (
    <>
      <Link href="/admin/users">Back to users</Link>
      <div className="page-heading">
        <div>
          <h1>{user.full_name}</h1>
          <p>{user.id}</p>
        </div>
        <RecordForm kind="user" initial={user} />
      </div>
      <section className="panel">
        <h2>Account information</h2>
        <p>Status: {user.status}</p>
        <p>Preferred area: {user.preferred_area ?? "Not provided"}</p>
        <p>Phone: {user.phone ?? "Not provided"}</p>
        <p>Last sign-in: {user.last_sign_in_at ? new Date(user.last_sign_in_at).toLocaleString("en-PH", {timeZone: "Asia/Manila"}) : "No sign-in recorded"}</p>
        <p>
          Created:{" "}
          {new Date(user.created_at).toLocaleString("en-PH", {
            timeZone: "Asia/Manila",
          })}
        </p>
      </section>
      <section className="panel">
        <h2>Submitted report activity</h2>
        {error ? (
          <p role="alert">Report activity could not be loaded.</p>
        ) : (
          <RecordsTable
            rows={(reports ?? []).map((report) => ({
              ...report,
              road_name:
                (report.road_locations as unknown as { name?: string } | null)
                  ?.name ?? "Location unavailable",
            }))}
            columns={["road_name", "depth_cm", "status", "created_at"]}
          />
        )}
      </section>
    </>
  );
}
