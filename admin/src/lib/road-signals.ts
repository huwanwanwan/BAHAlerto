import type { RecordRow } from "./modules";

export function roadSignals(roads: RecordRow[], observations: RecordRow[], now = Date.now()) {
  const latest = new Map<string, RecordRow>();
  for (const observation of observations) {
    const depth = observation.depth_cm;
    const observed = Date.parse(String(observation.observed_at));
    const until = Date.parse(String(observation.valid_until));
    if (!observation.published || observation.archived || observation.verification_status !== "verified" ||
        observation.evidence !== "observation" || typeof depth !== "number" || !Number.isFinite(depth) || depth < 0 ||
        !Number.isFinite(observed) || !Number.isFinite(until) || observed > now || until <= now) continue;
    const roadId = String(observation.road_id);
    const previous = latest.get(roadId);
    if (!previous || observed > Date.parse(String(previous.observed_at)) ||
      (observed === Date.parse(String(previous.observed_at)) && Date.parse(String(observation.created_at)) > Date.parse(String(previous.created_at)))) latest.set(roadId, observation);
  }
  return roads.map(road => {
    const observation = road.published ? latest.get(road.id) : undefined;
    const depth = observation?.depth_cm as number | undefined;
    const signal = depth === undefined ? "unknown" : depth >= 30 ? "red" : depth >= 15 ? "orange" : "yellow";
    const label = {red:"High flood exposure",orange:"Moderate flood exposure",yellow:"Caution",unknown:"No current flood data"}[signal];
    return {...road, flood_signal:signal, signal_label:label, flood_depth:depth ?? null,
      flood_source:observation?.source ?? null, flood_observed_at:observation?.observed_at ?? null,
      flood_valid_until:observation?.valid_until ?? null};
  });
}

export const signalColors: Record<string,string> = {red:"#dc3545",orange:"#ef8b23",yellow:"#e4b51c",unknown:"#82938a"};
