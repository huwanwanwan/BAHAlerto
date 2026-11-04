"use client";
import { useActionState, useEffect, useRef, useState } from "react";
import { Pencil, Plus, Save, X } from "lucide-react";
import { observationChoices, saveRecord, type ActionState } from "@/app/actions";
import { Button } from "./ui/button";

function localDate(value: unknown) {
  const time = Date.parse(String(value ?? ""));
  return Number.isFinite(time) ? new Date(time + 8 * 3600000).toISOString().slice(0, 16) : "";
}

export function FloodLevelForm({ initial, disabled = false }: { initial?: Record<string, unknown>; disabled?: boolean }) {
  const [open, setOpen] = useState(false);
  const [choices, setChoices] = useState<Awaited<ReturnType<typeof observationChoices>>>();
  const [loadError, setLoadError] = useState("");
  const [roadSearch, setRoadSearch] = useState("");
  const [road, setRoad] = useState(String(initial?.road_id ?? ""));
  const dialog = useRef<HTMLDialogElement>(null);
  const [state, action, pending] = useActionState<ActionState, FormData>(saveRecord, {});
  useEffect(() => {
    if (!open) return;
    dialog.current?.showModal();
    let cancelled = false;
    observationChoices().then(data => { if (!cancelled) setChoices(data); }).catch(() => {
      if (!cancelled) setLoadError("Road choices could not be loaded. Close this form and try again.");
    });
    return () => { cancelled = true; };
  }, [open]);
  const roadOptions = choices?.roads ?? [];
  const visibleRoads = roadOptions.filter(option => option.value === road || option.label.toLowerCase().includes(roadSearch.trim().toLowerCase()));
  const reports = (choices?.reports ?? []).filter(report => report.roadId === road);
  return <>
    <Button variant={initial ? "outline" : "default"} size={initial ? "sm" : "default"} className={initial ? "action-edit" : undefined} disabled={disabled} onClick={() => { setLoadError(""); setOpen(true); }}>
      {initial ? <Pencil size={14} /> : <Plus size={16} />}{initial ? "Edit" : "Add flood level"}
    </Button>
    {open && <dialog ref={dialog} className="modal flood-level-modal" aria-labelledby="flood-level-title" onClose={() => setOpen(false)}>
      <div className="panel-heading"><h2 id="flood-level-title">{initial ? "Edit" : "Add"} flood level</h2><button type="button" className="icon-button" aria-label="Close form" onClick={() => setOpen(false)}><X /></button></div>
      <p>Enter the water depth and when it was observed. Times use Philippine time.</p>
      <form className="form-stack" action={form => {
        for (const name of ["observed_at", "valid_until"]) {
          const value = String(form.get(name));
          form.set(name, new Date(`${value}+08:00`).toISOString());
        }
        action(form);
      }}>
        <input type="hidden" name="kind" value="observation" />
        <input type="hidden" name="id" value={String(initial?.id ?? "")} />
        <input type="hidden" name="archived" value={String(initial?.archived ?? false)} />
        <div className="flood-road-picker">
        <label>Find a road in Marilao<input type="search" value={roadSearch} placeholder="Search road name…" onChange={event => setRoadSearch(event.target.value)} /></label>
        <label>Road<select name="road_id" value={road} required onChange={event => setRoad(event.target.value)}>
          <option value="" disabled>{choices ? "Choose a road" : "Loading roads…"}</option>
          {road && !roadOptions.some(option => option.value === road) && <option value={road}>{String(initial?.road_name ?? "Current road")}</option>}
          {visibleRoads.map(option => <option key={option.value} value={option.value}>{option.label}</option>)}
        </select></label>
        {choices && <p className="flood-road-count">{visibleRoads.length} road choices · Marilao, Bulacan</p>}
        <a className="flood-road-attribution" href="https://www.openstreetmap.org/copyright" target="_blank" rel="noreferrer">Road data © OpenStreetMap contributors</a>
        </div>
        <div className="flood-level-form-grid">
          <label>Water depth (cm)<input name="depth_cm" type="number" min="0" max="10000" step="any" required defaultValue={String(initial?.depth_cm ?? "")} /></label>
          <label>Evidence type<select name="measurement_kind" defaultValue={String(initial?.measurement_kind ?? "community_estimate")}>
            <option value="community_estimate">Community estimate</option><option value="instrument">Instrument reading</option><option value="official_observation">Official observation</option><option value="unknown">Unknown</option>
          </select></label>
        </div>
        <label>Source<input name="source" placeholder="e.g. Municipal DRRMO" required maxLength={4000} defaultValue={String(initial?.source ?? "")} /></label>
        <div className="flood-level-form-grid">
          <label>Observed on<input name="observed_at" type="datetime-local" required defaultValue={localDate(initial?.observed_at)} /></label>
          <label>Valid until<input name="valid_until" type="datetime-local" required defaultValue={localDate(initial?.valid_until)} /></label>
        </div>
        <label>Visibility<select name="published" defaultValue={String(initial?.published ?? false)}><option value="false">Hidden</option><option value="true">Public</option></select></label>
        <details className="flood-level-more"><summary>More details (optional)</summary><div className="form-stack">
          <label>Verified supporting report<select key={road} name="supporting_report_id" defaultValue={road === String(initial?.road_id ?? "") ? String(initial?.supporting_report_id ?? "") : ""}>
            <option value="">No linked report</option>
            {road === String(initial?.road_id ?? "") && initial?.supporting_report_id && !reports.some(report => report.value === initial.supporting_report_id) ? <option value={String(initial.supporting_report_id)}>Previously linked verified report</option> : null}
            {reports.map(report => <option key={report.value} value={report.value}>{report.label}</option>)}
          </select></label>
          <label>Notes<textarea name="notes" maxLength={4000} defaultValue={String(initial?.notes ?? "")} /></label>
        </div></details>
        {loadError && <p role="alert" className="error-message">{loadError}</p>}
        {state.error && <p role="alert" className="error-message">{state.error}</p>}
        {state.success && <p role="status" className="success-message">{state.success}</p>}
        <Button disabled={pending || !choices || !!loadError}><Save size={16} />{pending ? "Saving…" : "Save flood level"}</Button>
      </form>
    </dialog>}
  </>;
}
