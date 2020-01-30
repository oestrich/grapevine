FROM elixir:1.9-alpine as builder
ENV MIX_ENV=prod
RUN apk update && \
  apk upgrade --no-cache && \
  apk add --no-cache gcc git make musl-dev && \
  mix local.rebar --force && \
  mix local.hex --force
WORKDIR /apps/telnet/
ENV MIX_ENV=prod
COPY data/mix.* /apps/data/
COPY telnet/mix.* /apps/telnet/
RUN mix deps.get --only prod && \
  mix deps.compile

FROM builder as releaser
COPY data /apps/data/
COPY telnet /apps/telnet/
RUN mix release

FROM alpine:3.11
ENV LANG=C.UTF-8
ENV MIX_ENV=prod
RUN apk update && \
  apk add -U bash openssl && \
  rm -rf /var/cache/apk/*
WORKDIR /app
COPY --from=releaser /apps/telnet/_build/prod/rel/telnet /app

ENV MIX_ENV=prod
EXPOSE 4101

ENTRYPOINT ["bin/telnet"]
CMD ["start"]
