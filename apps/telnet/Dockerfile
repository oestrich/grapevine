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

FROM builder as releaser
COPY . /opt/app/
ARG cookie
ENV COOKIE=${cookie}
RUN mix release --env=prod --no-tar

FROM alpine:3.9
ENV LANG=C.UTF-8
RUN apk update && \
  apk add -U bash openssl-dev && \
  rm -rf /var/cache/apk/*
WORKDIR /opt/app
COPY --from=releaser /opt/app/_build/prod/rel/telnet /opt/app/
COPY config/prod.docker.exs /etc/telnet/config.exs

ENV MIX_ENV=prod

ENTRYPOINT ["bin/telnet"]
CMD ["foreground"]
