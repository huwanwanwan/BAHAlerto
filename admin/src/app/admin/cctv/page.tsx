import { administrator } from "@/lib/auth";
import { CctvOverview } from "@/components/cctv-overview";
export default async function CctvPage() {
  await administrator("dashboard");
  return (
    <>
      <div className="page-heading">
        <div>
          <span className="eyebrow">BAHALERTO WORKSPACE</span>
          <h1>Manage CCTV</h1>
          <p>Camera views for supported monitoring locations.</p>
        </div>
      </div>
      <CctvOverview fullPage />
    </>
  );
}
