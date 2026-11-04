import { notFound } from "next/navigation";
import Link from "next/link";
import { ArrowLeft, CalendarDays, ClipboardList, Clock3, MapPin, Phone, UserRound } from "lucide-react";
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
  const name = user.full_name?.trim() || "Unnamed user";
  const initials = name.split(/\s+/).slice(0, 2).map((part: string) => part[0]).join("").toUpperCase();
  const formatDate = (value: string) => new Date(value).toLocaleString("en-PH", {
    timeZone: "Asia/Manila", dateStyle: "medium", timeStyle: "short",
  });
  return (
    <div className="user-detail">
      <Link className="user-back-link" href="/admin/users"><ArrowLeft size={17} />Back to users</Link>
      <section className="panel user-profile-header" aria-label="User profile">
        <div className="user-profile-avatar" aria-hidden="true">{initials}</div>
        <div className="user-profile-identity">
          <span className="user-detail-eyebrow">User details</span>
          <h1>{name}</h1>
          <p className="user-profile-id">User ID <span>{user.id}</span></p>
        </div>
        <div className="user-profile-actions">
          <span className={`user-account-status${user.status === "active" ? " is-active" : ""}`}>{user.status ?? "Unknown status"}</span>
          <RecordForm kind="user" initial={user} />
        </div>
      </section>
      <section className="panel user-account-panel" aria-labelledby="user-account-heading">
        <div className="user-section-heading"><UserRound size={20} /><h2 id="user-account-heading">Account information</h2></div>
        <dl className="user-account-grid">
          <div><dt><MapPin size={16} />Preferred area</dt><dd>{user.preferred_area?.trim() || "Not provided"}</dd></div>
          <div><dt><Phone size={16} />Phone number</dt><dd>{user.phone?.trim() || "Not provided"}</dd></div>
          <div><dt><Clock3 size={16} />Last sign-in</dt><dd>{user.last_sign_in_at ? formatDate(user.last_sign_in_at) : "No sign-in recorded"}</dd></div>
          <div><dt><CalendarDays size={16} />Date registered</dt><dd>{formatDate(user.created_at)}</dd></div>
        </dl>
      </section>
      <section className="panel user-activity-panel" aria-labelledby="user-activity-heading">
        <div className="user-section-heading"><ClipboardList size={20} /><h2 id="user-activity-heading">Submitted report activity</h2></div>
        <p className="user-section-description">Flood reports submitted by this user.</p>
        {error ? (
          <p role="alert">Report activity could not be loaded.</p>
        ) : !reports?.length ? (
          <div className="user-reports-empty">
            <span className="user-empty-icon"><ClipboardList size={26} /></span>
            <h3>No reports submitted yet</h3>
            <p>This user has not submitted any flood reports.</p>
          </div>
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
    </div>
  );
}
