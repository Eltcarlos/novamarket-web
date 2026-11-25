import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-proto";
import { resourceFromAttributes } from "@opentelemetry/resources";
import { BatchSpanProcessor, SimpleSpanProcessor, TraceIdRatioBasedSampler } from "@opentelemetry/sdk-trace-base";
import { NodeTracerProvider } from "@opentelemetry/sdk-trace-node";
import { CloudLoggingSpanExporter } from "./cloud-logging-exporter";

function sampleRatio(): number {
  const ratio = Number.parseFloat(process.env.OTEL_TRACES_SAMPLER_ARG ?? "1");
  return ratio >= 0 && ratio <= 1 ? ratio : 1;
}

export function startTelemetry() {
  // Con OTEL_EXPORTER_OTLP_ENDPOINT: OTLP hacia un colector.
  // Sin el: spans como JSON en stdout, que Cloud Run envia a Cloud Logging sin roles.
  const processor = process.env.OTEL_EXPORTER_OTLP_ENDPOINT
    ? // Next termina el proceso en SIGTERM sin esperar el envio: un lote de 1 s acota la perdida.
      new BatchSpanProcessor(new OTLPTraceExporter(), { scheduledDelayMillis: 1000 })
    : new SimpleSpanProcessor(new CloudLoggingSpanExporter());

  const provider = new NodeTracerProvider({
    resource: resourceFromAttributes({
      "service.name": process.env.K_SERVICE ?? "novamarket-web",
      "service.version": process.env.K_REVISION ?? "local",
      "cloud.region": process.env.REGION ?? "local",
    }),
    // No usa el "sampled" entrante: Cloud Run muestrea muy pocas peticiones.
    // El ratio por trace ID da la misma decision en todos los servicios.
    sampler: new TraceIdRatioBasedSampler(sampleRatio()),
    spanProcessors: [processor],
  });

  provider.register(); // propagacion W3C (traceparent) por defecto
}
