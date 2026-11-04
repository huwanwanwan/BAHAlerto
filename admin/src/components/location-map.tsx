"use client";
import { useEffect, useRef, useState } from "react";
import * as maplibregl from "maplibre-gl";
import "maplibre-gl/dist/maplibre-gl.css";
import { StreetViewDialog } from "./street-view-dialog";

export type MapPoint = {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  status: string;
  markerColor?: string;
  description?: string;
};

export function LocationMap({ points }: { points: MapPoint[] }) {
  const ref = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const fittedLocations = useRef("");
  const [satellite, setSatellite] = useState(true);
  const [streetViewPoint, setStreetViewPoint] = useState({latitude:14.7578,longitude:120.9572});
  const [streetViewLocation, setStreetViewLocation] = useState<{latitude:number;longitude:number} | null>(null);
  const [error, setError] = useState(false);

  useEffect(() => {
    if (!ref.current) return;

    let map: maplibregl.Map | undefined;
    let failureFrame = 0;
    try {
      maplibregl.setWorkerUrl(`/maplibre/maplibre-gl-worker.mjs?v=${maplibregl.getVersion()}`);
      map = new maplibregl.Map({
        container: ref.current,
        style: {
          version: 8,
          sources: {
            osm: {
              type: "raster",
              tiles: ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],
              tileSize: 256,
              attribution: "(c) OpenStreetMap contributors | MapLibre",
            },
            imagery: {type:"raster", tiles:["https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"],tileSize:256,maxzoom:19,attribution:"Esri, Vantor, Earthstar Geographics, GIS User Community"},
            roads: {type:"raster",tiles:["https://services.arcgisonline.com/ArcGIS/rest/services/Reference/World_Transportation/MapServer/tile/{z}/{y}/{x}"],tileSize:256,maxzoom:19,attribution:"Esri, HERE, Garmin, © OpenStreetMap contributors"},
            places: {type:"raster",tiles:["https://services.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}"],tileSize:256,maxzoom:19},
          },
          layers: [
            {id:"osm",type:"raster",source:"osm",layout:{visibility:"none"}},
            {id:"imagery",type:"raster",source:"imagery"},
            {id:"roads",type:"raster",source:"roads"},
            {id:"places",type:"raster",source:"places"},
          ],
        },
        center: [120.9572, 14.7578],
        zoom: 13,
        maxZoom:19,
      });

      map.addControl(new maplibregl.NavigationControl(), "top-right");
      map.addControl(new maplibregl.FullscreenControl(), "top-right");
      mapRef.current = map;
      map.on("moveend", () => {
        const center = map!.getCenter();
        setStreetViewPoint({latitude:center.lat,longitude:center.lng});
      });

      // Only trigger error on fatal WebGL loss, not transient tile cancellations
      map.on("webglcontextlost", () => {
        setError(true);
      });

    } catch {
      failureFrame = requestAnimationFrame(() => setError(true));
    }
    const observer = new ResizeObserver(() => map?.resize());
    if (ref.current) observer.observe(ref.current);
    return () => { cancelAnimationFrame(failureFrame); observer.disconnect(); map?.remove(); mapRef.current = null; };
  }, []);

  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;
    const markers: maplibregl.Marker[] = [];
    const validPoints = points.filter(
        (p) =>
          Number.isFinite(p.latitude) &&
          Number.isFinite(p.longitude) &&
          p.latitude >= -90 &&
          p.latitude <= 90 &&
          p.longitude >= -180 &&
          p.longitude <= 180,
      );

      validPoints.forEach((point) => {
        const marker = new maplibregl.Marker({
          color: point.markerColor ?? (
            point.status === "verified" || point.status === "published"
              ? "#078443"
              : "#d88a20"),
        })
          .setLngLat([point.longitude, point.latitude])
          .setPopup(
            new maplibregl.Popup({ offset: 25 }).setText(
              point.description ?? point.name + " / " + point.status,
            ),
          )
          .addTo(map);
        marker.getElement().addEventListener("click", () => {
          map.easeTo({center:[point.longitude,point.latitude]});
          setStreetViewPoint({latitude:point.latitude,longitude:point.longitude});
        });
        markers.push(marker);
        marker.getElement().setAttribute("aria-label", point.description ?? `${point.name}: ${point.status}`);
      });

      const locationKey = validPoints.map(point => `${point.id}:${point.longitude}:${point.latitude}`).sort().join("|");
      if (locationKey !== fittedLocations.current && validPoints.length === 1) {
        map.setCenter([validPoints[0].longitude, validPoints[0].latitude]);
        map.setZoom(15);
      } else if (locationKey !== fittedLocations.current && validPoints.length > 1) {
        const bounds = new maplibregl.LngLatBounds();
        validPoints.forEach((p) => bounds.extend([p.longitude, p.latitude]));
        map.fitBounds(bounds, { padding: 50, maxZoom: 14 });
      }
      fittedLocations.current = locationKey;
    return () => { markers.forEach(marker => marker.remove()); };
  }, [points]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;
    const apply = () => {
      for (const id of ["imagery","roads","places"]) map.setLayoutProperty(id,"visibility",satellite ? "visible" : "none");
      map.setLayoutProperty("osm","visibility",satellite ? "none" : "visible");
    };
    if (map.isStyleLoaded()) apply(); else map.once("load", apply);
    return () => { map.off("load", apply); };
  }, [satellite]);

  return (
    <div className="map-card geographic-map">
      <div
        className="map"
        ref={ref}
        aria-label="Road and report locations map"
      />
      <div className="map-view-switch" role="group" aria-label="Map view">
        <button type="button" aria-pressed={satellite} onClick={() => setSatellite(true)}>Satellite</button>
        <button type="button" aria-pressed={!satellite} onClick={() => setSatellite(false)}>Streets</button>
      </div>
      <button type="button" className="map-street-view" onClick={() => setStreetViewLocation({...streetViewPoint})} title="Explore the map center in Street View">Street View</button>
      {streetViewLocation && <StreetViewDialog location={streetViewLocation} onClose={() => setStreetViewLocation(null)} />}
      {!points.length && (
        <div className="map-label">
          No matching locations available. Base map only.
        </div>
      )}
      {error && (
        <div className="map-label map-error">
          Map rendering unavailable in this browser. Use the location table below.
        </div>
      )}
    </div>
  );
}
