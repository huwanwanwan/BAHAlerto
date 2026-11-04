import catalogue from "@/data/marilao-roads.json";

export const marilaoRoads = catalogue.roads;
export function catalogueRoad(id: string) {
  return marilaoRoads.find(road => road.id === id);
}
export function marilaoRoadChoices(stored: {id: string; name: string; locality: string | null}[]) {
  const local = stored.filter(road => /\bmarilao\b/i.test(`${road.name} ${road.locality ?? ""}`));
  const names = new Set(local.map(road => road.name.trim().toLowerCase()));
  const ids = new Set(local.map(road => road.id));
  return [
    ...local,
    ...marilaoRoads.filter(road => !ids.has(road.id) && !names.has(road.name.trim().toLowerCase())),
  ].map(road => ({value: road.id, label: `${road.name} · ${road.locality || "Marilao, Bulacan"}`}))
    .sort((a,b) => a.label.localeCompare(b.label, undefined, {numeric:true}));
}
