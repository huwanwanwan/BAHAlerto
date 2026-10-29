"use client";
import Link from "next/link";
import { useMemo, useState, useTransition } from "react";
import {
  Search,
  Inbox,
  Download,
  ChevronLeft,
  ChevronRight,
  Eye,
  Trash2,
  Archive,
} from "lucide-react";
import { display, csvCell, type RecordRow } from "@/lib/modules";
import { deleteOrArchiveRecord } from "@/app/actions";
import { Button } from "./ui/button";
import { RecordForm } from "./record-form";
import { TableRowsSkeleton } from "./skeletons";
const columnLabels: Record<string, string> = {
  road_name: "Location",
  name: "Name",
  locality: "Area",
  depth_cm: "Depth",
  created_at: "Submitted",
  observed_at: "Observed",
  observation_status: "Data status",
  publication_status: "Publication",
  full_name: "Name",
  last_sign_in_at: "Last sign-in",
  preferred_area: "Preferred area",
  expires_at: "Expires",
  verified_at: "Last verified",
  organization: "Organization",
  phone: "Contact number",
  service_area: "Service area",
  table_name: "Module",
  occurred_at: "Date & time",
  audit_context: "Details",
  status: "Status",
  source: "Source",
  severity: "Severity",
  title: "Advisory",
  address: "Address",
  action: "Action",
};
function publicationStatus(row: RecordRow) {
  return row.archived
    ? "archived"
    : row.published
      ? "published"
      : "unpublished";
}
function observationStatus(row: RecordRow) {
  if (row.archived) return "archived";
  if (row.evidence === "historical") return "historical";
  if (row.verification_status !== "verified") return "unverified";
  if (!row.published) return "unpublished";
  return String(row.freshness ?? "unavailable").toLowerCase();
}
function cellValue(row: RecordRow, column: string): unknown {
  if (column === "publication_status") return publicationStatus(row);
  if (column === "observation_status")
    return `${display(row.verification_status)} / ${display(row.freshness)} / ${publicationStatus(row)}`;
  return row[column];
}
function TableCell({ row, column }: { row: RecordRow; column: string }) {
  if (column === "table_name")
    return (
      <>
        {(
          {
            flood_reports: "Flood Reports",
            flood_observations: "Flood Levels",
            road_locations: "Roads & Locations",
            flood_alerts: "Alerts",
            profiles: "Users",
            emergency_contacts: "Emergency Contacts",
            evacuation_centers: "Evacuation Centers",
          } as Record<string, string>
        )[String(row[column])] ?? display(row[column])}
      </>
    );
  if (column === "action")
    return (
      <>
        {(
          {
            INSERT: "Created",
            UPDATE: "Updated",
            ACCOUNT_STATUS: "Account status changed",
          } as Record<string, string>
        )[String(row[column])] ?? display(row[column])}
      </>
    );
  if (column === "audit_context")
    return (
      <details className="table-record-details">
        <summary>View details</summary>
        <dl>
          <dt>Administrator</dt>
          <dd>{display(row.actor_id)}</dd>
          <dt>Affected record</dt>
          <dd>{display(row.record_id)}</dd>
          <dt>Review metadata</dt>
          <dd>{display(row.details)}</dd>
        </dl>
      </details>
    );
  if (column === "observation_status")
    return (
      <div className="table-status-stack">
        <span className={"badge " + display(row.verification_status)}>
          {display(row.verification_status)}
        </span>
        <span>{display(row.freshness)}</span>
        <small>{publicationStatus(row)}</small>
      </div>
    );
  if (["status", "severity", "publication_status"].includes(column))
    return (
      <span className={"badge " + display(cellValue(row, column))}>
        {display(cellValue(row, column))}
      </span>
    );
  if (column === "depth_cm")
    return row[column] == null ? (
      "Unavailable"
    ) : (
      <span title={`${(Number(row[column]) / 2.54).toFixed(1)} inches`}>
        {display(row[column])} cm
      </span>
    );
  if (column.endsWith("_at") && row[column])
    return new Date(String(row[column])).toLocaleString("en-PH", {
      timeZone: "Asia/Manila",
      dateStyle: "medium",
      timeStyle: "short",
    });
  return <>{display(cellValue(row, column))}</>;
}
function getColumnClass(column: string): string {
  if (
    ["name", "road_name", "title", "address", "organization"].includes(column)
  )
    return "col-name";
  if (
    ["status", "severity", "publication_status", "observation_status"].includes(
      column,
    )
  )
    return "col-status";
  if (column.endsWith("_at") || column === "created_at") return "col-date";
  if (column === "depth_cm") return "col-depth";
  return "";
}

