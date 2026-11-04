"use client";
import { useRef, useState } from "react";
import type { RecordRow } from "@/lib/modules";
import { AnalyticsReportPanel } from "./analytics-report-panel";
import { RecordsTable } from "./records-table";
import { RouteRefresh } from "./route-refresh";

export function AnalyticsWorkspace({reports,audit,canAudit,canAnalytics,initialTab,reportError,auditError}: {
  reports:RecordRow[];audit:RecordRow[];canAudit:boolean;canAnalytics:boolean;initialTab:"analytics"|"audit";reportError:string|null;auditError:string|null;
}) {
  const [tab,setTab]=useState(initialTab);
  const touchStart=useRef<{x:number;y:number}|null>(null);
  const select=(next:"analytics"|"audit")=>{setTab(next);const url=new URL(window.location.href);if(next==="audit")url.searchParams.set("tab","audit");else url.searchParams.delete("tab");window.history.replaceState(null,"",url)};
  return <div className="analytics-workspace"><RouteRefresh/>
    <div className="page-heading"><div><span className="eyebrow">BAHALERTO WORKSPACE</span><h1>Reports &amp; Analytics</h1><p>Explore community reports and administrator activity.</p></div></div>
    <div className="emergency-switch analytics-switch" data-tab={tab==="audit"?"centers":"contacts"} role="tablist" aria-label="Reports and analytics sections"
      onTouchStart={event=>{const point=event.touches[0];touchStart.current={x:point.clientX,y:point.clientY}}}
      onTouchEnd={event=>{const start=touchStart.current;touchStart.current=null;const end=event.changedTouches[0];if(!start||!end||!canAudit||!canAnalytics)return;const dx=end.clientX-start.x,dy=end.clientY-start.y;if(Math.abs(dx)>45&&Math.abs(dx)>Math.abs(dy)*1.5)select(dx<0?"audit":"analytics")}}
    ><span className="emergency-switch-indicator" aria-hidden="true"/>
      {(["analytics","audit"] as const).map(value=><button key={value} id={`analytics-tab-${value}`} role="tab" type="button" disabled={value==="audit"?!canAudit:!canAnalytics} aria-selected={tab===value} aria-controls={`analytics-panel-${value}`} tabIndex={tab===value?0:-1} onClick={()=>select(value)} onKeyDown={event=>{if(!["ArrowLeft","ArrowRight","Home","End"].includes(event.key)||!canAudit||!canAnalytics)return;event.preventDefault();const next=event.key==="Home"?"analytics":event.key==="End"?"audit":tab==="analytics"?"audit":"analytics";select(next);document.getElementById(`analytics-tab-${next}`)?.focus()}}>{value==="analytics"?"Reports & Analytics":"Audit Logs"}</button>)}
    </div>
    <div id="analytics-panel-analytics" role="tabpanel" aria-labelledby="analytics-tab-analytics" hidden={tab!=="analytics"} className="emergency-tab-panel">{reportError&&<p role="alert" className="error-message">{reportError}</p>}<AnalyticsReportPanel rows={reports} total={reports.length}/></div>
    {canAudit&&<section id="analytics-panel-audit" role="tabpanel" aria-labelledby="analytics-tab-audit" hidden={tab!=="audit"} className="panel emergency-tab-panel"><div className="panel-heading"><div><h2>Audit Logs</h2><p>Read-only history of administrator changes.</p></div></div>{auditError?<p role="alert" className="error-message">{auditError}</p>:<RecordsTable rows={audit} total={audit.length} columns={["action","table_name","occurred_at","audit_context"]}/>}</section>}
  </div>;
}
