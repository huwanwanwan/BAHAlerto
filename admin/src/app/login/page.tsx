import Link from "next/link";
import Image from "next/image";
import { LoginForm } from "@/components/login-form";
import { configured } from "@/lib/supabase";

const floodCards = [
  // Column 1
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
  // Column 2
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
  // Column 3
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
  // Column 4
  [
    {
      src: "/flood-photos/ph-flood-6.jpg",
      alt: "Rescue operations",
      title: "Civil Defense Operations",
    },
    {
      src: "/flood-photos/ph-flood-1.jpg",
      alt: "Water level gauge",
      title: "River Crest Warning",
    },
    {
      src: "/flood-photos/ph-flood-5.jpg",
      alt: "Evacuation transport",
      title: "Evacuation Support",
    },
  ],
];

export default function Login() {
  return (
    <main className="login-portal">
      {/* Tilted / Slanted Philippine Flood Photo Card Collage (matching video template) */}
      <div className="flood-collage-backdrop" aria-hidden="true">
        <div className="flood-collage-grid">
          {floodCards.map((col, colIdx) => (
            <div key={colIdx} className={`flood-collage-col col-${colIdx}`}>
              {[...col, ...col].map((card, cardIdx) => (
                <div key={cardIdx} className="flood-photo-card">
                  <Image
                    src={card.src}
                    alt={card.alt}
                    fill
                    sizes="250px"
                    className="flood-photo-img"
                  />
                  <div className="flood-card-overlay">
                    <span className="flood-card-pill">{card.title}</span>
                  </div>
                </div>
              ))}
            </div>
          ))}
        </div>
      </div>

      {/* Gentle gradient veil so the login card has high contrast and zero eye strain */}
      <div className="flood-collage-veil" aria-hidden="true" />

      {/* Centered Login Card */}
      <div className="login-frame">
        <section className="portal-card" aria-labelledby="login-title">
          <div className="portal-brand portal-artwork">
            <Image
              src="/login-logov3-centered.png"
              alt="BAHAlerto Admin - flood awareness landscape"
              fill
              sizes="(max-width: 740px) 100vw, 378px"
              priority
            />
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
