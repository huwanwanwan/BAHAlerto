import { marilaoRoads } from "./marilao-roads";
const preferred = ["MacArthur Highway","Lias Road","Lambakin Road","Miguel Villarica Road","Barangay Patubig Road","Old Main Patubig Road","Lambakin Residential Road"];
const selected=[...preferred.map(name=>marilaoRoads.find(road=>road.name===name)).filter(road=>!!road),...marilaoRoads.filter(road=>!preferred.includes(road.name))].slice(0,10);
export const sampleLocations=selected.map((road,index)=>({
  id:`f1000000-0000-4000-8000-${String(index+1).padStart(12,"0")}`,
  observationId:`f2000000-0000-4000-8000-${String(index+1).padStart(12,"0")}`,
  name:`[SAMPLE] ${road.name}`,locality:"Marilao, Bulacan · SAMPLE ONLY",
  latitude:road.latitude,longitude:road.longitude,depth:[0,5,10,14,15,20,29,30,45,60][index],
}));

export function samplePayloads(road:typeof sampleLocations[number],now=Date.now()) {
  return {
    road:{id:road.id,name:road.name,locality:road.locality,latitude:road.latitude,longitude:road.longitude,published:"true"},
    observation:{id:road.observationId,road_id:road.id,depth_cm:road.depth,source:"SAMPLE ONLY - simulated depth, not a live flood measurement",measurement_kind:"community_estimate",supporting_report_id:"",observed_at:new Date(now-60000).toISOString(),valid_until:new Date(now+7*86400000).toISOString(),published:"true",archived:"false",notes:"SAMPLE ONLY. Demonstration water depth; do not use for travel decisions. Real mapped road coordinates, fictional flood conditions."},
  };
}
