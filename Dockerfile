FROM elixir:1.7.2-alpine as builder

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

FROM node:8.6 as frontend

WORKDIR /app
COPY assets/package*.json /app/
COPY --from=builder /app/deps/phoenix /deps/phoenix
COPY --from=builder /app/deps/phoenix_html /deps/phoenix_html

RUN npm install

COPY assets /app
RUN node node_modules/brunch/bin/brunch build

FROM builder as releaser
COPY --from=frontend /priv/static /app/priv/static
COPY . /app/
ENV COOKIE="zR2/sR0Ohy5xeVMjMHsCt5Jl76lTpeI0LU57zu8XrnfLLzHZFuIsWxQYiMLBpToU"
RUN mix phx.digest
RUN mix release --env=prod --no-tar

FROM alpine:3.8
RUN apk add -U bash libssl1.0
WORKDIR /app
COPY --from=releaser /app/_build/prod/rel/grapevine /app/
COPY config/prod.docker.exs /etc/grapevine.config.exs

ENV MIX_ENV=prod

EXPOSE 4001

ENTRYPOINT ["bin/grapevine"]
CMD ["foreground"]
