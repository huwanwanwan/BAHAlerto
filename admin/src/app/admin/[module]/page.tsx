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
  const { tab } = await searchParams;
  const isAudit = module === "analytics" && tab === "audit";
  const admin = await administrator(isAudit ? "audit" : permissions[module]);
  const connected = configured();
  if (module === "cctv") return <><div className="page-heading"><div><span className="eyebrow">VISUAL MONITORING</span><h1>Manage CCTV</h1><p>Recorded CCTV video for sample viewing.</p></div></div><CctvOverview fullPage/></>;
  if (module === "settings") return <SettingsWorkspace connected={connected} />;
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
  const sampleTrend = [8, 12, 9, 18, 14, 23, 20].map((reports, index) => ({
    date: `Sample day ${index + 1}`, reports,
  }));
  const sampleStats = [
    { total: "1,248", change: "+12%", color: "#078443", pulse: "M0 26 H20 L27 22 L34 29 L42 26 H53 L60 12 L67 40 L76 5 L85 30 L93 23 L101 26 H160" },
    { total: "24", change: "−8%", color: "#c38c27", pulse: "M0 24 H12 L20 30 L28 17 L36 25 H62 L70 7 L78 39 L86 20 L94 24 H120 L130 32 L140 24 H160" },
    { total: "18", change: "+20%", color: "#458faf", pulse: "M0 30 H24 L32 25 L40 32 L48 30 H72 L80 18 L88 42 L96 4 L104 28 L112 22 L120 26 H138 L146 18 L154 23 H160" },
    { total: "6", change: "+2", color: "#a46aaf", pulse: "M0 27 H10 L18 12 L26 36 L34 23 L42 27 H78 L86 21 L94 30 L102 27 H119 L127 3 L135 43 L143 20 L151 27 H160" },
  ];
  const cards = [
    {
      label: "Registered users",
      href: "/admin/users",
      icon: Users,
      table: "profiles",
      field: "",
      value: "",
    },
    {
      label: "Pending reports",
      href: "/admin/reports",
      icon: ClipboardClock,
      table: "flood_reports",
      field: "status",
      value: "pending",
    },
    {
      label: "Current observations",
      href: "/admin/levels",
      icon: Waves,
      table: "flood_observations",
      field: "published",
      value: true,
    },
    {
      label: "Active advisories",
      href: "/admin/alerts",
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
                <Link className="stat" href={c.href} key={c.label}>
                  <div>
                    <span>{c.label}</span>
                    <Icon size={19} style={{ color: sampleStats[i].color, backgroundColor: `${sampleStats[i].color}12` }} />
                  </div>
                  <div className="stat-number-chart">
                    <strong>{counts[i] ?? sampleStats[i].total}</strong>
                    <svg style={{ color: sampleStats[i].color }} viewBox="0 0 160 48" role="img" aria-label={`Illustrative heartbeat trend for ${c.label}`}><path d={sampleStats[i].pulse} fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinejoin="round" strokeLinecap="round" /></svg>
                  </div>
                  <small>
                    {counts[i] == null
                      ? connected
                        ? "Sample total · actual count unavailable"
                        : "Sample total · preview only"
                      : "From authorized database records"}
                  </small>
                  <span className="sample-caption">Sample pulse · {sampleStats[i].change} over 7 days</span>
                </Link>
              );
            })}
          </div>
          <div className="dashboard-grid">
            <CctvOverview />
            <section className="panel dashboard-linked-panel">
              <div className="panel-heading">
                <div>
                  <h2>Report locations</h2>
                  <p>Observed locations, never route clearance</p>
                </div>
                <Link className="dashboard-card-link" href="/admin/roads" aria-label="View roads and report locations">
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
            <section className="panel dashboard-linked-panel dashboard-recent-reports">
              <div className="panel-heading">
                <div>
                  <h2>Recent flood reports</h2>
                  <p>
                    Review submissions before using them in public observations.
                  </p>
                </div>
                <Link className="text-link dashboard-card-link" href="/admin/reports">
                  View reports &rarr;
                </Link>
              </div>
              {reports.rows.length ? <RecordsTable
                rows={reports.rows.slice(0, 5)}
                columns={["road_name", "depth_cm", "status"]}
                review
              /> : <>
                <p className="sample-caption">Sample reports · fictional preview, not current flood conditions</p>
                <RecordsTable rows={[
                  { id: "sample-1", road_name: "Sample Riverside Road", depth_cm: 25, status: "pending" },
                  { id: "sample-2", road_name: "Sample Market Street", depth_cm: 15, status: "verified" },
                  { id: "sample-3", road_name: "Sample Central Avenue", depth_cm: 40, status: "pending" },
                  { id: "sample-4", road_name: "Sample School Road", depth_cm: 10, status: "rejected" },
                  { id: "sample-5", road_name: "Sample Bridge Approach", depth_cm: 30, status: "pending" },
                ]} columns={["road_name", "depth_cm", "status"]} />
              </>}
            </section>
            <section className="panel dashboard-linked-panel">
              <div className="panel-heading">
                <div>
                  <h2><Link className="dashboard-card-link" href="/admin/analytics">Community reporting activity</Link></h2>
                  <p>Submissions by date / Philippine time</p>
                </div>
                <span className="badge">{trend.length ? "Latest loaded records" : "Sample statistics"}</span>
              </div>
              {!trend.length && <div className="community-sample-stats"><div><strong>104</strong><span>Sample reports</span></div><div><strong>7 days</strong><span>Illustrative period</span></div><div><strong>23</strong><span>Peak daily reports</span></div></div>}
              <Trends data={trend.length ? trend : sampleTrend} />
              {!trend.length && <p className="sample-caption">Sample data for preview only. Actual reporting activity appears when records are available.</p>}
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
