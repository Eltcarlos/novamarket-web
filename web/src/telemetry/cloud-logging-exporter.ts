import { SpanKind, SpanStatusCode } from "@opentelemetry/api";
import { ExportResultCode, hrTimeToMilliseconds, type ExportResult } from "@opentelemetry/core";
import type { ReadableSpan, SpanExporter } from "@opentelemetry/sdk-trace-base";

// Lista blanca: las URLs completas pueden llevar datos personales en la query.
const ALLOWED_ATTRIBUTES = ["http.method", "http.route", "http.status_code", "next.span_type", "next.route"];

export class CloudLoggingSpanExporter implements SpanExporter {
  export(spans: ReadableSpan[], done: (result: ExportResult) => void): void {
    for (const span of spans) {
      // Los spans internos de Next (~10 por pagina) multiplicarian el costo de logs.
      const isError = span.status.code === SpanStatusCode.ERROR;
      if (span.kind === SpanKind.INTERNAL && !isError) continue;
      process.stdout.write(`${JSON.stringify(toLogEntry(span))}\n`);
    }
    done({ code: ExportResultCode.SUCCESS });
  }

  async shutdown(): Promise<void> {}
}

function toLogEntry(span: ReadableSpan) {
  const { traceId, spanId } = span.spanContext();
  const project = process.env.GOOGLE_CLOUD_PROJECT;
  const route = span.attributes["next.route"] ?? span.attributes["http.route"];

  return {
    severity: span.status.code === SpanStatusCode.ERROR ? "ERROR" : "INFO",
    message: "otel.span",
    // Campos especiales: Cloud Logging correlaciona con el log de la peticion.
    "logging.googleapis.com/trace": project ? `projects/${project}/traces/${traceId}` : traceId,
    "logging.googleapis.com/spanId": spanId,
    span: {
      // El nombre de un span sin ruta puede contener la URL; se usa el tipo.
      name: route ? span.name.split("?")[0] : (span.attributes["next.span_type"] ?? "span"),
      kind: SpanKind[span.kind],
      parentSpanId: span.parentSpanContext?.spanId,
      durationMs: hrTimeToMilliseconds(span.duration),
      attributes: Object.fromEntries(
        ALLOWED_ATTRIBUTES.filter((k) => span.attributes[k] !== undefined).map((k) => [k, span.attributes[k]]),
      ),
    },
    service: span.resource.attributes["service.name"],
    revision: span.resource.attributes["service.version"],
    region: span.resource.attributes["cloud.region"],
  };
}
