import type { RecordRow } from "./modules";
export type Period = "all" | "day" | "week" | "month" | "year";
export const manilaDay = (value: string | number | Date) => new Intl.DateTimeFormat("en-CA", {timeZone:"Asia/Manila",year:"numeric",month:"2-digit",day:"2-digit"}).format(new Date(value));
export function periodBounds(period: Period, anchor: string) {
  if (period === "all") return {from:"",to:""};
  const date = new Date(`${anchor}T00:00:00Z`);
  if (!Number.isFinite(date.getTime())) return {from:"",to:""};
  const end = new Date(date);
  if (period === "week") { date.setUTCDate(date.getUTCDate() - (date.getUTCDay()+6)%7); end.setTime(date.getTime()); end.setUTCDate(end.getUTCDate()+6); }
  if (period === "month") { date.setUTCDate(1); end.setUTCMonth(end.getUTCMonth()+1,0); }
  if (period === "year") { date.setUTCMonth(0,1); end.setUTCMonth(11,31); }
  return {from:date.toISOString().slice(0,10),to:end.toISOString().slice(0,10)};
}
export function filterReports(rows: RecordRow[], filters: {from:string;to:string;location:string;status:string}) {
  return rows.filter(row => {
    const date = new Date(String(row.created_at));
    if (!Number.isFinite(date.getTime())) return false;
    const day = manilaDay(date);
    return (!filters.from || day>=filters.from) && (!filters.to || day<=filters.to) &&
      (!filters.location || String(row.road_name ?? row.road_id ?? "").toLowerCase().includes(filters.location.toLowerCase())) &&
      (filters.status === "all" || row.status === filters.status);
  });
}
