"use client";

import { useCallback, useEffect, useState } from "react";

type Status = { state: "loading" | "ok" | "error"; ms?: number };

export function LiveStatus() {
  const [status, setStatus] = useState<Status>({ state: "loading" });

  const check = useCallback(async () => {
    setStatus({ state: "loading" });
    const start = performance.now();
    try {
      const res = await fetch("/api/health", { cache: "no-store" });
      if (!res.ok) throw new Error(String(res.status));
      setStatus({ state: "ok", ms: Math.round(performance.now() - start) });
    } catch {
      setStatus({ state: "error" });
    }
  }, []);

  useEffect(() => void check(), [check]);

  const text =
    status.state === "ok" ? `En línea · ${status.ms} ms` : status.state === "error" ? "Sin respuesta" : "Comprobando…";

  return (
    <div className="live">
      <span className={`dot ${status.state}`} aria-hidden="true" />
      <span role="status">{text}</span>
      <button type="button" onClick={check} disabled={status.state === "loading"}>
        Medir de nuevo
      </button>
    </div>
  );
}
