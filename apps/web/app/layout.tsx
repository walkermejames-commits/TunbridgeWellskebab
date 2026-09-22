import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = {
  title: "Tunbridge Wells Kebab | Demo",
  description: "Controlled demo ordering and delivery tracking.",
  manifest: "/manifest.webmanifest",
  appleWebApp: { capable: true, title: "TWK Kebab", statusBarStyle: "black-translucent" },
};
export default function Layout({ children }: Readonly<{ children: React.ReactNode }>) { return <html lang="en"><body>{children}</body></html>; }
