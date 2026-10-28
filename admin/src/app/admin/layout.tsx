import { administrator } from "@/lib/auth";
import { configured } from "@/lib/supabase";
import { Shell } from "@/components/shell";
export const dynamic = "force-dynamic";
export default async function Layout({
  children,
}: {
  children: React.ReactNode;
}) {
  const admin = await administrator();
  return (
    <Shell email={admin?.email ?? "Setup preview"} connected={configured()}>
      {children}
    </Shell>
  );
}
