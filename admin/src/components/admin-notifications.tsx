"use client";
import { useCallback, useEffect, useRef, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Bell, CheckCheck, RefreshCw } from "lucide-react";
import { loadNotifications, markNotificationsRead } from "@/app/notification-actions";

type NotificationData = Awaited<ReturnType<typeof loadNotifications>>;
export function AdminNotifications({ connected, onRegistrationCountChange }: { connected: boolean; onRegistrationCountChange: (count: number) => void }) {
  const [data, setData] = useState<NotificationData | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [marking, setMarking] = useState(false);
  const busy = useRef(false);
  const latest = useRef<string | null>(null);
  const router = useRouter();
  const refresh = useCallback(async () => {
    if (!connected || busy.current) return;
    busy.current = true;
    try {
      const result = await loadNotifications();
      setData(result); setError(result.error);
      if (!result.error) onRegistrationCountChange(result.registrations);
      const newest = result.items[0]?.id ?? "";
      if (latest.current !== null && newest !== latest.current && !result.error) router.refresh();
      latest.current = newest;
    } catch { setError("Could not load notifications. Please retry."); }
    finally { busy.current = false; }
  }, [connected, router, onRegistrationCountChange]);
  useEffect(() => {
    const tick = () => { if (!document.hidden) void refresh(); };
    tick();
    const timer = window.setInterval(tick, 30000);
    window.addEventListener("focus", tick);
    return () => { window.clearInterval(timer); window.removeEventListener("focus", tick); };
  }, [refresh]);
  const unread = data?.unread ?? 0;
  async function markVisible() {
    if (!data || marking) return;
    setMarking(true);
    try { await markNotificationsRead(data.items.filter(item => !item.read_at).map(item => item.id)); await refresh(); }
    catch { setError("Could not mark notifications as read. Please retry."); }
    finally { setMarking(false); }
  }
  return <details className="admin-notifications" onToggle={event => { if (event.currentTarget.open) void refresh(); }}
    onKeyDown={event => { if (event.key === "Escape") { event.currentTarget.open = false; event.currentTarget.querySelector("summary")?.focus(); } }}>
    <summary className="icon-button notification-bell" aria-label={`Notifications${unread ? `, ${unread} unread` : ""}`}>
      <Bell size={21} />
      {unread > 0 && <span className="notification-count" aria-hidden="true">{unread > 99 ? "99+" : unread}</span>}
    </summary>
    <section className="notification-panel" aria-label="Notifications">
      <div className="notification-heading"><h2>Notifications</h2><button type="button" className="icon-button" aria-label="Refresh notifications" onClick={() => void refresh()}><RefreshCw size={17}/></button></div>
      {!connected ? <p>Connect Supabase to receive notifications.</p> : error ? <p role="alert">{error}</p> : !data ? <p>Loading notifications?</p> : <>
        {data.items.some(item => !item.read_at) && <button type="button" className="notification-read" onClick={() => void markVisible()} disabled={marking}><CheckCheck size={16}/>{marking ? "Saving?" : "Mark shown as read"}</button>}
        {data.items.length === 0 ? <p>No notifications yet.</p> : <ul>{data.items.map(item => <li key={item.id} className={!item.read_at ? "notification-unread" : ""}>
          <Link href={item.href}><span>{item.title}</span><time dateTime={item.created_at}>{new Date(item.created_at).toLocaleString("en-PH", { timeZone: "Asia/Manila" })}</time>{!item.read_at && <span className="notification-dot" aria-label="Unread"/>}</Link>
        </li>)}</ul>}
      </>}
    </section>
  </details>;
}
