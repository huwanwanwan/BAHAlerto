import { jsPDF } from "jspdf";
import { autoTable } from "jspdf-autotable";
import type { RecordRow } from "./modules";

export function reportsPdf(rows: RecordRow[], scope: string) {
  const doc = new jsPDF({orientation:"landscape"});
  doc.setFillColor(7,92,56); doc.rect(0,0,297,30,"F");
  doc.setTextColor(255);doc.setFontSize(20);doc.text("BAHAlerto | Flood Reports",14,14);
  doc.setFontSize(10);doc.text(`${rows.length} reports | Philippine time`,14,23);
  doc.setTextColor(70);doc.setFontSize(9);doc.text(doc.splitTextToSize(scope,265),14,39);
  const time = (value: unknown) => value && Number.isFinite(Date.parse(String(value))) ? new Date(String(value)).toLocaleString("en-PH",{timeZone:"Asia/Manila"}) : "Not recorded";
  autoTable(doc,{
    startY:52,margin:{top:16,bottom:16,left:14,right:14},
    head:[["Location","Depth (cm)","Status","Observed (PH)","Submitted (PH)","Description","Review reason"]],
    body:rows.map(row=>[String(row.road_name ?? "Location unavailable"),String(row.depth_cm ?? "Unknown"),String(row.status ?? "Unknown"),time(row.observed_at),time(row.created_at),String(row.description ?? ""),String(row.review_reason ?? "")]),
    styles:{fontSize:8,cellPadding:3,overflow:"linebreak"},headStyles:{fillColor:[7,132,67]},alternateRowStyles:{fillColor:[241,248,244]},
    didDrawPage: data => {doc.setFontSize(8);doc.setTextColor(100);doc.text(`BAHAlerto - ${data.pageNumber}`,14,doc.internal.pageSize.height-8);},
  });
  return doc;
}
