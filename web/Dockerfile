# syntax=docker/dockerfile:1

# ---- Paso 1: base comun, version fija ----
FROM node:24-alpine3.24 AS base
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1

# ---- Paso 2: dependencias exactas del lockfile (capa cacheable) ----
FROM base AS deps
RUN chown node:node /app
USER node
COPY --chown=node:node package.json package-lock.json ./
RUN npm ci --ignore-scripts --no-audit --no-fund

# ---- Paso 3: compilacion, sin root ----
FROM deps AS builder
COPY --chown=node:node next.config.ts tsconfig.json ./
COPY --chown=node:node src ./src
RUN npm run build

# ---- Paso 4: imagen final, solo lo necesario para ejecutar ----
FROM base AS runner
ENV NODE_ENV=production \
    HOSTNAME=0.0.0.0 \
    PORT=8080

# Usuario sin shell, sin home y sin privilegios; npm/yarn no hacen falta.
RUN addgroup -S -g 10001 app \
 && adduser -S -D -H -u 10001 -G app -s /sbin/nologin app \
 && rm -rf /usr/local/lib/node_modules /usr/local/bin/npm /usr/local/bin/npx \
           /usr/local/bin/corepack /opt/yarn* /usr/local/bin/yarn /usr/local/bin/yarnpkg

# El codigo pertenece a root: la app puede leerlo pero no modificarlo.
COPY --from=builder --chown=root:root /app/.next/standalone ./
COPY --from=builder --chown=root:root /app/.next/static ./.next/static

# Unica ruta con escritura: la cache de Next.
RUN mkdir -p .next/cache && chown app:app .next/cache

# UID numerico: verificable por runAsNonRoot si algun dia corre en Kubernetes.
USER 10001:10001
EXPOSE 8080

# Forma exec: node recibe SIGTERM directo y Cloud Run apaga limpiamente.
CMD ["node", "server.js"]
