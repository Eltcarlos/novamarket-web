import type { Metadata } from "next";
import type { ReactNode } from "react";

export const metadata: Metadata = {
  title: "NovaMarket LATAM",
  description: "Plataforma regional unificada",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="es">
      <body style={{ fontFamily: "system-ui, sans-serif", margin: "4rem auto", maxWidth: "40rem", padding: "0 1rem" }}>
        {children}
      </body>
    </html>
  );
}
