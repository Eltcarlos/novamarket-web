// Punto de entrada de Next.js: se ejecuta una vez al iniciar el servidor.
export async function register() {
  if (process.env.NEXT_RUNTIME === "nodejs") {
    const { startTelemetry } = await import("./telemetry/start");
    startTelemetry();
  }
}
