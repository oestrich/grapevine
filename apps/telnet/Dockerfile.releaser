FROM elixir:1.8 as builder
RUN mix local.rebar --force && \
    mix local.hex --force
WORKDIR /app
ENV MIX_ENV=prod
COPY mix.* /app/
RUN mix deps.get --only prod
RUN mix deps.compile

FROM builder as releaser
ARG cookie
ENV COOKIE=${cookie}
COPY . /app/
RUN mix release --env=prod
