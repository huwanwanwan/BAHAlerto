import { test } from "node:test";
import assert from "node:assert/strict";
import { roadSignals } from "../src/lib/road-signals";

const now = Date.parse("2026-11-04T04:00:00Z");
const road = {id:"road",published:true};
const observation = {id:"observation",road_id:"road",depth_cm:30,source:"DRRMO",published:true,archived:false,verification_status:"verified",evidence:"observation",observed_at:"2026-11-04T03:00:00Z",valid_until:"2026-11-04T05:00:00Z",created_at:"2026-11-04T03:01:00Z"};

test("signal colors follow current depth thresholds including zero without claiming passability", () => {
  for (const [depth,color] of [[0,"yellow"],[14.9,"yellow"],[15,"orange"],[29.9,"orange"],[30,"red"]] as const) {
    const row=roadSignals([road],[{...observation,depth_cm:depth}],now)[0];
    assert.equal(row.flood_signal,color);
    assert.equal(row.flood_depth,depth);
    assert.ok(!row.signal_label.toLowerCase().includes("passable"));
  }
});
test("absent, stale, future, historical, hidden and unverified data stay unknown", () => {
  for (const change of [{valid_until:"2026-11-04T04:00:00Z"},{observed_at:"2026-11-04T04:01:00Z"},{evidence:"historical"},{published:false},{archived:true},{verification_status:"pending"},{depth_cm:null},{depth_cm:-1},{observed_at:"bad"}]) {
    assert.equal(roadSignals([road],[{...observation,...change}],now)[0].flood_signal,"unknown");
  }
  assert.equal(roadSignals([road],[],now)[0].flood_signal,"unknown");
  assert.equal(roadSignals([{...road,published:false}],[observation],now)[0].flood_signal,"unknown");
});
test("the newest eligible observation wins, rather than the largest old depth", () => {
  const newer={...observation,id:"newer",depth_cm:10,observed_at:"2026-11-04T03:30:00Z"};
  assert.equal(roadSignals([road],[observation,newer],now)[0].flood_signal,"yellow");
  assert.equal(roadSignals([road],[newer,observation],now)[0].flood_signal,"yellow");
});
