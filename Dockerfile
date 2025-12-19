FROM oven/bun:1.3-alpine AS builder

WORKDIR /app

# Copy all package.json files for workspace resolution
COPY package.json bun.lockb ./

# Copy all workspace package.json files
COPY packages/ai/package.json ./packages/ai/
COPY packages/constants/package.json ./packages/constants/
COPY packages/db/package.json ./packages/db/
COPY packages/email/package.json ./packages/email/
COPY packages/fonts/package.json ./packages/fonts/
COPY packages/git/package.json ./packages/git/
COPY packages/growth/package.json ./packages/growth/
COPY packages/image-server/package.json ./packages/image-server/
COPY packages/mastra/package.json ./packages/mastra/
COPY packages/models/package.json ./packages/models/
COPY packages/parser/package.json ./packages/parser/
COPY packages/penpal/package.json ./packages/penpal/
COPY packages/rpc/package.json ./packages/rpc/
COPY packages/scripts/package.json ./packages/scripts/
COPY packages/stripe/package.json ./packages/stripe/
COPY packages/types/package.json ./packages/types/
COPY packages/ui/package.json ./packages/ui/
COPY packages/utility/package.json ./packages/utility/

COPY tooling/typescript/package.json ./tooling/typescript/

COPY apps/backend/package.json ./apps/backend/
COPY apps/web/package.json ./apps/web/
COPY apps/web/client/package.json ./apps/web/client/
COPY apps/web/preload/package.json ./apps/web/preload/
COPY apps/web/server/package.json ./apps/web/server/
COPY apps/web/template/package.json ./apps/web/template/

COPY docs/package.json ./docs/

# Install dependencies
RUN bun install --frozen-lockfile

# Copy all source files
COPY . .

# Build arguments
ARG SUPABASE_DATABASE_URL
ARG ANTHROPIC_API_KEY
ARG NEXT_PUBLIC_SUPABASE_URL
ARG NEXT_PUBLIC_SUPABASE_ANON_KEY
ARG CSB_API_KEY
ARG NEXT_PUBLIC_APP_URL
ARG NODE_ENV=production
ARG SESSION_SECRET
ARG JWT_SECRET

# Set environment variables for build
ENV SUPABASE_DATABASE_URL=$SUPABASE_DATABASE_URL \
    ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
    NEXT_PUBLIC_SUPABASE_URL=$NEXT_PUBLIC_SUPABASE_URL \
    NEXT_PUBLIC_SUPABASE_ANON_KEY=$NEXT_PUBLIC_SUPABASE_ANON_KEY \
    CSB_API_KEY=$CSB_API_KEY \
    NEXT_PUBLIC_APP_URL=$NEXT_PUBLIC_APP_URL \
    NODE_ENV=$NODE_ENV \
    SESSION_SECRET=$SESSION_SECRET \
    JWT_SECRET=$JWT_SECRET \
    NEXT_TELEMETRY_DISABLED=1

# Build the application
RUN bun run build

FROM oven/bun:1.3-alpine AS runner

WORKDIR /app

# Copy built application
COPY --from=builder /app ./

ENV NODE_ENV=production \
    PORT=3000 \
    HOSTNAME="0.0.0.0" \
    NEXT_TELEMETRY_DISABLED=1

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD bun -e "fetch('http://localhost:3000').then(r => r.ok ? process.exit(0) : process.exit(1)).catch(() => process.exit(1))"

CMD ["bun", "run", "start"]
