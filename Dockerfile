FROM node:20-bookworm-slim AS build

WORKDIR /app

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt-get update && \
  apt-get install -y --no-install-recommends python3 make g++ && \
  rm -rf /var/lib/apt/lists/*

COPY package.json yarn.lock ./
RUN --mount=type=cache,target=/root/.yarn/cache,sharing=locked \
  yarn install --frozen-lockfile

COPY . .
RUN yarn tsc
RUN yarn build:backend

FROM node:20-bookworm-slim

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt-get update && \
  apt-get install -y --no-install-recommends tini && \
  rm -rf /var/lib/apt/lists/*

USER node
WORKDIR /app

COPY --from=build /app/packages/backend/dist/skeleton.tar.gz ./
RUN tar xzf skeleton.tar.gz && rm skeleton.tar.gz

COPY --from=build /app/packages/backend/dist/bundle.tar.gz ./
RUN tar xzf bundle.tar.gz && rm bundle.tar.gz

ENV NODE_ENV=production
ENV PORT=7007

EXPOSE 7007

ENTRYPOINT ["tini", "--"]
CMD ["node", "packages/backend/dist/index.js"]
