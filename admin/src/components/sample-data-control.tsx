"use client";
import { useActionState } from "react";
import { installSamples } from "@/app/sample-actions";
export function SampleDataControl({disabled=false}:{disabled?:boolean}) {
  const[state,action,pending]=useActionState(installSamples,{});
  return <section className="panel settings-samples"><h2>Sample locations</h2><p>Load 10 clearly labeled Marilao examples into the shared admin and mobile directory. The road coordinates are mapped; flood depths are simulated for demonstration.</p><form action={action}><button className="button" disabled={disabled||pending}>{pending?"Publishing samples…":"Load 10 sample locations"}</button></form>{state.error&&<p className="error-message" role="alert">{state.error}</p>}{state.success&&<p className="success-message" role="status">{state.success}</p>}<p className="flood-levels-help">Repeating this action updates the same samples. Examples are labeled SAMPLE ONLY and expire after seven days.</p></section>;
}
