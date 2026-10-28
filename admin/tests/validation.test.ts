import { test } from "node:test";
import assert from "node:assert/strict";
import { saveSchema } from "../src/lib/validation";
import { csvCell } from "../src/lib/modules";
test("invalid coordinates and unsafe depths are rejected", () => {
  assert.equal(
    saveSchema.safeParse({
      kind: "road",
      name: "Road",
      locality: "Area",
      latitude: 91,
      longitude: 120,
      published: "false",
    }).success,
    false,
  );
  assert.equal(
    saveSchema.safeParse({ kind: "observation", road_id: "bad", depth_cm: -1 })
      .success,
    false,
  );
});
test("unsupported operations and empty rejection reasons are rejected", () => {
  assert.equal(
    saveSchema.safeParse({ kind: "admin_memberships", id: "any" }).success,
    false,
  );
  assert.equal(
    saveSchema.safeParse({
      kind: "user",
      id: "10000000-0000-4000-8000-000000000001",
      status: "suspended",
      reason: "",
    }).success,
    false,
  );
});
test("CSV escapes delimiters and neutralizes spreadsheet formulas", () => {
  assert.equal(csvCell('=HYPERLINK("x")'), '"\'=HYPERLINK(""x"")"');
  assert.equal(csvCell("a,b"), '"a,b"');
});
