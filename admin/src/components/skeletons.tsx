import { Skeleton } from "@/components/ui/skeleton";

export function HeadingSkeleton({ hasAction = true }: { hasAction?: boolean }) {
  return (
    <div className="page-heading skeleton-heading-wrap" aria-hidden="true">
      <div className="skeleton-heading-content">
        <Skeleton variant="text" className="w-40 h-3.5 mb-2" />
        <Skeleton variant="rounded" className="w-72 h-9 mb-2" />
        <Skeleton variant="text" className="w-96 max-w-full h-4" />
      </div>
      {hasAction && (
        <Skeleton variant="rounded" className="w-36 h-10 shrink-0" />
      )}
    </div>
  );
}

export function StatsGridSkeleton({ count = 4 }: { count?: number }) {
  return (
    <div className="stats-grid skeleton-stats-grid" aria-hidden="true">
      {Array.from({ length: count }).map((_, i) => (
        <div className="stat skeleton-stat-card" key={i}>
          <div className="skeleton-stat-header">
            <Skeleton variant="text" className="w-28 h-4" />
            <Skeleton variant="rounded" className="w-9 h-9" />
          </div>
          <Skeleton variant="rounded" className="w-24 h-10 my-3" />
          <Skeleton variant="text" className="w-44 max-w-full h-3.5" />
        </div>
      ))}
    </div>
  );
}

export function TableRowsSkeleton({
  rows = 5,
  columns = 4,
}: {
  rows?: number;
  columns?: number;
}) {
  const columnWidths = ["w-3/5", "w-4/5", "w-2/5", "w-1/2", "w-3/4"];
  return (
    <>
      {Array.from({ length: rows }).map((_, r) => (
        <tr key={r} className="skeleton-table-row">
          {Array.from({ length: columns }).map((__, c) => (
            <td key={c} className={c === columns - 1 ? "table-action-col" : undefined}>
              {c === columns - 1 ? (
                <Skeleton variant="rounded" className="w-16 h-8" />
              ) : (
                <Skeleton
                  variant="text"
                  className={`${columnWidths[(r + c) % columnWidths.length]} h-4`}
                />
              )}
            </td>
          ))}
        </tr>
      ))}
    </>
  );
}

