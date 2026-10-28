import { z } from "zod";
const text = z.string().trim().min(1).max(4000);
export const capability: Record<string, string> = {
  road: "roads",
  observation: "observations",
  alert: "alerts",
  contact: "emergency",
  center: "emergency",
  user: "users",
};
const common = { id: z.union([z.uuid(), z.literal("")]).optional() };
export const saveSchema = z.discriminatedUnion("kind", [
  z.object({
    ...common,
    kind: z.literal("road"),
    name: text,
    locality: text,
    latitude: z.coerce.number().min(-90).max(90),
    longitude: z.coerce.number().min(-180).max(180),
    published: z.enum(["true", "false"]),
  }),
  z
    .object({
      ...common,
      kind: z.literal("observation"),
      road_id: z.uuid(),
      depth_cm: z.coerce.number().min(0).max(10000),
      source: text,
      measurement_kind: z.enum([
        "community_estimate",
        "instrument",
        "official_observation",
        "unknown",
      ]),
      supporting_report_id: z.union([z.uuid(), z.literal("")]),
      observed_at: text,
      valid_until: text,
      notes: z.string().max(4000),
      published: z.enum(["true", "false"]),
      archived: z.enum(["true", "false"]),
    })
    .refine(
      (x) =>
        Number.isFinite(Date.parse(x.observed_at)) &&
        Date.parse(x.observed_at) <= Date.now() &&
        Date.parse(x.valid_until) > Date.parse(x.observed_at),
      "Use a past observation timestamp and later expiry.",
    ),
  z.object({
    ...common,
    kind: z.literal("alert"),
    title: text,
    message: text,
    road_id: z.uuid(),
    severity: z.enum(["information", "caution", "danger"]),
    source: text,
    status: z.enum(["draft", "published", "expired"]),
    expires_at: text,
  }),
  z.object({
    ...common,
    kind: z.literal("contact"),
    organization: text,
    phone: text,
    service_area: text,
    details: z.string().max(4000),
    published: z.enum(["true", "false"]),
    archived: z.enum(["true", "false"]),
  }),
  z.object({
    ...common,
    kind: z.literal("center"),
    name: text,
    address: text,
    latitude: z.coerce.number().min(-90).max(90),
    longitude: z.coerce.number().min(-180).max(180),
    contact: text,
    operational_details: text,
    verified_at: text,
    published: z.enum(["true", "false"]),
    archived: z.enum(["true", "false"]),
  }),
  z.object({
    kind: z.literal("user"),
    id: z.uuid(),
    status: z.enum(["active", "suspended"]),
    reason: z.string().trim().min(5).max(2000),
  }),
]);
