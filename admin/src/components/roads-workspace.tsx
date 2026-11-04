"use client";
import { useMemo, useState } from "react";
import type { RecordRow } from "@/lib/modules";
import { signalColors } from "@/lib/road-signals";
import { LocationMap } from "./location-map";
import { RecordsTable } from "./records-table";
import { RecordForm } from "./record-form";
import { RouteRefresh } from "./route-refresh";
import { SampleDataControl } from "./sample-data-control";

export function RoadsWorkspace({rows,total,error,connected,canSamples=false}: {rows:RecordRow[];total:number;error:string|null;connected:boolean;canSamples?:boolean}) {
  const [filteredRows, setFilteredRows] = useState(rows);
  const points = useMemo(() => filteredRows.filter(road => road.latitude != null && road.longitude != null).map(road => ({
    id:road.id,name:String(road.name),latitude:Number(road.latitude),longitude:Number(road.longitude),
    status:String(road.signal_label),markerColor:signalColors[String(road.flood_signal)] ?? signalColors.unknown,
    description:`${road.name} · ${road.signal_label}${road.flood_depth == null ? "" : ` · ${road.flood_depth} cm`}${road.flood_observed_at ? ` · Observed ${new Date(String(road.flood_observed_at)).toLocaleString("en-PH",{timeZone:"Asia/Manila"})}` : ""}`,
  })),[filteredRows]);
  return <>
    <RouteRefresh />
    <div className="page-heading"><div><span className="eyebrow">FLOOD MONITORING</span><h1>Manage Roads &amp; Locations</h1><p>Road locations and current reported flood exposure.</p></div><RecordForm kind="road" disabled={!connected} /></div>
    {error && <p role="alert" className="error-message">{error}</p>}
    <section className="panel roads-map-panel" aria-label="Road locations and flood signals">
      <LocationMap points={points} />
      <div className="road-signal-legend">
        <span><i style={{background:signalColors.red}} />Red · 30 cm and above</span>
        <span><i style={{background:signalColors.orange}} />Orange · 15–29 cm</span>
        <span><i style={{background:signalColors.yellow}} />Yellow · Below 15 cm</span>
        <span><i style={{background:signalColors.unknown}} />Gray · No current data</span>
      </div>
      <p className="flood-levels-help">{points.length} mapped locations match the table filters. Colors indicate flood exposure, not guaranteed passability.</p>
    </section>
    {canSamples&&<details className="roads-sample-tools"><summary>Sample location tools</summary><SampleDataControl disabled={!connected}/></details>}
    <section className="panel"><div className="panel-heading"><div><h2>Roads &amp; Locations</h2><p>{total} saved locations · Updates automatically</p></div></div>
      <RecordsTable rows={rows} total={total} kind="road" columns={["name","locality","flood_signal","publication_status"]} onFilteredRowsChange={setFilteredRows} />
    </section>
  </>;
}
