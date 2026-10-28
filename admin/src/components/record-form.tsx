"use client";
import { useActionState, useState, useRef, useEffect } from "react";
import { Plus, X, Save, Pencil } from "lucide-react";
import { saveRecord, type ActionState } from "@/app/actions";
import { Button } from "./ui/button";
export type Field = {
  name: string;
  label: string;
  type?: string;
  options?: string[];
  optional?: boolean;
};
export const fields: Record<string, Field[]> = {
  road: [
    { name: "name", label: "Road name" },
    { name: "locality", label: "Barangay / municipality" },
    { name: "latitude", label: "Latitude", type: "number" },
    { name: "longitude", label: "Longitude", type: "number" },
    { name: "published", label: "Published", options: ["false", "true"] },
  ],
  observation: [
    { name: "road_id", label: "Road ID (UUID)" },
    { name: "depth_cm", label: "Reported depth (cm)", type: "number" },
    { name: "source", label: "Source / measurement method" },
    {
      name: "measurement_kind",
      label: "Evidence method",
      options: [
        "community_estimate",
        "instrument",
        "official_observation",
        "unknown",
      ],
    },
    {
      name: "supporting_report_id",
      label: "Supporting verified report ID (optional UUID)",
      optional: true,
    },
    { name: "observed_at", label: "Observed at (include timezone)" },
    { name: "valid_until", label: "Valid until (include timezone)" },
    {
      name: "notes",
      label: "Evidence and notes",
      type: "textarea",
      optional: true,
    },
    { name: "published", label: "Published", options: ["false", "true"] },
    { name: "archived", label: "Archived", options: ["false", "true"] },
  ],
  alert: [
    { name: "title", label: "Title" },
    { name: "message", label: "Warning message", type: "textarea" },
    { name: "road_id", label: "Affected road ID (UUID)" },
    {
      name: "severity",
      label: "Severity",
      options: ["information", "caution", "danger"],
    },
    { name: "source", label: "Official / attributed source" },
    {
      name: "status",
      label: "Status",
      options: ["draft", "published", "expired"],
    },
    { name: "expires_at", label: "Expires at (include timezone)" },
  ],
  contact: [
    { name: "organization", label: "Organization" },
    { name: "phone", label: "Telephone number" },
    { name: "service_area", label: "Service area" },
    { name: "details", label: "Details", type: "textarea", optional: true },
    { name: "published", label: "Published", options: ["false", "true"] },
    { name: "archived", label: "Archived", options: ["false", "true"] },
  ],
  center: [
    { name: "name", label: "Facility name" },
    { name: "address", label: "Address" },
    { name: "latitude", label: "Latitude", type: "number" },
    { name: "longitude", label: "Longitude", type: "number" },
    { name: "contact", label: "Contact information" },
    {
      name: "operational_details",
      label: "Verified operational details",
      type: "textarea",
    },
    {
      name: "verified_at",
      label: "Operational details verified at (with timezone)",
    },
    { name: "published", label: "Published", options: ["false", "true"] },
    { name: "archived", label: "Archived", options: ["false", "true"] },
  ],
  user: [
    {
      name: "status",
      label: "Account status",
      options: ["active", "suspended"],
    },
    { name: "reason", label: "Reason for change", type: "textarea" },
  ],
};
export function RecordForm({
  kind,
  disabled = false,
  initial,
}: {
  kind: string;
  disabled?: boolean;
  initial?: Record<string, unknown>;
}) {
  const [open, setOpen] = useState(false);
  const dialog = useRef<HTMLDialogElement>(null);
  useEffect(() => {
    if (open) dialog.current?.showModal();
  }, [open]);
  const [state, action, pending] = useActionState<ActionState, FormData>(
    saveRecord,
    {},
  );
  return (
    <>
      <Button
        variant={initial ? "outline" : "default"}
        size={initial ? "sm" : "default"}
        disabled={disabled}
        onClick={() => setOpen(true)}
      >
        {initial ? <Pencil size={14} /> : <Plus size={16} />}
        {initial
          ? "Edit"
          : "Add " +
            ({
              observation: "observation",
              road: "road",
              alert: "advisory",
              contact: "contact",
              center: "center",
              user: "account",
            }[kind] ?? "record")}
      </Button>
      {open && (
        <dialog
          ref={dialog}
          onClose={() => setOpen(false)}
          aria-labelledby={"form-" + kind}
          className="modal"
        >
          <div className="panel-heading">
            <div>
              <span className="eyebrow">ADMINISTRATOR ACTION</span>
              <h2 id={"form-" + kind}>
                {initial ? "Update" : "Create"} {kind}
              </h2>
            </div>
            <button
              className="icon-button"
              aria-label="Close form"
              onClick={() => setOpen(false)}
            >
              <X />
            </button>
          </div>
          <p>
            Changes are authorized and audited by the database. Publication
            makes records available to public readers.
          </p>
          <form
            action={action}
            className="form-stack"
            onSubmit={(e) => {
              if (
                !window.confirm(
                  "Save these changes and record this action in the audit log?",
                )
              )
                e.preventDefault();
            }}
          >
            <input name="kind" type="hidden" value={kind} />
            <input name="id" type="hidden" value={String(initial?.id ?? "")} />
            {fields[kind]?.map((f) => (
              <label key={f.name}>
                {f.label}
                {f.type === "textarea" ? (
                  <textarea
                    name={f.name}
                    required={!f.optional}
                    maxLength={4000}
                    defaultValue={String(initial?.[f.name] ?? "")}
                  />
                ) : f.options ? (
                  <select
                    name={f.name}
                    defaultValue={String(initial?.[f.name] ?? f.options[0])}
                  >
                    {f.options.map((o) => (
                      <option key={o}>{o}</option>
                    ))}
                  </select>
                ) : (
                  <input
                    name={f.name}
                    type={f.type ?? "text"}
                    step={f.type === "number" ? "any" : undefined}
                    required={!f.optional}
                    maxLength={4000}
                    defaultValue={String(initial?.[f.name] ?? "")}
                  />
                )}
              </label>
            ))}
            {kind === "observation" && (
              <div className="notice">
                An approved community estimate remains an estimate. Document the
                evidence; do not imply instrument precision. Saving an
                observation records your review.
              </div>
            )}
            {state.error && (
              <p role="alert" className="error-message">
                {state.error}
              </p>
            )}
            {state.success && (
              <p role="status" className="success-message">
                {state.success}
              </p>
            )}
            <Button disabled={pending}>
              <Save size={16} />
              {pending ? "Saving..." : "Save changes"}
            </Button>
          </form>
        </dialog>
      )}
    </>
  );
}
