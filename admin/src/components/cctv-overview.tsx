import Link from "next/link";
import { Cctv, ArrowUpRight } from "lucide-react";
import { YoutubeCameraTile } from "./youtube-camera-tile";

export function CctvOverview({ fullPage = false }: { fullPage?: boolean }) {
  if (fullPage) return <><div className="cctv-sample-notice"><p>Your selected YouTube recording. This is sample footage, not a live camera feed.</p></div><div className="cctv-single-preview"><YoutubeCameraTile /></div></>;
  return (
    <section className="panel cctv-panel dashboard-linked-panel" aria-labelledby="cctv-heading">
      <div className="panel-heading">
        <div>
          <h2 id="cctv-heading">
            {fullPage ? "Camera views" : "CCTV overview"}
          </h2>
          <p>Sample camera preview · archival footage, not live</p>
        </div>
        {fullPage ? (
          <span className="badge">Not configured</span>
        ) : (
          <Link className="button outline dashboard-card-link" href="/admin/cctv">
            <Cctv size={16} />
            View cameras
            <ArrowUpRight size={15} />
          </Link>
        )}
      </div>
      <div className="dashboard-camera-preview">
        <YoutubeCameraTile />
      </div>
      <p className="sample-caption">Your selected YouTube video. Recorded footage, not a live camera.</p>
    </section>
  );
}
