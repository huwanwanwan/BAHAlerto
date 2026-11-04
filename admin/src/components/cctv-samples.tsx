"use client";
import { useState } from "react";
import { Pause, Play, Video } from "lucide-react";
import recordings from "@/data/cctv-recordings.json";
import { RecordedCameraTile } from "./recorded-camera-tile";

export function CctvSamples() {
  const [playing,setPlaying]=useState(true);
  const [query,setQuery]=useState("");
  const views=Array.from({length:10},(_,index)=>({index,recording:recordings[index%recordings.length]}));
  const visible=views.filter(view=>`${view.recording.title} ${view.recording.location} sample view ${view.index+1}`.toLowerCase().includes(query.toLowerCase()));
  return <div className="cctv-samples">
    <div className="cctv-sample-notice"><Video size={22}/><div><strong>Neighborhood flood footage · Sample monitoring wall</strong><p>10 demo tiles share two freely licensed recordings from Project 8, Quezon City, dated September 26, 2009. These are archival street recordings, not live or verified barangay CCTV feeds.</p></div></div>
    <div className="table-tools"><div className="search"><input aria-label="Search sample cameras" placeholder="Search location or sample view" value={query} onChange={event=>setQuery(event.target.value)}/></div><span>{visible.length} sample views</span><button className="button" type="button" onClick={()=>setPlaying(value=>!value)}>{playing?<Pause size={16}/>:<Play size={16}/>} {playing?"Pause previews":"Resume previews"}</button></div>
    <div className="cctv-sample-grid">{visible.map(view=><RecordedCameraTile key={view.index} recording={view.recording} index={view.index} playing={playing}/>)}</div>
    {!visible.length&&<section className="panel"><p>No recordings match this search.</p></section>}
  </div>;
}
