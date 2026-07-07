# Example production Dockerfile matching the chart's security defaults
# (non-root uid 10001, read-only rootfs, port 8080).
FROM node:22-alpine AS build
WORKDIR /build
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .

FROM node:22-alpine
ENV NODE_ENV=production
WORKDIR /app
COPY --from=build --chown=10001:10001 /build /app
USER 10001:10001
EXPOSE 8080
HEALTHCHECK CMD wget -qO- http://127.0.0.1:8080/healthz || exit 1
CMD ["node", "server.js"]
