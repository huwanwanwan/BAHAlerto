import "server-only";
import { configured, database } from "./supabase";
import type { RecordRow } from "./modules";
export async function records(table: string) {
  if (!configured())
    return { rows: [] as RecordRow[], total: 0, error: null as string | null };
  const db = await database();
  const { data, error, count } = await db
    .from(table)
    .select(
      ["flood_reports", "flood_observations", "flood_alerts"].includes(table)
        ? "*, road_locations(name,locality)"
        : "*",
      { count: "exact" },
    )
    .order(table === "audit_logs" ? "occurred_at" : "created_at", {
      ascending: false,
    })
    .limit(1000);
  const normalized = (data ?? []).map<RecordRow>((r) => {
    const row = r as unknown as RecordRow;
    const road = row.road_locations as {
      name?: string;
      locality?: string;
    } | null;
    return {
      ...row,
      road_name: road?.name ?? "Location unavailable",
      locality: road?.locality ?? row.locality,
    };
  });
  const rows = normalized.map((r) =>
    table === "flood_observations"
      ? {
          ...r,
          freshness: r.archived
            ? "Archived"
            : r.evidence === "historical"
              ? "Historical hazard"
              : r.verification_status !== "verified"
                ? "Unverified"
                : new Date(String(r.observed_at)).getTime() > Date.now()
                  ? "Future observation"
                  : new Date(String(r.valid_until)).getTime() <= Date.now()
                    ? "Outdated"
                    : "Current",
        }
      : table === "flood_alerts" &&
          r.status === "published" &&
          new Date(String(r.expires_at)).getTime() <= Date.now()
        ? { ...r, status: "expired" }
        : r,
  );
  return {
    rows: rows as RecordRow[],
    total: count ?? 0,
    error: error
      ? "Database request failed. Check migrations, permissions and connectivity."
      : null,
  };
}
