import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = {
  title: "BAHAlerto | Administration",
  description: "Flood observation and community report management",
};
export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
