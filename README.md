# Grapevine

![Grapevine](https://grapevine.haus/images/grapevine.png)

Grapevine is a MUD chat network.

- [MUD Coders Slack](https://slack.mudcoders.com/)
- [Docs](https://grapevine.haus/docs)
- [Trello](https://trello.com/b/bWZ00VpS/grapevine)
- [Patreon](https://www.patreon.com/exventure)
- [Discord](https://discord.gg/GPEa6dB)

## WebSocket Protocol

View the websocket details on [Grapevine][websocket-docs].

## Server

### Requirements

This is only required to run Grapevine itself, the server. These are not required to connect as a game. See the above [websocket docs][websocket-docs] for connecting as a client.

- PostgreSQL 10
- Elixir 1.8.0
- Erlang 21.2.6
- node.js 10.13.0

### Setup

```bash
mix deps.get
mix compile
cd assets && npm install && node node_modules/brunch/bin/brunch build && cd ..
mix ecto.reset
mix phx.server
```

This will start a web server on port 4100. You can now load [http://localhost:4100/](http://localhost:4100/) to view the application.

### Running Tests

```bash
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate
mix test
```

### Docker

```bash
docker-compose build grapevine
docker-compose up -d postgres
docker-compose run --rm grapevine migrate
docker-compose up grapevine
```

### Telnet Web Client

For deployment the telnet application needs to be on its own erlang node. You can connect with something similar to:

```elixir
config :grapevine,
  topologies: [
    local: [
      strategy: Cluster.Strategy.Epmd,
      config: [
        hosts: [
          :grapevine@localhost,
          :telnet@localhost,
        ]
      ]
    ]
  ]
```

## Setting up a new Play CNAME

- Game sets the CNAME to `grapevine.haus`
- Game must have a homepage url
- Game must have the web client enabled
- Update game's record for their CNAME
- Update nginx config for new domain
- Run certbot for the new domain
- Refresh CNAMEs in ETS `Grapevine.CNAMEs.reload()`

[websocket-docs]: https://grapevine.haus/docs
