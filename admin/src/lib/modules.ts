export const modules = [
  {
    slug: "dashboard",
    title: "Dashboard",
    subtitle:
      "An overview of community reports and published flood information.",
    table: "",
  },
  {
    slug: "reports",
    title: "Manage Flood Reports",
    subtitle:
      "Review community observations. Keep evidence and verification distinct.",
    table: "flood_reports",
  },
  {
    slug: "levels",
    title: "Manage Flood Levels",
    subtitle: "Maintain attributed observations, freshness and publication.",
    table: "flood_observations",
  },
  {
    slug: "roads",
    title: "Manage Roads & Locations",
    subtitle: "Manage supported locations without assuming road passability.",
    table: "road_locations",
  },
  {
    slug: "alerts",
    title: "Manage Alerts",
    subtitle: "Publish sourced warnings for affected communities.",
    table: "flood_alerts",
  },
  {
    slug: "cctv",
    title: "Manage CCTV",
    subtitle: "Camera views for supported monitoring locations.",
    table: "",
  },
  {
    slug: "users",
    title: "Manage Users",
    subtitle: "Authorized account information and reporting activity.",
    table: "profiles",
  },
  {
    slug: "emergency",
    title: "Manage Emergency",
    subtitle: "Maintain verified contacts and evacuation center information.",
    table: "emergency_contacts",
  },
  {
    slug: "analytics",
    title: "Reports & Analytics",
    subtitle: "Reporting trends, exports and administrator audit logs.",
    table: "flood_reports",
  },
  {
    slug: "settings",
    title: "Settings",
    subtitle: "Administrator account and application settings.",
    table: "",
  },
] as const;
export type ModuleSlug = (typeof modules)[number]["slug"];
export type RecordRow = { id: string; [key: string]: unknown };
export function display(value: unknown): string {
  return value == null
    ? "Not available"
    : typeof value === "object"
      ? JSON.stringify(value)
      : String(value);
}
export function csvCell(value: unknown) {
  const text = display(value);
  return (
    '"' +
    (/^[=+@\-\t\r]/.test(text) ? "'" + text : text).replaceAll('"', '""') +
    '"'
  );
}
export const permissions: Record<string, string> = {
  reports: "reports",
  levels: "observations",
  roads: "roads",
  alerts: "alerts",
  users: "users",
  emergency: "emergency",
  analytics: "analytics",
  settings: "account",
  dashboard: "dashboard",
  cctv: "dashboard",
};