function DeleteRecordButton({
  kind,
  row,
}: {
  kind: string;
  row: RecordRow;
}) {
  const [isPending, startTransition] = useTransition();
  const isArchived = Boolean(
    row.archived ||
      (kind === "road" && row.published === false) ||
      (kind === "alert" && row.status === "expired") ||
      (kind === "user" && row.status === "suspended"),
  );

  const handleAction = () => {
    const actionLabel = isArchived ? "restore" : "delete / archive";
    const confirmPrompt = isArchived
      ? `Re-activate and restore this ${kind} record?`
      : `Are you sure you want to delete/archive this ${kind} record? It will be removed from public view and saved in the audit log.`;

    if (!window.confirm(confirmPrompt)) return;

    startTransition(async () => {
      const res = await deleteOrArchiveRecord(kind, row, !isArchived);
      if (res.error) {
        alert(res.error);
      }
    });
  };

  return (
    <Button
      variant={isArchived ? "outline" : "outline-destructive"}
      size="sm"
      disabled={isPending}
      title={
        isArchived
          ? "Currently archived. Click to restore."
          : `Delete / Archive this ${kind}`
      }
      onClick={handleAction}
    >
      {isArchived ? <Archive size={13} /> : <Trash2 size={13} />}
      {isPending ? "..." : isArchived ? "Restore" : "Delete"}
    </Button>
  );
}

