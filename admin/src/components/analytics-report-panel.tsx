"use client";
import { useMemo, useState } from "react";
import { Download, SlidersHorizontal } from "lucide-react";
import { Trends } from "./charts";
import { RecordsTable } from "./records-table";
import { filterReports, manilaDay, periodBounds, type Period } from "@/lib/report-period";
import type { RecordRow } from "@/lib/modules";

export function AnalyticsReportPanel({rows,total}: {rows:RecordRow[];total:number}) {
  const [period,setPeriod]=useState<Period|"custom">("all");
  const [anchor,setAnchor]=useState(()=>manilaDay(Date.now()));
  const [from,setFrom]=useState(""),[to,setTo]=useState(""),[location,setLocation]=useState(""),[status,setStatus]=useState("all");
  const [exporting,setExporting]=useState(false),[exportError,setExportError]=useState("");
  const [showFilters,setShowFilters]=useState(true);
  const filtered=useMemo(()=>filterReports(rows,{from,to,location,status}),[rows,from,to,location,status]);
  const data=useMemo(()=>{const counts=new Map<string,number>();for(const row of filtered){const day=manilaDay(String(row.created_at));counts.set(day,(counts.get(day)??0)+1)}return [...counts].sort(([a],[b])=>a.localeCompare(b)).map(([date,reports])=>({date,reports}));},[filtered]);
  function choosePeriod(value:Period,date=anchor){setPeriod(value);setAnchor(date);const range=periodBounds(value,date);setFrom(range.from);setTo(range.to)}
  async function download(){setExporting(true);setExportError("");try{const {reportsPdf}=await import("@/lib/reports-pdf");reportsPdf(filtered,`Period: ${from||"All dates"} to ${to||"present"} | Location: ${location||"All"} | Status: ${status}`).save("bahalerto-flood-reports.pdf");}catch{setExportError("The PDF could not be generated. Please try again.")}finally{setExporting(false)}}
  return <>
    <div className="analytics-export-toolbar"><button type="button" className="button" disabled={exporting||!filtered.length} onClick={()=>void download()}><Download size={17}/>{exporting?"Preparing PDF...":"Download PDF"}</button></div>
    <section className="panel analytics-filters">
      <div className="panel-heading"><div><h2>Report filters</h2><p>Charts, totals and downloads use the same filters.</p></div><div className="analytics-header-actions"><div className="analytics-periods analytics-periods-right" role="group" aria-label="Reporting period">{(["all","day","week","month","year"] as Period[]).map(value=><button key={value} type="button" aria-pressed={period===value} onClick={()=>choosePeriod(value)}>{value==="all"?"All time":value[0].toUpperCase()+value.slice(1)}</button>)}</div><button type="button" className="analytics-filter-toggle" aria-expanded={showFilters} aria-controls="analytics-report-filters" onClick={()=>setShowFilters(value=>!value)}><SlidersHorizontal size={17}/>Filters</button></div></div>
      <div id="analytics-report-filters" className="analytics-filter-layout" hidden={!showFilters}>
      <div className="analytics-filter-grid">
        <label>Search location<input placeholder="Search location" value={location} onChange={e=>setLocation(e.target.value)}/></label>
        {period!=="all"&&period!=="custom"&&<label>Reference date<input aria-label="Reference date" type="date" value={anchor} onChange={e=>{if(e.target.value)choosePeriod(period,e.target.value)}}/></label>}
        <label>From<input type="date" value={from} onChange={e=>{setPeriod("custom");setFrom(e.target.value)}}/></label>
        <label>To<input type="date" value={to} onChange={e=>{setPeriod("custom");setTo(e.target.value)}}/></label>
        <label>Status<select value={status} onChange={e=>setStatus(e.target.value)}><option value="all">All statuses</option>{["pending","verified","rejected","clarification"].map(value=><option key={value} value={value}>{value[0].toUpperCase()+value.slice(1)}</option>)}</select></label>
      </div>
      </div>
      {exportError&&<p className="error-message" role="alert">{exportError}</p>}
      <p className="flood-levels-help">{filtered.length} matching reports / {total} authorized reports. Times use Asia/Manila.</p>
    </section>
    <div className="analytics-summary">{[["All matching reports",filtered.length],["Pending",filtered.filter(r=>r.status==="pending").length],["Verified",filtered.filter(r=>r.status==="verified").length],["Rejected",filtered.filter(r=>r.status==="rejected").length],["Needs clarification",filtered.filter(r=>r.status==="clarification").length]].map(([label,count])=><section className="analytics-summary-card" key={label}><span>{label}</span><strong>{count}</strong></section>)}</div>
    <section className="panel"><div className="panel-heading"><div><h2>Reporting trends</h2><p>Reports submitted per day</p></div></div><Trends data={data} bar/></section>
    <section className="panel"><div className="panel-heading"><div><h2>All matching reports</h2><p>Every matching record is included in the PDF, across all table pages.</p></div></div><RecordsTable rows={filtered} total={filtered.length} columns={["road_name","depth_cm","observed_at","created_at","status"]} filters={false}/></section>
  </>;
}
