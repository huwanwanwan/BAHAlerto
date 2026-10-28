import { HeadingSkeleton } from "@/components/skeletons";
import { Skeleton } from "@/components/ui/skeleton";

export default function AdminLoading() {
  return (
    <div className="skeleton-page-container" aria-label="Loading workspace">
      <HeadingSkeleton hasAction={false} />
      <section className="panel" aria-hidden="true">
        <div className="panel-heading">
          <div>
            <Skeleton variant="rounded" className="w-48 h-6 mb-2" />
            <Skeleton variant="text" className="w-32 h-3.5" />
          </div>
        </div>
        <Skeleton variant="rounded" className="w-full h-48" />
      </section>
    </div>
  );
}
