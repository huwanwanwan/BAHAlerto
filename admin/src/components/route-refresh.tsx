"use client";
import { useEffect, useTransition } from "react";
import { useRouter } from "next/navigation";

export function RouteRefresh() {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  useEffect(() => {
    const refresh = () => {
      if (pending || document.hidden || document.querySelector("dialog[open]") ||
        document.activeElement?.matches("input,textarea,select,[contenteditable=true]")) return;
      startTransition(() => router.refresh());
    };
    const timer = window.setInterval(refresh, 15000);
    window.addEventListener("focus", refresh);
    return () => { window.clearInterval(timer); window.removeEventListener("focus", refresh); };
  }, [router, pending]);
  return null;
}
