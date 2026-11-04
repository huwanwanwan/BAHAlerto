import {test} from "node:test";
import assert from "node:assert/strict";
import {filterReports,periodBounds,manilaDay} from "../src/lib/report-period";
import {reportsPdf} from "../src/lib/reports-pdf";
import {sampleLocations} from "../src/lib/sample-locations";
import videos from "../src/data/cctv-recordings.json";

test("day/week/month/year filters use calendar boundaries",()=>{
  assert.deepEqual(periodBounds("day","2026-11-04"),{from:"2026-11-04",to:"2026-11-04"});
  assert.deepEqual(periodBounds("week","2026-11-04"),{from:"2026-11-02",to:"2026-11-08"});
  assert.deepEqual(periodBounds("month","2024-02-15"),{from:"2024-02-01",to:"2024-02-29"});
  assert.deepEqual(periodBounds("year","2026-11-04"),{from:"2026-01-01",to:"2026-12-31"});
  assert.equal(manilaDay("2026-11-03T16:00:00Z"),"2026-11-04");
});
test("Philippine midnight and combined report filters match the same export subset",()=>{
  const rows=[{id:"1",created_at:"2026-11-03T16:00:00Z",road_name:"Marilao",status:"verified"},{id:"2",created_at:"2026-11-03T15:59:59Z",road_name:"Marilao",status:"verified"},{id:"3",created_at:"2026-11-04T12:00:00Z",road_name:"Marilao",status:"pending"}];
  assert.deepEqual(filterReports(rows,{from:"2026-11-04",to:"2026-11-04",location:"marilao",status:"verified"}).map(r=>r.id),["1"]);
});
test("PDF contains every supplied report across multiple pages",()=>{
  const rows=Array.from({length:125},(_,i)=>({id:String(i),road_name:`Export Road ${i}`,depth_cm:10,status:"pending",created_at:"2026-11-04T12:00:00Z",description:`Report detail ${i}`}));
  const doc=reportsPdf(rows,"All time; all locations; all statuses");
  assert.ok(doc.getNumberOfPages()>1);
  const output=doc.output();
  assert.ok(output.startsWith("%PDF-"));
  assert.ok(output.includes("Export Road 0"));assert.ok(output.includes("Export Road 124"));
});
test("ten sample locations stay isolated and raw footage has verified free-source attribution",()=>{
  assert.equal(sampleLocations.length,10);assert.equal(new Set(sampleLocations.map(r=>r.id)).size,10);
  assert.ok(sampleLocations.every(r=>r.name.startsWith("[SAMPLE]")&&r.locality.includes("SAMPLE ONLY")));
  assert.equal(videos.length,2);assert.equal(new Set(videos.map(v=>v.id)).size,2);
  assert.ok(videos.every(v=>v.sourceUrl.startsWith("https://commons.wikimedia.org/wiki/")&&v.license==="CC BY-SA 4.0"&&v.author==="Exec8"&&v.src.startsWith("/sample-footage/")));
});
