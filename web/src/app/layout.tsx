import type { Metadata } from "next";
import type { ReactNode } from "react";
import "./globals.css";

export const metadata: Metadata = {
  title: "NovaMarket LATAM",
  description: "Un solo mercado para Colombia, México, Perú y Chile.",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="es">
      <body>
        <div className="weave" aria-hidden="true" />
        {children}
      </body>
    </html>
  );
}
