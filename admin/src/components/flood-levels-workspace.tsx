import { RecordForm } from "./record-form";
import { RecordsTable } from "./records-table";
import { RouteRefresh } from "./route-refresh";
import type { RecordRow } from "@/lib/modules";

export function FloodLevelsWorkspace({ rows, total, error, connected }: {
  rows: RecordRow[]; total: number; error: string | null; connected: boolean;
}) {
  return <div className="flood-levels-workspace">
    <RouteRefresh />
    <div className="page-heading"><div><span className="eyebrow">FLOOD MONITORING</span><h1>Manage Flood Levels</h1><p>Review and publish current water levels for each road.</p></div><RecordForm kind="observation" disabled={!connected} /></div>
    {error && <p className="error-message" role="alert">{error}</p>}
    <section className="panel flood-levels-panel">
      <div className="panel-heading"><div><h2>Flood level records</h2><p>{total} records · Updates automatically</p></div></div>
      <RecordsTable rows={rows} total={total} kind="observation" columns={["road_name", "depth_cm", "observed_at", "valid_until", "observation_status"]} />
      <p className="flood-levels-help">Only published, verified levels within their validity period appear as current on mobile.</p>
    </section>
  </div>;
}
