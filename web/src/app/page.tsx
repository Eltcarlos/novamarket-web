// Se evalua por peticion para mostrar la region que atiende al usuario.
export const dynamic = "force-dynamic";

export default function Home() {
  return (
    <main>
      <h1>NovaMarket LATAM</h1>
      <p>Plataforma regional unificada: Colombia, México, Perú y Chile.</p>
      <ul>
        <li>Región: {process.env.REGION ?? "local"}</li>
        <li>Revisión: {process.env.K_REVISION ?? "local"}</li>
      </ul>
    </main>
  );
}
