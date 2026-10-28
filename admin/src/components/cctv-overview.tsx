import Link from "next/link";
import { Cctv, VideoOff, ArrowUpRight } from "lucide-react";

export function CctvOverview({ fullPage = false }: { fullPage?: boolean }) {
  return (
    <section className="panel cctv-panel" aria-labelledby="cctv-heading">
      <div className="panel-heading">
        <div>
          <h2 id="cctv-heading">
            {fullPage ? "Camera views" : "CCTV overview"}
          </h2>
          <p>Visual monitoring at supported locations</p>
        </div>
        {fullPage ? (
          <span className="badge">Not configured</span>
        ) : (
          <Link className="button outline" href="/admin/cctv">
            <Cctv size={16} />
            View cameras
            <ArrowUpRight size={15} />
          </Link>
        )}
      </div>
      <div className="cctv-empty">
        <div className="cctv-screen">
          <VideoOff size={38} strokeWidth={1.3} />
          <span>No camera feed</span>
          <div className="cctv-corner top-left" />
          <div className="cctv-corner bottom-right" />
        </div>
        <div className="cctv-description">
          <span className="eyebrow">CCTV MONITORING</span>
          <h3>No cameras connected</h3>
          <p>
            Camera views will appear here once authorized CCTV sources are
            configured. No live footage or camera status is available yet.
          </p>
        </div>
      </div>
    </section>
  );
}
