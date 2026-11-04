"use client";

import { useState } from "react";
import type { RecordRow } from "@/lib/modules";
import { RecordsTable } from "./records-table";
import { RecordForm } from "./record-form";

type Tab = "contacts" | "centers";
type Dataset = { rows: RecordRow[]; total: number; error: string | null };

export function EmergencyWorkspace({ contacts, centers, connected, initialTab }: {
  contacts: Dataset; centers: Dataset; connected: boolean; initialTab: Tab;
}) {
  const [tab, setTab] = useState<Tab>(initialTab);
  const selectTab = (next: Tab) => {
    setTab(next);
    const url = new URL(window.location.href);
    if (next === "centers") url.searchParams.set("tab", "centers");
    else url.searchParams.delete("tab");
    window.history.replaceState(null, "", url);
  };
  return <>
    <div className="page-heading">
      <div><span className="eyebrow">BAHALERTO WORKSPACE</span><h1>Manage Emergency</h1><p>Manage emergency contacts and evacuation centers.</p></div>
      <RecordForm key={tab} kind={tab === "contacts" ? "contact" : "center"} disabled={!connected} />
    </div>
    <div className="emergency-switch" role="tablist" aria-label="Emergency sections" data-tab={tab}>
      <span className="emergency-switch-indicator" aria-hidden="true" />
      {(["contacts", "centers"] as const).map(key => <button
        key={key} id={`emergency-tab-${key}`} type="button" role="tab"
        aria-selected={tab === key} aria-controls={`emergency-panel-${key}`}
        tabIndex={tab === key ? 0 : -1} onClick={() => selectTab(key)}
        onKeyDown={event => {
          if (!["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) return;
          event.preventDefault();
          const next = event.key === "Home" ? "contacts" : event.key === "End" ? "centers" : tab === "contacts" ? "centers" : "contacts";
          selectTab(next);
          document.getElementById(`emergency-tab-${next}`)?.focus();
        }}
      >{key === "contacts" ? "Emergency Contacts" : "Evacuation Centers"}</button>)}
    </div>
    {(["contacts", "centers"] as const).map(key => {
      const data = key === "contacts" ? contacts : centers;
      const title = key === "contacts" ? "Emergency contacts" : "Evacuation centers";
      return <section key={key} id={`emergency-panel-${key}`} role="tabpanel" aria-labelledby={`emergency-tab-${key}`} hidden={tab !== key} className="panel emergency-tab-panel">
        <div className="panel-heading"><div><h2>{title}</h2><p>{data.total} {key === "contacts" ? "contacts" : "centers"}</p></div></div>
        {data.error ? <p className="error-message" role="alert">{data.error}</p> : <RecordsTable
          rows={data.rows} total={data.total} kind={key === "contacts" ? "contact" : "center"}
          columns={key === "contacts" ? ["organization", "phone", "service_area", "publication_status"] : ["name", "address", "contact", "verified_at", "publication_status"]}
        />}
      </section>;
    })}
  </>;
}
