FROM elixir:1.9-alpine as builder
ENV MIX_ENV=prod
RUN apk update && \
  apk upgrade --no-cache && \
  apk add --no-cache gcc git make musl-dev && \
  mix local.rebar --force && \
  mix local.hex --force
WORKDIR /app
COPY mix.* /app/
RUN mix deps.get --only prod && \
  mix deps.compile

FROM builder as releaser
COPY . /app/
ARG cookie
ENV COOKIE=${cookie}
RUN mix release

FROM alpine:3.9
ENV LANG=C.UTF-8
ENV MIX_ENV=prod
RUN apk update && \
  apk add -U bash openssl && \
  rm -rf /var/cache/apk/*
WORKDIR /app
COPY --from=releaser /app/_build/prod/rel/telnet /app
COPY config/prod.docker.exs /etc/telnet/config.exs

ENV MIX_ENV=prod

ENTRYPOINT ["bin/telnet"]
CMD ["start"]
