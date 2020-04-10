FROM grapevinehaus/elixir:1.9.4-alpine-1 as builder
RUN apk update && \
  apk upgrade --no-cache && \
  apk add --no-cache gcc git make musl-dev && \
  mix local.rebar --force && \
  mix local.hex --force
WORKDIR /apps/socket/
ENV MIX_ENV=prod
COPY data/mix.* /apps/data/
COPY socket/mix.* /apps/socket/
RUN mix deps.get --only prod && \
  mix deps.compile

FROM builder as releaser
COPY data /apps/data/
COPY socket /apps/socket/
RUN mix release

FROM alpine:3.11
ENV LANG=C.UTF-8
RUN apk update && \
  apk add -U bash openssl && \
  rm -rf /var/cache/apk/*
WORKDIR /app
COPY --from=releaser /apps/socket/_build/prod/rel/grapevine_socket /app

ENV MIX_ENV=prod
EXPOSE 4110

ENTRYPOINT ["bin/grapevine_socket"]
CMD ["start"]
