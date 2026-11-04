"use client";
import { useEffect, useRef, useState } from "react";
import { Play } from "lucide-react";

export type Recording = {
  id:string;title:string;location:string;recordedDate:string;src:string;
  sourceUrl:string;author:string;license:string;licenseUrl:string;
};
export function RecordedCameraTile({recording,index,playing}:{recording:Recording;index:number;playing:boolean}) {
  const tile=useRef<HTMLElement>(null);
  const video=useRef<HTMLVideoElement>(null);
  const [visible,setVisible]=useState(false);
  const [blocked,setBlocked]=useState(false);
  const [failed,setFailed]=useState(false);
  useEffect(()=>{
    const element=tile.current;if(!element)return;
    const observer=new IntersectionObserver(entries=>setVisible(entries[0]?.isIntersecting??false),{threshold:0.1});
    observer.observe(element);return()=>observer.disconnect();
  },[]);
  useEffect(()=>{
    const player=video.current;if(!player)return;
    const update=()=>{if(playing&&visible&&!document.hidden)void player.play().catch(()=>setBlocked(true));else player.pause()};
    update();document.addEventListener("visibilitychange",update);
    return()=>document.removeEventListener("visibilitychange",update);
  },[playing,visible]);
  return <article className="cctv-sample-card" ref={tile}>
    <div className="cctv-recording cctv-native-recording">
      <video ref={video} src={visible?recording.src:undefined} aria-label={`Sample view ${index+1}: ${recording.title}`} autoPlay={playing} muted loop playsInline controls preload="none" onPlay={()=>setBlocked(false)} onError={()=>setFailed(true)}/>
      <span className="cctv-sample-label">SAMPLE VIEW {String(index+1).padStart(2,"0")} · RECORDED</span>
      <span className="cctv-recorded-date">REC {recording.recordedDate}</span>
      {blocked&&playing&&!failed&&<button type="button" className="cctv-autoplay-retry" onClick={()=>void video.current?.play().catch(()=>setBlocked(true))}><Play size={20}/>Start preview</button>}
      {failed&&<div className="cctv-playback-error" role="status">Recording unavailable. Please refresh this page.</div>}
    </div>
    <div className="cctv-sample-content"><h2>{recording.title}</h2><p>{recording.location}</p><p>Archival flood footage · muted, automatic replay</p><div className="cctv-source-row"><a href={recording.sourceUrl} target="_blank" rel="noopener noreferrer">Source: {recording.author}</a><a href={recording.licenseUrl} target="_blank" rel="noopener noreferrer">{recording.license}</a></div></div>
  </article>;
}
