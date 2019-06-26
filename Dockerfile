FROM elixir:1.8-alpine as builder
ENV MIX_ENV=prod
RUN apk update && \
  apk upgrade --no-cache && \
  apk add --no-cache gcc git make musl-dev && \
  mix local.rebar --force && \
  mix local.hex --force
WORKDIR /opt/app
COPY mix.* /opt/app/
RUN mix deps.get --only prod && \
  mix deps.compile

FROM node:10.13 as frontend
WORKDIR /opt/app
COPY assets/package.json assets/yarn.lock /opt/app/
COPY --from=builder /opt/app/deps/phoenix /opt/deps/phoenix
COPY --from=builder /opt/app/deps/phoenix_html /opt/deps/phoenix_html
COPY --from=builder /opt/app/deps/phoenix_live_view /opt/deps/phoenix_live_view
RUN npm install -g yarn && yarn install
COPY assets /opt/app
RUN npm run deploy

FROM builder as releaser
COPY --from=frontend /opt/priv/static /opt/app/priv/static
COPY . /opt/app/
ARG cookie
ENV COOKIE=${cookie}
RUN mix phx.digest && \
  mix release --env=prod --no-tar

FROM alpine:3.9
ENV LANG=C.UTF-8
RUN apk update && \
  apk add -U bash openssl-dev imagemagick && \
  rm -rf /var/cache/apk/*
WORKDIR /opt/app
COPY --from=releaser /opt/app/_build/prod/rel/grapevine /opt/app/
COPY config/prod.docker.exs /etc/grapevine/config.exs

ENV MIX_ENV=prod
EXPOSE 4100

ENTRYPOINT ["bin/grapevine"]
CMD ["foreground"]
