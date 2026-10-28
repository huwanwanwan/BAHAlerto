import Link from "next/link";
import Image from "next/image";
import { LoginForm } from "@/components/login-form";
import { configured } from "@/lib/supabase";

const floodColumns = [
  // Col 0 - River Gauges & Controls
  [
    {
      src: "/flood-photos/ph-flood-1.jpg",
      alt: "Marikina River critical water level monitoring",
      title: "Marikina River 18m Gauge",
    },
    {
      src: "/flood-photos/ph-flood-2.jpg",
      alt: "Pasig-Marikina flood control structure",
      title: "River Control Infrastructure",
    },
    {
      src: "/flood-photos/ph-flood-9.jpg",
      alt: "Tidal flooding in Marilao, Bulacan",
      title: "Marilao Road Inundation",
    },
  ],
  // Col 1 - Rescue & Civil Defense
  [
    {
      src: "/flood-photos/ph-flood-5.jpg",
      alt: "Disaster response and community rescue in Manila",
      title: "Disaster Rescue Response",
    },
    {
      src: "/flood-photos/ph-flood-6.jpg",
      alt: "Flood relief boat operations",
      title: "Waterborne Rescue Teams",
    },
    {
      src: "/flood-photos/ph-flood-7.jpg",
      alt: "Emergency relief assistance during flooding",
      title: "Emergency Medical Relief",
    },
  ],
  // Col 2 - Typhoon Inundation & Pumping Stations
  [
    {
      src: "/flood-photos/ph-flood-8.jpg",
      alt: "Typhoon flood in Central Luzon community",
      title: "Typhoon Flood Monitoring",
    },
    {
      src: "/flood-photos/ph-flood-3.jpg",
      alt: "Pasig River flood gate and control",
      title: "Flood Barrier Stations",
    },
    {
      src: "/flood-photos/ph-flood-4.jpg",
      alt: "River flood control channel",
      title: "Hydrological Monitoring",
    },
  ],
  // Col 3 - Bulacan & Pampanga Waterways
  [
    {
      src: "/flood-photos/ph-flood-9.jpg",
      alt: "Tidal flooding in Marilao, Bulacan",
      title: "MacArthur Highway Inundation",
    },
    {
      src: "/flood-photos/ph-flood-1.jpg",
      alt: "Marikina River monitoring station",
      title: "River Crest Warning",
    },
    {
      src: "/flood-photos/ph-flood-6.jpg",
      alt: "Civil defense flood rescue",
      title: "Civil Defense Operations",
    },
  ],
  // Col 4 - Waterways & Medical Relief
  [
    {
      src: "/flood-photos/ph-flood-2.jpg",
      alt: "Pasig-Marikina River Channel Esplanade",
      title: "Pasig Flood Control",
    },
    {
      src: "/flood-photos/ph-flood-7.jpg",
      alt: "Medical relief operations in Manila",
      title: "Community Relief Operations",
    },
    {
      src: "/flood-photos/ph-flood-8.jpg",
      alt: "Floodwaters in Central Luzon",
      title: "Pampanga Basin Floodway",
    },
  ],
  // Col 5 - Outer wide screen balance
  [
    {
      src: "/flood-photos/ph-flood-4.jpg",
      alt: "Flood channel improvement",
      title: "Floodway Channel Control",
    },
    {
      src: "/flood-photos/ph-flood-5.jpg",
      alt: "Resident evacuation during typhoon flood",
      title: "Evacuation Operations",
    },
    {
      src: "/flood-photos/ph-flood-3.jpg",
      alt: "River gate infrastructure",
      title: "Pumping Gate Controls",
    },
  ],
];

/*
 * Background collage geometry.
 * Each track must be taller than the (rotated) backdrop so a single track
 * always covers the visible area; the second identical track follows it,
 * and the animation moves exactly one track height (-100%) for a seamless loop.
 */
const COLUMN_COUNT = 14;
const CARDS_PER_TRACK = 12;
const allCards = floodColumns.flat();

const collageColumns = Array.from({ length: COLUMN_COUNT }, (_, colIdx) =>
  Array.from(
    { length: CARDS_PER_TRACK },
    (_, i) => allCards[(colIdx * 5 + i * 2) % allCards.length],
  ),
);

function FloodTrack({ cards }: { cards: (typeof allCards)[number][] }) {
  return (
    <div className="flood-track">
      {cards.map((card, cardIdx) => (
        <div key={cardIdx} className="flood-photo-card">
          <Image
            src={card.src}
            alt=""
            fill
            sizes="360px"
            loading="eager"
            className="flood-photo-img"
          />
        </div>
      ))}
    </div>
  );
}

export default function Login() {
  return (
    <main className="login-portal">
      {/* Tilted Philippine flood photo collage with seamless infinite scroll */}
      <div className="flood-collage-backdrop" aria-hidden="true">
        {collageColumns.map((cards, colIdx) => (
          <div
            key={colIdx}
            className={`flood-collage-col ${colIdx % 2 === 0 ? "dir-up" : "dir-down"}`}
            style={{ animationDuration: `${150 + (colIdx % 5) * 12}s` }}
          >
            <FloodTrack cards={cards} />
            <FloodTrack cards={cards} />
          </div>
        ))}
      </div>

      {/* Gentle center backlight veil so the login card has high contrast without obscuring the background */}
      <div className="flood-collage-veil" aria-hidden="true" />

      {/* Centered Login Card */}
      <div className="login-frame">
        <section className="portal-card" aria-labelledby="login-title">
          <div className="portal-brand portal-artwork">
            <Image
              src="/login-brand-generated.jpg"
              alt="BAHAlerto flood monitoring landscape"
              fill
              sizes="(max-width: 740px) 100vw, 378px"
              className="portal-artwork-bg"
              priority
            />
            <div className="portal-artwork-vignette" aria-hidden="true" />
            <div className="portal-brand-logo-wrap">
              <Image
                src="/admin-logo-transparent.png"
                alt="BAHAlerto Admin"
                width={290}
                height={240}
                className="portal-brand-logo-img"
                priority
              />
            </div>
          </div>
          <div className="portal-content">
            <h1 id="login-title">Login Portal</h1>
            <LoginForm />
            <p className="portal-recovery">
              Forgot your password?{" "}
              <Link href="/forgot-password">Reset it here</Link>
            </p>
          </div>
        </section>
        {!configured() && (
          <p className="portal-setup">
            Supabase is not connected.{" "}
            <Link href="/admin/dashboard">View setup preview</Link>
          </p>
        )}
      </div>
    </main>
  );
}
