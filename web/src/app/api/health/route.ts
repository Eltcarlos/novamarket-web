import { getRegion } from "../../../lib/region";

export const dynamic = "force-dynamic";

export function GET() {
  return Response.json({ status: "ok", region: getRegion() }, { headers: { "Cache-Control": "no-store" } });
}
