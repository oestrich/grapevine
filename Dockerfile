FROM elixir:1.9-alpine as builder
RUN apk update && \
      apk upgrade --no-cache && \
      apk add --no-cache gcc git make musl-dev && \
      mix local.rebar --force && \
      mix local.hex --force
WORKDIR /app
ENV MIX_ENV=prod
COPY apps/data/mix.* /app/apps/data/
COPY mix.* /app/
RUN mix deps.get --only prod
RUN mix deps.compile

FROM node:10.9 as frontend
WORKDIR /app
COPY assets/package.json assets/yarn.lock /app/
COPY --from=builder /app/deps/phoenix /deps/phoenix
COPY --from=builder /app/deps/phoenix_html /deps/phoenix_html
COPY --from=builder /app/deps/phoenix_live_view /deps/phoenix_live_view
RUN npm install -g yarn && yarn install
COPY assets /app
RUN yarn run deploy

FROM builder as releaser
ENV MIX_ENV=prod
COPY --from=frontend /priv/static /app/priv/static
COPY . /app/
RUN mix phx.digest
ARG WEB_HOST
ARG WEB_PORT
ARG WEB_SCHEME
RUN mix release

FROM alpine:3.11
ENV LANG=C.UTF-8
RUN apk update && \
  apk add -U bash openssl imagemagick && \
  rm -rf /var/cache/apk/*
WORKDIR /opt/app
COPY --from=releaser /app/_build/prod/rel/grapevine /opt/app/

ENV MIX_ENV=prod
EXPOSE 4100

ENTRYPOINT ["bin/grapevine"]
CMD ["start"]
