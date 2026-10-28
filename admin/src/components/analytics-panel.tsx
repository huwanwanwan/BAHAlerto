"use client";
import { useMemo, useState } from "react";
import { Trends } from "./charts";
import { RecordsTable } from "./records-table";
import type { RecordRow } from "@/lib/modules";
export function AnalyticsPanel({
  rows,
  total,
}: {
  rows: RecordRow[];
  total: number;
}) {
  const [from, setFrom] = useState(""),
    [to, setTo] = useState(""),
    [location, setLocation] = useState(""),
    [status, setStatus] = useState("all");
  const filtered = useMemo(
    () =>
      rows.filter(
        (r) =>
          (!from || String(r.created_at).slice(0, 10) >= from) &&
          (!to || String(r.created_at).slice(0, 10) <= to) &&
          (!location ||
            String(r.road_name ?? r.road_id)
              .toLowerCase()
              .includes(location.toLowerCase())) &&
          (status === "all" || r.status === status),
      ),
    [rows, from, to, location, status],
  );
  const counts = new Map<string, number>();
  filtered.forEach((r) => {
    const day = new Date(String(r.created_at)).toLocaleDateString("en-CA", {
      timeZone: "Asia/Manila",
    });
    counts.set(day, (counts.get(day) ?? 0) + 1);
  });
  const data = [...counts]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([date, reports]) => ({ date, reports }));
  return (
    <>
      <section className="panel">
        <h2>Reporting trends</h2>
        <p>
          Filters apply to charts and exports. Latest {rows.length} loaded
          records of {total} total.
        </p>
        <div className="table-tools">
          <label>
            From
            <input
              type="date"
              value={from}
              onChange={(e) => setFrom(e.target.value)}
            />
          </label>
          <label>
            To
            <input
              type="date"
              value={to}
              onChange={(e) => setTo(e.target.value)}
            />
          </label>
          <input
            aria-label="Filter location"
            placeholder="Search location"
            value={location}
            onChange={(e) => setLocation(e.target.value)}
          />
          <select
            aria-label="Analytics report status"
            value={status}
            onChange={(e) => setStatus(e.target.value)}
          >
            <option value="all">All statuses</option>
            {["pending", "verified", "rejected", "clarification"].map((s) => (
              <option key={s}>{s}</option>
            ))}
          </select>
        </div>
        <Trends data={data} bar />
      </section>
      <section className="panel">
        <h2>Authorized reporting export</h2>
        <RecordsTable
          rows={filtered}
          total={total}
          columns={["road_name", "depth_cm", "created_at", "status"]}
          exportable
          filters={false}
        />
      </section>
    </>
  );
}
