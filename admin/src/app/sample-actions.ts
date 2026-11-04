"use server";
import { requireWrite } from "@/lib/auth";
import { database } from "@/lib/supabase";
import { sampleLocations, samplePayloads } from "@/lib/sample-locations";
import { revalidatePath } from "next/cache";
import type { ActionState } from "./actions";

export async function installSamples():Promise<ActionState> {
  const admin=await requireWrite("roads");
  if(!admin.permissions.includes("observations"))return{error:"Road and flood-level permissions are required."};
  const db=await database();
  const existing=await db.from("road_locations").select("id,name").in("id",sampleLocations.map(road=>road.id));
  if(existing.error)return{error:"Sample locations could not be checked. Try again."};
  if(existing.data?.some(road=>!road.name.startsWith("[SAMPLE]")))return{error:"A reserved sample ID is already used by a real road. No samples were changed."};
  const existingObservations=await db.from("flood_observations").select("id,source").in("id",sampleLocations.map(road=>road.observationId));
  if(existingObservations.error||existingObservations.data?.some(row=>!row.source.startsWith("SAMPLE ONLY")))return{error:"The sample observations could not be safely checked. No samples were changed."};
  const now=Date.now();
  let completed=0;
  for(let start=0;start<sampleLocations.length;start+=3){
    const results=await Promise.all(sampleLocations.slice(start,start+3).map(async road=>{
      const payloads=samplePayloads(road,now);
      const saveRoad=await db.rpc("admin_save_record",{kind:"road",payload:payloads.road});
      if(saveRoad.error)return false;
      const observation=await db.rpc("admin_save_record",{kind:"observation",payload:payloads.observation});
      return !observation.error;
    }));
    completed+=results.filter(Boolean).length;
  }
  revalidatePath("/admin","layout");
  return completed===10?{success:"10 labeled sample roads and flood levels are published. Open the mobile map and tap Refresh, or wait for its automatic update."}:{error:`${completed} of 10 sample locations were saved. Retry to finish; existing samples will not be duplicated.`};
}