export function RecordsTable({
  rows,
  columns,
  review = false,
  kind,
  exportable = false,
  total = rows.length,
  filters = true,
  loading = false,
}: {
  rows: RecordRow[];
  columns: string[];
  review?: boolean;
  kind?: string;
  exportable?: boolean;
  total?: number;
  filters?: boolean;
  loading?: boolean;
}) {
  const [query, setQuery] = useState(""),
    [status, setStatus] = useState("all"),
    [page, setPage] = useState(0),
    [from, setFrom] = useState(""),
    [to, setTo] = useState("");
  const statusOptions = columns.includes("publication_status")
    ? ["published", "unpublished", "archived"]
    : columns.includes("observation_status")
      ? [
          "current",
          "outdated",
          "unverified",
          "historical",
          "unpublished",
          "archived",
        ]
      : kind === "user"
        ? ["active", "suspended"]
        : kind === "alert"
          ? ["draft", "published", "expired"]
          : columns.includes("status")
            ? ["pending", "verified", "rejected", "clarification"]
            : [];
  const rowStatus = (row: RecordRow) =>
    columns.includes("publication_status")
      ? publicationStatus(row)
      : columns.includes("observation_status")
        ? observationStatus(row)
        : String(row.status ?? row.verification_status ?? "");
  const filtered = useMemo(
    () =>
      rows.filter(
        (r) =>
          Object.values(r).some((v) =>
            display(v).toLowerCase().includes(query.toLowerCase()),
          ) &&
          (status === "all" || rowStatus(r) === status) &&
          (!from || String(r.created_at).slice(0, 10) >= from) &&
          (!to || String(r.created_at).slice(0, 10) <= to),
      ),
    [rows, query, status, from, to],
  );
  const pages = Math.max(1, Math.ceil(filtered.length / 10));
  const current = Math.min(page, pages - 1);
  function exportCsv() {
    const output = [
      columns
        .map((column) => csvCell(columnLabels[column] ?? column))
        .join(","),
      ...filtered.map((r) =>
        columns.map((c) => csvCell(cellValue(r, c))).join(","),
      ),
    ].join("\r\n");
    const url = URL.createObjectURL(
      new Blob(["\ufeff" + output], { type: "text/csv;charset=utf-8" }),
    );
    const a = document.createElement("a");
    a.href = url;
    a.download = "bahalerto-authorized-records.csv";
    a.click();
    URL.revokeObjectURL(url);
  }
  return (
    <>
      <div className="table-tools">
        {filters && (
          <>
            <div className="search">
              <Search size={17} />
              <input
                aria-label="Search records"
                placeholder="Search records..."
                value={query}
                onChange={(e) => {
                  setQuery(e.target.value);
                  setPage(0);
                }}
              />
            </div>
            {statusOptions.length > 0 && (
              <select
                aria-label="Filter status"
                value={status}
                onChange={(e) => {
                  setStatus(e.target.value);
                  setPage(0);
                }}
              >
                <option value="all">All statuses</option>
                {statusOptions.map((s) => (
                  <option key={s}>{s}</option>
                ))}
              </select>
            )}
          </>
        )}
        {exportable && (
          <>
            {filters && (
              <>
                <input
                  aria-label="From date"
                  type="date"
                  value={from}
                  onChange={(e) => setFrom(e.target.value)}
                />
                <input
                  aria-label="To date"
                  type="date"
                  value={to}
                  onChange={(e) => setTo(e.target.value)}
                />
              </>
            )}
            <button
              className="button outline"
              disabled={!filtered.length}
              onClick={exportCsv}
            >
              <Download size={16} />
              Export CSV
            </button>
          </>
        )}
      </div>
      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              {columns.map((c) => (
                <th key={c} className={getColumnClass(c)}>
                  {kind === "user" && c === "created_at"
                    ? "Joined"
                    : (columnLabels[c] ?? c.replaceAll("_", " "))}
                </th>
              ))}
              {(review || kind) && <th className="table-action-col">Action</th>}
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <TableRowsSkeleton
                rows={5}
                columns={columns.length + (review || kind ? 1 : 0)}
              />
            ) : (
              filtered.slice(current * 10, current * 10 + 10).map((row) => (
                <tr key={row.id}>
                  {columns.map((c) => (
                    <td key={c} className={getColumnClass(c)}>
                      <TableCell row={row} column={c} />
                    </td>
                  ))}
                  {review && (
                    <td className="table-action-col">
                      <div className="table-row-actions">
                        <Link
                          className="button outline button-sm"
                          href={"/admin/reports/" + row.id}
                        >
                          <Eye size={14} />
                          Review
                        </Link>
                      </div>
                    </td>
                  )}
                  {kind && !review && (
                    <td className="table-action-col">
                      <div className="table-row-actions">
                        {kind === "user" && (
                          <Link
                            className="button outline button-sm"
                            href={"/admin/users/" + row.id}
                          >
                            <Eye size={14} />
                            Details
                          </Link>
                        )}
                        <RecordForm kind={kind} initial={row} />
                        <DeleteRecordButton kind={kind} row={row} />
                      </div>
                    </td>
                  )}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
      {!loading && !filtered.length && (
        <div className="empty">
          <span>
            <Inbox size={28} />
          </span>
          <h3>
            No {query || status !== "all" ? "matching " : ""}records to display
          </h3>
          <p>
            {rows.length
              ? "Try a different search or status filter."
              : "Records will appear here after the database is connected and authorized information is added."}
          </p>
        </div>
      )}
      <div className="pagination">
        <span>
          {filtered.length} loaded matches / {total} total records
          {total > rows.length
            ? " / showing latest 1,000; narrow database queries for larger datasets"
            : ""}
        </span>
        <div>
          <button
            className="icon-button"
            aria-label="Previous page"
            disabled={current === 0}
            onClick={() => setPage(current - 1)}
          >
            <ChevronLeft size={18} />
          </button>
          <span>
            {current + 1} / {pages}
          </span>
          <button
            className="icon-button"
            aria-label="Next page"
            disabled={current + 1 >= pages}
            onClick={() => setPage(current + 1)}
          >
            <ChevronRight size={18} />
          </button>
        </div>
      </div>
    </>
  );
}
