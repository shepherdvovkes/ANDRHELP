FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package.json tsconfig.json ./
COPY src ./src

RUN npm install && npm run build

FROM node:20-alpine

WORKDIR /app

ENV NODE_ENV=production

# Copy only needed files
COPY package.json ./
RUN npm install --only=production

COPY --from=builder /app/dist ./dist

# Copy service account key for Google Cloud Speech-to-Text
COPY speech-to-text-key.json ./speech-to-text-key.json

# Default port (can be overridden via .env / PORT)
ENV PORT=3100

EXPOSE 3100

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s CMD wget -qO- http://127.0.0.1:${PORT}/health || exit 1

CMD ["node", "dist/server.js"]


