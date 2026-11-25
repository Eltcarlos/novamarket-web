export const dynamic = "force-dynamic";

export function GET() {
  return Response.json(
    { status: "ok", region: process.env.REGION ?? "local" },
    { headers: { "Cache-Control": "no-store" } },
  );
}
