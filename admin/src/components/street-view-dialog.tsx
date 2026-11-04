"use client";
import { useEffect, useRef, useState } from "react";
import { ArrowLeft } from "lucide-react";

export function StreetViewDialog({ location, onClose }: {
  location: { latitude: number; longitude: number }; onClose: () => void;
}) {
  const dialog = useRef<HTMLDialogElement>(null);
  const [loaded, setLoaded] = useState(false);
  const [failed, setFailed] = useState(false);
  const key = process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY;
  const url = key ? `https://www.google.com/maps/embed/v1/streetview?${new URLSearchParams({
    key, location: `${location.latitude},${location.longitude}`, language:"en",
  })}` : undefined;
  useEffect(() => { dialog.current?.showModal(); }, []);
  return <dialog ref={dialog} className="street-view-dialog" aria-labelledby="street-view-title" onClose={onClose}>
    <div className="street-view-heading">
      <h2 id="street-view-title">Street View</h2>
      <button type="button" onClick={onClose}><ArrowLeft size={16} />Back to map</button>
    </div>
    <div className="street-view-body">
      {!key ? <div className="street-view-message" role="status">
        <h3>Street View needs to be connected</h3>
        <p>Add a Google Maps Embed API key to enable ground-level viewing here.</p>
        <p className="street-view-setup">Set NEXT_PUBLIC_GOOGLE_MAPS_API_KEY in the admin environment, enable Maps Embed API, then restart the admin server.</p>
      </div> : <>
        {!loaded && !failed && <p className="street-view-loading" role="status">Loading Street View…</p>}
        {failed && <div className="street-view-message" role="alert"><h3>Street View could not load</h3><p>Check your connection and the Google Maps API configuration, then close and reopen this viewer.</p></div>}
        <iframe title="Google Street View" src={url} allowFullScreen referrerPolicy="strict-origin-when-cross-origin" onLoad={() => setLoaded(true)} onError={() => setFailed(true)} hidden={failed} />
      </>}
    </div>
    <p className="street-view-caption">Use the arrows in the panorama to move along roads where Street View coverage is available.</p>
  </dialog>;
}
