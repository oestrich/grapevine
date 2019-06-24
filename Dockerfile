FROM elixir:1.8-alpine as builder

# The nuclear approach:
# RUN apk add --no-cache alpine-sdk
RUN apk add --no-cache \
    gcc \
    git \
    make \
    musl-dev

RUN mix local.rebar --force && \
    mix local.hex --force

WORKDIR /app
ENV MIX_ENV=prod
COPY mix.* /app/
RUN mix deps.get --only prod

RUN mix deps.compile

FROM node:10.13 as frontend

WORKDIR /app
COPY assets/package.json assets/yarn.lock /app/
COPY --from=builder /app/deps/phoenix /deps/phoenix
COPY --from=builder /app/deps/phoenix_html /deps/phoenix_html
COPY --from=builder /app/deps/phoenix_live_view /deps/phoenix_live_view

RUN npm install -g yarn && yarn install

COPY assets /app
RUN npm run deploy

FROM builder as releaser
COPY --from=frontend /priv/static /app/priv/static
COPY . /app/
ARG cookie
ENV COOKIE=${cookie}
RUN mix phx.digest
RUN mix release --env=prod --no-tar

FROM alpine:3.9
ENV LANG=C.UTF-8
RUN apk add -U bash openssl imagemagick
WORKDIR /app
COPY --from=releaser /app/_build/prod/rel/grapevine /app/
COPY config/prod.docker.exs /etc/grapevine/config.exs

ENV MIX_ENV=prod

EXPOSE 4001

ENTRYPOINT ["bin/grapevine"]
CMD ["foreground"]
