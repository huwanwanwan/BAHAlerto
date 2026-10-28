"use client";
import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { useState, useRef, useLayoutEffect } from "react";
import {
  LayoutDashboard,
  ClipboardList,
  Cctv,
  Waves,
  Map,
  TriangleAlert,
  Users,
  HeartPulse,
  ChartNoAxesCombined,
  Settings,
  Bell,
  PanelLeftClose,
  LogOut,
  ChevronRight,
} from "lucide-react";
import { modules } from "@/lib/modules";
import { logout } from "@/app/actions";
const icons = [
  LayoutDashboard,
  ClipboardList,
  Waves,
  Map,
  TriangleAlert,
  Cctv,
  Users,
  HeartPulse,
  ChartNoAxesCombined,
  Settings,
];
export function Shell({
  children,
  email,
  connected,
}: {
  children: React.ReactNode;
  email: string | undefined;
  connected: boolean;
}) {
  const path = usePathname(),
    [collapsed, setCollapsed] = useState(false);
  const navigation = useRef<HTMLElement>(null);
  useLayoutEffect(() => {
    const nav = navigation.current;
    if (!nav) return;
    let frame = 0;
    const positionIndicator = () => {
      const active = nav.querySelector<HTMLElement>('a[aria-current="page"]');
      if (!active) { delete nav.dataset.indicatorReady; return; }
      const box = active.getBoundingClientRect();
      const container = nav.getBoundingClientRect();
      nav.style.setProperty('--active-y', `${box.top - container.top}px`);
      nav.style.setProperty('--active-height', `${box.height}px`);
      nav.dataset.indicatorReady = 'true';
      frame = requestAnimationFrame(() => { nav.dataset.indicatorMotion = 'true'; });
    };
    positionIndicator();
    const observer = new ResizeObserver(positionIndicator);
    observer.observe(nav);
    return () => { observer.disconnect(); cancelAnimationFrame(frame); };
  }, [path, collapsed]);
  return (
    <div className={collapsed ? "app collapsed" : "app"}>
      <aside id="workspace-sidebar">
        <Link
          href="/admin/dashboard"
          className="brand brand-assets"
          aria-label="BAHAlerto dashboard"
        >
          <Image
            className="brand-expanded"
            src="/admin-logo-transparent.png"
            alt="BAHAlerto Admin"
            width={1381}
            height={1139}
            priority
          />
          <Image
            className="brand-collapsed"
            src="/admin-logo-collapse-transparent.png"
            alt="BAHAlerto"
            width={1254}
            height={1254}
            priority
          />
        </Link>
        <nav ref={navigation} aria-label="Main navigation">
          <span className="sidebar-active-indicator" aria-hidden="true"/>
          {[
            { label: "Workspace", slugs: ["dashboard"] },
            { label: "Flood Monitoring", slugs: ["reports", "levels", "roads", "cctv"] },
            { label: "Community & Safety", slugs: ["alerts", "users", "emergency"] },
            { label: "Administration", slugs: ["analytics", "settings"] },
          ].map(group => <section className="nav-section" key={group.label} aria-label={group.label}>
            <h2 className="nav-caption nav-label">{group.label}</h2>
            {group.slugs.map(slug => {
              const index = modules.findIndex(module => module.slug === slug);
              const item = modules[index];
              const Icon = icons[index];
              const active = path === `/admin/${slug}` || path.startsWith(`/admin/${slug}/`);
              return <Link prefetch key={slug} title={item.title} href={`/admin/${slug}`} className={active ? "active" : ""} aria-current={active ? "page" : undefined}>
                <Icon size={21}/><span className="nav-label">{item.title}</span>
              </Link>;
            })}
          </section>)}
        </nav>
        <div className="sidebar-foot sidebar-logout">
          <form action={logout}>
            <button type="submit" title="Log out" aria-label="Log out">
              <LogOut size={21} /><span className="nav-label">Log Out</span>
            </button>
          </form>
        </div>
      </aside>
      <div className="workspace">
        <header>
          <button
            className="icon-button"
            aria-label="Toggle sidebar"
            aria-expanded={!collapsed}
            aria-controls="workspace-sidebar"
            onClick={() => setCollapsed(!collapsed)}
          >
            <PanelLeftClose size={20} />
          </button>
          <div className="header-location" aria-label="Current page">
            <span className="header-brand-title">BAHAlerto</span>
            <ChevronRight className="header-page-arrow" size={20} aria-hidden="true" />
            <span className="header-current-page" title={modules.find(m => path === `/admin/${m.slug}` || path.startsWith(`/admin/${m.slug}/`))?.title}>
              {modules.find(m => path === `/admin/${m.slug}` || path.startsWith(`/admin/${m.slug}/`))?.title}
            </span>
          </div>
          <div className="header-right">
            <Link
              className="icon-button"
              aria-label="Advisories"
              href="/admin/alerts"
            >
              <Bell size={20} />
            </Link>
            <Link href="/admin/settings" className="avatar" aria-label="Account settings" title={email ?? "Account settings"}>BA</Link>
          </div>
        </header>
        <main>
          {!connected && (
            <div className="setup-banner">
              <TriangleAlert size={18} />
              <span>
                <strong>Database not connected.</strong> This is an empty setup
                preview. No reports, statistics or administrator session are
                simulated. Connect Supabase to enable management.
              </span>
              <Link href="/admin/settings">
                Setup details <ChevronRight size={16} />
              </Link>
            </div>
          )}
          {children}
        </main>
        <footer>
          BAHAlerto | Administrator platform{" "}
          <span>Observation evidence matters. Follow official advisories.</span>
        </footer>
      </div>
    </div>
  );
}
