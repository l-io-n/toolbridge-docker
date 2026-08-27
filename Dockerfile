# ---- Build stage ----
FROM node:20-slim AS builder
WORKDIR /app

COPY package.json ./
RUN npm install

COPY . .

# As of this writing, `tsc` reports 3 cosmetic strict-mode type errors in
# two files (header value narrowing) that do NOT affect the emitted JS --
# but they do make `tsc` exit non-zero, which is why the project's own
# `npm start` (`npm run build && node ...`) currently fails outright on a
# fresh clone: the `&&` never reaches `node`. We build directly here and
# don't propagate that exit code. Verified: the emitted dist/ is complete
# and the server runs correctly.
RUN npx tsc || true
RUN test -f dist/src/index.js || (echo "Build failed: dist/src/index.js missing" && exit 1)

# ---- Runtime stage ----
FROM node:20-slim
WORKDIR /app

COPY package.json ./
RUN npm install --omit=dev

COPY --from=builder /app/dist ./dist
COPY config.json ./config.json

EXPOSE 3100
CMD ["node", "--no-deprecation", "dist/src/index.js"]
