FROM grapevinehaus/elixir:1.9.4-alpine-1 as builder
RUN apk update && \
      apk upgrade --no-cache && \
      apk add --no-cache gcc git make musl-dev && \
      mix local.rebar --force && \
      mix local.hex --force
WORKDIR /apps/grapevine
ENV MIX_ENV=prod
COPY data/mix.* /apps/data/
COPY socket/mix.* /apps/socket/
COPY telnet/mix.* /apps/telnet/
COPY grapevine/mix.* /apps/grapevine/
RUN mix deps.get --only prod
RUN mix deps.compile

FROM node:10.9 as frontend
WORKDIR /app
COPY grapevine/assets/package.json grapevine/assets/yarn.lock /app/
COPY --from=builder /apps/grapevine/deps/phoenix /deps/phoenix
COPY --from=builder /apps/grapevine/deps/phoenix_html /deps/phoenix_html
COPY --from=builder /apps/grapevine/deps/phoenix_live_view /deps/phoenix_live_view
RUN npm install -g yarn && yarn install
COPY grapevine/assets /app
RUN yarn run deploy

FROM builder as releaser
COPY --from=frontend /priv/static /apps/grapevine/priv/static
COPY data /apps/data
COPY socket /apps/socket
COPY telnet /apps/telnet
COPY grapevine/ /apps/grapevine
RUN mix phx.digest && \
  mix release

FROM alpine:3.11
ENV LANG=C.UTF-8
RUN apk update && \
  apk add -U bash openssl imagemagick && \
  rm -rf /var/cache/apk/*
WORKDIR /app
COPY --from=releaser /apps/grapevine/_build/prod/rel/grapevine /app/

ENV MIX_ENV=prod
EXPOSE 4100

ENTRYPOINT ["bin/grapevine"]
CMD ["start"]