export function TableModuleSkeleton({
  title = "Module Records",
  columns = 5,
  rows = 6,
}: {
  title?: string;
  columns?: number;
  rows?: number;
}) {
  return (
    <div className="skeleton-page-container" aria-label={`Loading ${title}`}>
      <HeadingSkeleton hasAction />
      <section className="panel skeleton-panel">
        <div className="panel-heading">
          <div>
            <Skeleton variant="rounded" className="w-48 h-6 mb-2" />
            <Skeleton variant="text" className="w-32 h-3.5" />
          </div>
        </div>

        <div className="table-tools skeleton-tools">
          <Skeleton variant="rounded" className="w-64 h-10 max-w-full" />
          <Skeleton variant="rounded" className="w-36 h-10" />
          <Skeleton variant="rounded" className="w-32 h-10 ml-auto" />
        </div>

        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                {Array.from({ length: columns }).map((_, i) => (
                  <th key={i} className={i === columns - 1 ? "table-action-col" : undefined}>
                    <Skeleton variant="text" className="w-20 h-3.5" />
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              <TableRowsSkeleton rows={rows} columns={columns} />
            </tbody>
          </table>
        </div>

        <div className="pagination skeleton-pagination">
          <Skeleton variant="text" className="w-44 h-4" />
          <div className="flex gap-2 items-center">
            <Skeleton variant="rounded" className="w-8 h-8" />
            <Skeleton variant="text" className="w-12 h-4" />
            <Skeleton variant="rounded" className="w-8 h-8" />
          </div>
        </div>
      </section>
    </div>
  );
}

export function DashboardSkeleton() {
  return (
    <div
      className="skeleton-page-container skeleton-dashboard"
      aria-label="Loading BAHAlerto administrator dashboard"
    >
      <HeadingSkeleton hasAction={false} />

      {/* 4 Stats Cards */}
      <StatsGridSkeleton count={4} />

      {/* Dashboard Grid: CCTV Overview + Map */}
      <div className="dashboard-grid">
        {/* CCTV Overview matching real layout */}
        <section className="panel cctv-panel" aria-hidden="true">
          <div className="panel-heading">
            <div>
              <Skeleton variant="rounded" className="w-36 h-6 mb-1.5" />
              <Skeleton variant="text" className="w-56 h-3.5" />
            </div>
            <Skeleton variant="rounded" className="w-32 h-9" />
          </div>
          <div className="cctv-empty">
            <div className="cctv-screen">
              <Skeleton variant="rounded" className="w-10 h-10 mb-2" />
              <Skeleton variant="text" className="w-24 h-3.5" />
              <div className="cctv-corner top-left" />
              <div className="cctv-corner bottom-right" />
            </div>
            <div className="cctv-description">
              <Skeleton variant="text" className="w-28 h-3 mb-2" />
              <Skeleton variant="rounded" className="w-44 h-5 mb-2" />
              <Skeleton variant="text" className="w-full h-3 mb-1.5" />
              <Skeleton variant="text" className="w-4/5 h-3" />
            </div>
          </div>
        </section>

        {/* Map Preview matching real layout */}
        <section className="panel skeleton-panel" aria-hidden="true">
          <div className="panel-heading">
            <div>
              <Skeleton variant="rounded" className="w-40 h-6 mb-1.5" />
              <Skeleton variant="text" className="w-60 h-3.5" />
            </div>
            <Skeleton variant="circular" className="w-6 h-6" />
          </div>
          <div className="map-card skeleton-map-card">
            <div className="map-label">
              <Skeleton variant="text" className="w-52 h-3.5 mx-auto" />
            </div>
          </div>
        </section>
      </div>

      {/* Monitoring Grid: Recent Reports + Activity Chart */}
      <div className="dashboard-monitoring-grid">
        <section className="panel skeleton-panel" aria-hidden="true">
          <div className="panel-heading">
            <div>
              <Skeleton variant="rounded" className="w-44 h-6 mb-1.5" />
              <Skeleton variant="text" className="w-72 h-3.5" />
            </div>
            <Skeleton variant="text" className="w-24 h-4" />
          </div>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>
                    <Skeleton variant="text" className="w-24 h-3.5" />
                  </th>
                  <th>
                    <Skeleton variant="text" className="w-16 h-3.5" />
                  </th>
                  <th>
                    <Skeleton variant="text" className="w-20 h-3.5" />
                  </th>
                  <th className="table-action-col">
                    <Skeleton variant="text" className="w-16 h-3.5" />
                  </th>
                </tr>
              </thead>
              <tbody>
                <TableRowsSkeleton rows={5} columns={4} />
              </tbody>
            </table>
          </div>
        </section>

        <section className="panel skeleton-panel" aria-hidden="true">
          <div className="panel-heading">
            <div>
              <Skeleton variant="rounded" className="w-52 h-6 mb-1.5" />
              <Skeleton variant="text" className="w-60 h-3.5" />
            </div>
            <Skeleton variant="pill" className="w-32 h-6" />
          </div>
          <div className="skeleton-chart-box">
            <div className="skeleton-chart-bars">
              {[45, 75, 30, 90, 60, 85, 40, 70, 95, 55].map((h, i) => (
                <div
                  key={i}
                  className="skeleton-chart-bar"
                  style={{ height: `${h}%` }}
                />
              ))}
            </div>
            <div className="skeleton-chart-axis">
              <Skeleton variant="text" className="w-full h-3 mt-4" />
            </div>
          </div>
        </section>
      </div>
    </div>
  );
}

export function RecordDetailSkeleton({
  title = "Record details",
}: {
  title?: string;
}) {
  return (
    <div
      className="skeleton-page-container"
      aria-label={`Loading ${title}`}
    >
      <Skeleton variant="text" className="w-32 h-4 mb-4" />
      <div className="page-heading">
        <div>
          <Skeleton variant="text" className="w-28 h-3.5 mb-2" />
          <Skeleton variant="rounded" className="w-64 h-9 mb-2" />
          <Skeleton variant="text" className="w-80 h-4" />
        </div>
        <Skeleton variant="pill" className="w-24 h-7" />
      </div>

      <div className="dashboard-grid">
        <section className="panel skeleton-panel">
          <Skeleton variant="rounded" className="w-44 h-6 mb-5" />
          <div className="skeleton-definition-list">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="skeleton-dl-row">
                <Skeleton variant="text" className="w-28 h-3.5 mb-1" />
                <Skeleton variant="text" className="w-56 max-w-full h-4 mb-3" />
              </div>
            ))}
          </div>
          <Skeleton variant="rounded" className="w-full h-56 mt-4" />
        </section>

        <section className="panel skeleton-panel">
          <Skeleton variant="rounded" className="w-36 h-6 mb-4" />
          <Skeleton variant="rounded" className="w-full h-24 mb-4" />
          <Skeleton variant="rounded" className="w-full h-11 mb-3" />
          <Skeleton variant="rounded" className="w-full h-11" />
        </section>
      </div>
    </div>
  );
}

export function CctvSkeleton() {
  return (
    <div
      className="skeleton-page-container"
      aria-label="Loading CCTV camera monitoring views"
    >
      <HeadingSkeleton hasAction={false} />
      <section className="panel cctv-panel" aria-hidden="true">
        <div className="panel-heading">
          <div>
            <Skeleton variant="rounded" className="w-36 h-6 mb-1.5" />
            <Skeleton variant="text" className="w-56 h-3.5" />
          </div>
          <Skeleton variant="pill" className="w-28 h-6" />
        </div>
        <div className="cctv-empty">
          <div className="cctv-screen">
            <Skeleton variant="rounded" className="w-12 h-12 mb-2" />
            <Skeleton variant="text" className="w-28 h-3.5" />
            <div className="cctv-corner top-left" />
            <div className="cctv-corner bottom-right" />
          </div>
          <div className="cctv-description">
            <Skeleton variant="text" className="w-32 h-3 mb-2" />
            <Skeleton variant="rounded" className="w-48 h-6 mb-2" />
            <Skeleton variant="text" className="w-full h-3.5 mb-1.5" />
            <Skeleton variant="text" className="w-4/5 h-3.5" />
          </div>
        </div>
      </section>
    </div>
  );
}
