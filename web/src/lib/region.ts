const LABELS: Record<string, string> = {
  "northamerica-south1": "Querétaro, México",
  "southamerica-west1": "Santiago, Chile",
};

// REGION si esta definida; si no, el sufijo del servicio (novamarket-web-<region>).
export function getRegion(): string {
  return process.env.REGION ?? process.env.K_SERVICE?.replace(/^novamarket-web-/, "") ?? "local";
}

export function regionLabel(region: string): string {
  return LABELS[region] ?? "Entorno local";
}
