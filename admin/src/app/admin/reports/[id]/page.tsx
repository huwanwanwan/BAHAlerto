import { notFound } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import { administrator } from "@/lib/auth";
import { database, configured } from "@/lib/supabase";
import { display } from "@/lib/modules";
import { ReviewForm } from "@/components/review-form";
import { LocationMap } from "@/components/location-map";
export default async function Report({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  await administrator("reports");
  if (!configured()) notFound();
  const { id } = await params;
  if (!/^[a-f0-9-]{36}$/i.test(id)) notFound();
  const db = await database();
  const { data: report, error } = await db
    .from("flood_reports")
    .select("*")
    .eq("id", id)
    .single();
  if (error || !report) notFound();
  let photo: string | undefined;
  if (report.photo_path) {
    const { data } = await db.storage
      .from("flood-photos")
      .createSignedUrl(report.photo_path, 120);
    photo = data?.signedUrl;
  }
  const { data: road } = await db
    .from("road_locations")
    .select("name,locality")
    .eq("id", report.road_id)
    .single();
  return (
    <>
      <Link href="/admin/reports" className="text-link">
        ? All flood reports
      </Link>
      <div className="page-heading">
        <div>
          <span className="eyebrow">REPORT REVIEW</span>
          <h1>{road?.name ?? "Reported location"}</h1>
          <p>
            {id} / {road?.locality ?? ""}
          </p>
        </div>
        <span className={"badge " + report.status}>{report.status}</span>
      </div>
      <div className="dashboard-grid">
        <section className="panel">
          <h2>Observation details</h2>
          <dl>
            {Object.entries(report)
              .filter(([key]) => key !== "photo_path")
              .map(([key, value]) => (
                <div key={key}>
                  <dt>{key.replaceAll("_", " ")}</dt>
                  <dd>{display(value)}</dd>
                </div>
              ))}
          </dl>
          {photo ? (
            <>
              <Image
                src={photo}
                alt="Submitted flood observation photograph"
                width={800}
                height={500}
                unoptimized
                className="report-photo"
              />
              <a href={photo} target="_blank" rel="noreferrer">
                Open private report photo (expires in 2 minutes)
              </a>
            </>
          ) : (
            <p>No accessible photo supplied.</p>
          )}
          <LocationMap
            points={[
              {
                id,
                name: road?.name ?? id,
                latitude: Number(report.latitude),
                longitude: Number(report.longitude),
                status: report.status,
              },
            ]}
          />
        </section>
        <section className="panel">
          <h2>Review decision</h2>
          <ReviewForm
            id={id}
            disabled={!["pending", "clarification"].includes(report.status)}
          />
        </section>
      </div>
    </>
  );
}
