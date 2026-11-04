"use client";
import Link from "next/link";
import Image from "next/image";
import { usePathname, useRouter } from "next/navigation";
import { useState, useRef, useLayoutEffect, useOptimistic, useTransition } from "react";
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
  PanelLeftClose,
  LogOut,
  ChevronRight,
} from "lucide-react";
import { modules } from "@/lib/modules";
import { AdminNotifications } from "./admin-notifications";
import { Skeleton } from "./ui/skeleton";
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
  const [newUsers, setNewUsers] = useState(0);
  const router = useRouter();
  const [selectedPath, selectPath] = useOptimistic(path);
  const [isNavigating, startNavigation] = useTransition();
  const switchingPage = selectedPath !== path;
  const selectedTitle = modules.find(module =>
    selectedPath === `/admin/${module.slug}` || selectedPath.startsWith(`/admin/${module.slug}/`),
  )?.title;
  const navigate = (href: string) => {
    startNavigation(() => {
      selectPath(href);
      router.push(href);
    });
  };
  const navigation = useRef<HTMLElement>(null);
  const pageContent = useRef<HTMLDivElement>(null);
  useLayoutEffect(() => {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const animation = pageContent.current?.animate(
      [
        { opacity: 0, transform: "translateY(6px)" },
        { opacity: 1, transform: "translateY(0)" },
      ],
      { duration: 220, easing: "cubic-bezier(0.2, 0.7, 0.2, 1)" },
    );
    return () => animation?.cancel();
  }, [path, selectedPath]);
  useLayoutEffect(() => {
    const nav = navigation.current;
    if (!nav) return;
    let frame = 0;
    const positionIndicator = () => {
      const active = nav.querySelector<HTMLElement>('a[data-selected="true"]');
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
  }, [selectedPath, collapsed]);
  return (
    <div className={collapsed ? "app collapsed" : "app"}>
      <aside id="workspace-sidebar">
        <Link
          href="/admin/dashboard"
          onNavigate={(event) => { event.preventDefault(); navigate("/admin/dashboard"); }}
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
            { label: "Community & Safety", slugs: ["users", "alerts", "emergency"] },
            { label: "Flood Monitoring", slugs: ["reports", "levels", "roads", "cctv"] },
            { label: "Administration", slugs: ["analytics", "settings"] },
          ].map(group => <section className="nav-section" key={group.label} aria-label={group.label}>
            <h2 className="nav-caption nav-label">{group.label}</h2>
            {group.slugs.map(slug => {
              const index = modules.findIndex(module => module.slug === slug);
              const item = modules[index];
              const Icon = icons[index];
              const href = `/admin/${slug}`;
              const active = selectedPath === href || selectedPath.startsWith(`${href}/`);
              const current = path === href || path.startsWith(`${href}/`);
              return <Link prefetch key={slug} title={item.title} href={href} onNavigate={(event) => { event.preventDefault(); navigate(href); }} className={active ? "active" : ""} data-selected={active} aria-current={current ? "page" : undefined}>
                <Icon size={21}/><span className="nav-label">{item.title}</span>
                {slug === "users" && newUsers > 0 && <span className="nav-unread-count" aria-label={`${newUsers} unread user registrations`}>{newUsers > 99 ? "99+" : newUsers}</span>}
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
            <span className="header-current-page" title={selectedTitle}>
              {selectedTitle}
            </span>
          </div>
          <div className="header-right">
            <AdminNotifications connected={connected} onRegistrationCountChange={setNewUsers} />
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
          {isNavigating && <div className="navigation-progress" role="status">Loading page…</div>}
          <div ref={pageContent} className="route-content" aria-busy={isNavigating}>
            {switchingPage && (
              <div className="skeleton-page-container">
                <div className="page-heading"><h1>{selectedTitle}</h1></div>
                <section className="panel" aria-label={`Loading ${selectedTitle ?? "page"}`}>
                  <Skeleton variant="text" className="w-48 h-6 mb-2" />
                  <Skeleton variant="rounded" className="w-full h-48" />
                </section>
              </div>
            )}
            <div hidden={switchingPage}>{children}</div>
          </div>
        </main>
        <footer>
          BAHAlerto | Administrator platform{" "}
          <span>Observation evidence matters. Follow official advisories.</span>
        </footer>
      </div>
    </div>
  );
}
