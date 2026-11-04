import Link from "next/link";
import { notFound } from "next/navigation";
import {
  Users,
  ClipboardClock,
  Waves,
  Radio,
  ArrowUpRight,
  ShieldCheck,
} from "lucide-react";
import { modules, permissions, type RecordRow } from "@/lib/modules";
import { administrator } from "@/lib/auth";
import { records, roadsWithSignals, allRecords } from "@/lib/data";
import { configured, database } from "@/lib/supabase";
import { RecordsTable } from "@/components/records-table";
import { RecordForm } from "@/components/record-form";
import { Trends } from "@/components/charts";
import { LocationMap } from "@/components/location-map";
import { AnalyticsWorkspace } from "@/components/analytics-workspace";
import { CctvOverview } from "@/components/cctv-overview";
import { SettingsWorkspace } from "@/components/settings-workspace";
import { EmergencyWorkspace } from "@/components/emergency-workspace";
import { FloodLevelsWorkspace } from "@/components/flood-levels-workspace";
import { RouteRefresh } from "@/components/route-refresh";
import { RoadsWorkspace } from "@/components/roads-workspace";
export default async function Module({
  params,
  searchParams,
}: {
  params: Promise<{ module: string }>;
  searchParams: Promise<{ tab?: string; google?: string }>;
}) {
  const { module } = await params;
  const spec = modules.find((m) => m.slug === module);
  if (!spec) notFound();
  const { tab, google } = await searchParams;
  const isAudit = module === "analytics" && tab === "audit";
  const admin = await administrator(isAudit ? "audit" : permissions[module]);
  const connected = configured();
  if (module === "cctv") return <><div className="page-heading"><div><span className="eyebrow">VISUAL MONITORING</span><h1>Manage CCTV</h1><p>Recorded Philippine flood footage for sample viewing.</p></div></div><CctvOverview fullPage/></>;
  if (module === "settings") return <SettingsWorkspace connected={connected} googleStatus={google} />;
  if (module === "analytics") {
    const canAudit=admin?.permissions.includes("audit")??!connected;
    const canAnalytics=admin?.permissions.includes("analytics")??!connected;
    const empty={rows:[] as RecordRow[],total:0,error:null};
    const [reports,audit]=await Promise.all([canAnalytics?allRecords("flood_reports"):Promise.resolve(empty),canAudit?allRecords("audit_logs"):Promise.resolve(empty)]);
    return <AnalyticsWorkspace reports={reports.rows} audit={audit.rows} reportError={reports.error} auditError={audit.error} canAudit={canAudit} canAnalytics={canAnalytics} initialTab={isAudit?"audit":"analytics"}/>;
  }
  if (module === "emergency") {
    const [contacts, centers] = await Promise.all([
      records("emergency_contacts"), records("evacuation_centers"),
    ]);
    return <EmergencyWorkspace contacts={contacts} centers={centers} connected={connected} initialTab={tab === "centers" ? "centers" : "contacts"} />;
  }
  if (module === "levels") {
    const levels = await records("flood_observations");
    return <FloodLevelsWorkspace {...levels} connected={connected} />;
  }
  if (module === "roads") {
    const roads = await roadsWithSignals();
    return <RoadsWorkspace {...roads} connected={connected} canSamples={!!admin?.permissions.includes("roads")&&!!admin.permissions.includes("observations")} />;
  }
  const table = isAudit
    ? "audit_logs"
    : spec.table;
  const result = table
    ? await records(table)
    : { rows: [] as RecordRow[], total: 0, error: null };
  const reports =
    module === "dashboard" ? await records("flood_reports") : result;
  const trendCounts = new Map<string, number>();
  reports.rows.forEach((r) => {
    const day = new Date(String(r.created_at)).toLocaleDateString("en-CA", {
      timeZone: "Asia/Manila",
    });
    trendCounts.set(day, (trendCounts.get(day) ?? 0) + 1);
  });
  const trend = [...trendCounts]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([date, reports]) => ({ date, reports }));
  const cards = [
    {
      label: "Registered users",
      icon: Users,
      table: "profiles",
      field: "",
      value: "",
    },
    {
      label: "Pending reports",
      icon: ClipboardClock,
      table: "flood_reports",
      field: "status",
      value: "pending",
    },
    {
      label: "Current observations",
      icon: Waves,
      table: "flood_observations",
      field: "published",
      value: true,
    },
    {
      label: "Active advisories",
      icon: Radio,
      table: "flood_alerts",
      field: "status",
      value: "published",
    },
  ];
  const counts =
    module === "dashboard" && connected
      ? await Promise.all(
          cards.map(async (c) => {
            const db = await database();
            let q = db
              .from(c.table)
              .select("id", { count: "exact", head: true });
            if (c.field) q = q.eq(c.field, c.value);
            if (c.table === "flood_alerts")
              q = q
                .gt("expires_at", new Date().toISOString())
                .lte("published_at", new Date().toISOString());
            if (c.table === "flood_observations")
              q = q
                .eq("archived", false)
                .eq("verification_status", "verified")
                .eq("evidence", "observation")
                .not("depth_cm", "is", null)
                .lte("observed_at", new Date().toISOString())
                .gt("valid_until", new Date().toISOString());
            const { count, error } = await q;
            return error ? null : count;
          }),
        )
      : cards.map(() => null);
  const kind = (
    {
      levels: "observation",
      roads: "road",
      alerts: "alert",
      users: "user",
      emergency: tab === "centers" ? "center" : "contact",
    } as Record<string, string>
  )[module];
  const columns: Record<string, string[]> = {
    reports: ["road_name", "depth_cm", "created_at", "status"],
    levels: [
      "road_name",
      "depth_cm",
      "source",
      "observed_at",
      "observation_status",
    ],
    roads: ["name", "locality", "publication_status"],
    alerts: ["title", "road_name", "severity", "expires_at", "status"],
    users: ["full_name", "preferred_area", "created_at", "last_sign_in_at", "status"],
    emergency:
      tab === "centers"
        ? ["name", "address", "verified_at", "publication_status"]
        : ["organization", "phone", "service_area", "publication_status"],
    analytics: ["road_name", "depth_cm", "created_at", "status"],
  };
  return (
    <>
      {module === "reports" && <RouteRefresh />}
      <div className="page-heading">
        <div>
          <span className="eyebrow">BAHALERTO WORKSPACE</span>
          <h1>{spec.title}</h1>
          <p>{spec.subtitle}</p>
        </div>
        {kind && module !== "users" && (
          <RecordForm kind={kind} disabled={!connected} />
        )}
      </div>
      {(result.error || reports.error) && (
        <div className="error-message" role="alert">
          {result.error ?? reports.error}
        </div>
      )}
      {module === "dashboard" ? (
        <>
          <div className="stats-grid">
            {cards.map((c, i) => {
              const Icon = c.icon;
              return (
                <div className="stat" key={c.label}>
                  <div>
                    <span>{c.label}</span>
                    <Icon size={19} />
                  </div>
                  <strong>{counts[i] ?? "\u2014"}</strong>
                  <small>
                    {counts[i] == null
                      ? connected
                        ? "Count unavailable"
                        : "Awaiting database connection"
                      : "From authorized database records"}
                  </small>
                </div>
              );
            })}
          </div>
          <div className="dashboard-grid">
            <CctvOverview />
            <section className="panel">
              <div className="panel-heading">
                <div>
                  <h2>Report locations</h2>
                  <p>Observed locations, never route clearance</p>
                </div>
                <Link href="/admin/roads">
                  <ArrowUpRight size={20} />
                </Link>
              </div>
              <LocationMap
                points={reports.rows
                  .filter((r) => r.latitude != null)
                  .map((r) => ({
                    id: r.id,
                    name: String(r.id),
                    latitude: Number(r.latitude),
                    longitude: Number(r.longitude),
                    status: String(r.status),
                  }))}
              />
            </section>
          </div>
          <div className="dashboard-monitoring-grid">
            <section className="panel">
              <div className="panel-heading">
                <div>
                  <h2>Recent flood reports</h2>
                  <p>
                    Review submissions before using them in public observations.
                  </p>
                </div>
                <Link className="text-link" href="/admin/reports">
                  View reports &rarr;
                </Link>
              </div>
              <RecordsTable
                rows={reports.rows.slice(0, 5)}
                columns={["road_name", "depth_cm", "status"]}
                review
              />
            </section>
            <section className="panel">
              <div className="panel-heading">
                <div>
                  <h2>Community reporting activity</h2>
                  <p>Submissions by date / Philippine time</p>
                </div>
                <span className="badge">Latest loaded records</span>
              </div>
              <Trends data={trend} />
            </section>
          </div>
          <section className="safety-note">
            <ShieldCheck />
            <div>
              <strong>
                Verification is a review decision, not a safety rating.
              </strong>
              <p>
                Missing reports do not indicate safe roads. Publish source,
                observation time and evidence with every observation.
              </p>
            </div>
          </section>
        </>
      ) : (
        <>
          {module !== "analytics" && module !== "settings" && (
            <section className="panel">
              <div className="panel-heading">
                <div>
                  <h2>
                    {module === "levels"
                      ? "Observation history"
                      : spec.title.replace("Manage ", "")}
                  </h2>
                  <p>{result.total} authorized records</p>
                </div>
              </div>
              <RecordsTable
                key={table}
                rows={result.rows}
                total={result.total}
                columns={columns[module] ?? ["id"]}
                review={module === "reports"}
                kind={kind}
                exportable={module === "analytics"}
              />
            </section>
          )}
        </>
      )}
    </>
  );
}
