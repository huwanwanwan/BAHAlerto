"use client";
import { useEffect, useRef, useState } from "react";
import * as maplibregl from "maplibre-gl";
import "maplibre-gl/dist/maplibre-gl.css";

export type MapPoint = {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  status: string;
};

export function LocationMap({ points }: { points: MapPoint[] }) {
  const ref = useRef<HTMLDivElement>(null);
  const [error, setError] = useState(false);

  useEffect(() => {
    if (!ref.current) return;

    let map: maplibregl.Map | undefined;
    try {
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
          },
          layers: [{ id: "osm", type: "raster", source: "osm" }],
        },
        center: [120.9572, 14.7578],
        zoom: 11,
      });

      map.addControl(new maplibregl.NavigationControl(), "top-right");

      // Only trigger error on fatal WebGL loss, not transient tile cancellations
      map.on("webglcontextlost", () => {
        setError(true);
      });

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
        new maplibregl.Marker({
          color:
            point.status === "verified" || point.status === "published"
              ? "#078443"
              : "#d88a20",
        })
          .setLngLat([point.longitude, point.latitude])
          .setPopup(
            new maplibregl.Popup({ offset: 25 }).setText(
              point.name + " / " + point.status,
            ),
          )
          .addTo(map!);
      });

      // Auto-fit to point(s)
      if (validPoints.length === 1) {
        map.setCenter([validPoints[0].longitude, validPoints[0].latitude]);
        map.setZoom(13);
      } else if (validPoints.length > 1) {
        const bounds = new maplibregl.LngLatBounds();
        validPoints.forEach((p) => bounds.extend([p.longitude, p.latitude]));
        map.fitBounds(bounds, { padding: 50, maxZoom: 14 });
      }
    } catch {
      setError(true);
    }

    return () => {
      map?.remove();
    };
  }, [points]);

  return (
    <div className="map-card">
      <div
        className="map"
        ref={ref}
        aria-label="Road and report locations map"
      />
      {!points.length && (
        <div className="map-label">
          No report markers available. Base map only.
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
