# --- Build stage --------------------------------------------------------------
FROM node:20-alpine AS builder
WORKDIR /app

# Install deps (including dev) so we can build TS and run prisma generate.
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund

# Copy sources and build.
COPY tsconfig.json ./
COPY prisma ./prisma
COPY src ./src
RUN npx prisma generate
RUN npm run build

# --- Runtime stage ------------------------------------------------------------
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=4000

# OpenSSL is required by Prisma's query engine on alpine.
RUN apk add --no-cache openssl

# Copy compiled JS, runtime deps and the Prisma schema (needed for migrate deploy).
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/prisma ./prisma
COPY package.json ./

EXPOSE 4000

# On boot: run any pending migrations against $DATABASE_URL, then start the API.
# The seed runs only when SEED_ON_BOOT=true so it's safe to leave on for the
# first deploy and turn off afterwards.
CMD ["sh", "-c", "npx prisma migrate deploy && (if [ \"$SEED_ON_BOOT\" = \"true\" ]; then npx tsx prisma/seed.ts || true; fi) && node dist/server.js"]
