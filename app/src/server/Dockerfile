FROM node:24-alpine AS base

WORKDIR /app

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs

COPY package*.json ./

# Development stage
FROM base AS dev

ENV NODE_ENV=development \
    NPM_CONFIG_LOGLEVEL=warn

RUN --mount=type=cache,target=/root/.npm,sharing=locked \
    npm ci && \
    npm cache clean --force

COPY --chown=nodejs:nodejs . .

USER nodejs

EXPOSE 3011

CMD ["npm", "start"]

# Production stage
FROM base AS prod-deps

ENV NODE_ENV=production \
    NPM_CONFIG_LOGLEVEL=silent

RUN --mount=type=cache,target=/root/.npm,sharing=locked \
    npm ci --omit=dev && \
    npm cache clean --force

# Final production image
FROM base AS production

ENV NODE_ENV=production \
    NPM_CONFIG_LOGLEVEL=silent

COPY --from=prod-deps /app/node_modules ./node_modules

COPY --chown=nodejs:nodejs . .

USER nodejs

EXPOSE 3011

CMD ["npm", "start"]