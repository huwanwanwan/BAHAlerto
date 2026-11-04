import "server-only";
import { configured, database } from "./supabase";
import type { RecordRow } from "./modules";
import { roadSignals } from "./road-signals";

export async function allRecords(table:"flood_reports"|"audit_logs") {
  if (!configured()) return {rows:[] as RecordRow[],total:0,error:null as string|null};
  const db=await database();const rows:RecordRow[]=[];
  for(let start=0;;start+=500){
    const page=await db.from(table).select(table==="flood_reports"?"id,road_id,depth_cm,description,status,review_reason,observed_at,created_at,road_locations(name,locality)":"*").order(table==="audit_logs"?"occurred_at":"created_at",{ascending:false}).order("id").range(start,start+499);
    if(page.error)return{rows:[] as RecordRow[],total:0,error:"Reports could not be loaded. Refresh and try again."};
    rows.push(...(page.data??[]) as unknown as RecordRow[]);
    if((page.data?.length??0)<500)break;
  }
  return{rows:rows.map(row=>({...row,road_name:(row.road_locations as {name?:string}|null)?.name??"Location unavailable"})),total:rows.length,error:null};
}

export async function roadsWithSignals() {
  if (!configured()) return {rows:[] as RecordRow[],total:0,error:null as string|null};
  const db = await database();
  const roads: RecordRow[] = [];
  for (let start = 0; ; start += 500) {
    const page = await db.from("road_locations").select("*").order("id").range(start,start+499);
    if (page.error) return {rows:[] as RecordRow[],total:0,error:"Roads could not be loaded. Please refresh."};
    roads.push(...(page.data ?? []));
    if ((page.data?.length ?? 0) < 500) break;
  }
  const observations: RecordRow[] = [];
  const now = new Date().toISOString();
  for (let start = 0; ; start += 500) {
    const page = await db.from("flood_observations").select("id,road_id,depth_cm,source,observed_at,valid_until,created_at,published,archived,verification_status,evidence")
      .eq("published",true).eq("archived",false).eq("verification_status","verified").eq("evidence","observation")
      .lte("observed_at",now).gt("valid_until",now).not("depth_cm","is",null)
      .order("id").range(start,start+499);
    if (page.error) return {rows:roadSignals(roads,[]),total:roads.length,error:"Flood data could not be loaded. Road signals are shown as unknown."};
    observations.push(...(page.data ?? []));
    if ((page.data?.length ?? 0) < 500) break;
  }
  return {rows:roadSignals(roads,observations),total:roads.length,error:null};
}
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
