import type { CSSProperties } from "react";
import { LiveStatus } from "../components/live-status";
import { getRegion, regionLabel } from "../lib/region";

// Se evalua por peticion para mostrar la region que atiende al usuario.
export const dynamic = "force-dynamic";

const COUNTRIES = [
  { name: "Colombia", currency: "Peso colombiano (COP)", color: "#f2b134" },
  { name: "México", currency: "Peso mexicano (MXN)", color: "#0b5d4b" },
  { name: "Perú", currency: "Sol (PEN)", color: "#e4572e" },
  { name: "Chile", currency: "Peso chileno (CLP)", color: "#2a7f9e" },
];

const FEATURES = [
  { title: "Dos regiones activas", text: "Querétaro y Santiago sirven la misma versión detrás de una sola dirección IP." },
  { title: "Escala con la demanda", text: "Las instancias aumentan en campañas y se reducen cuando baja el tráfico." },
  { title: "Cada petición deja rastro", text: "OpenTelemetry registra las peticiones sin guardar la URL completa." },
];

export default function Home() {
  const region = getRegion();

  return (
    <>
      <div className="wrap">
        <header>
          <a className="brand" href="/">Nova<span>Market</span></a>
          <nav><a href="/api/health">Estado del servicio</a></nav>
        </header>

        <main>
          <div className="hero">
            <div>
              <h1>Un solo mercado para <em>toda la región</em></h1>
              <p className="lead">
                NovaMarket reúne a clientes, vendedores y operadores logísticos de Colombia, México, Perú y Chile en una
                misma plataforma.
              </p>
              <a className="btn" href="#paises">Ver los países</a>
            </div>

            <aside className="panel">
              <h2>Te atiende</h2>
              <p className="place">{regionLabel(region)}</p>
              <LiveStatus />
              <dl>
                <div><dt>Región de Google Cloud</dt><dd>{region}</dd></div>
                <div><dt>Revisión</dt><dd>{process.env.K_REVISION ?? "local"}</dd></div>
              </dl>
            </aside>
          </div>

          <section id="paises">
            <h2>Cuatro países para empezar</h2>
            <ul className="countries">
              {COUNTRIES.map((c) => (
                <li key={c.name} style={{ "--c": c.color } as CSSProperties}>
                  <strong>{c.name}</strong>
                  <span>{c.currency}</span>
                </li>
              ))}
            </ul>
          </section>

          <section>
            <h2>Preparada para los días de más venta</h2>
            <div className="features">
              {FEATURES.map((f) => (
                <div key={f.title}><h3>{f.title}</h3><p>{f.text}</p></div>
              ))}
            </div>
          </section>
        </main>

        <footer>NovaMarket LATAM. Entorno de demostración.</footer>
      </div>
    </>
  );
}
