# Gossip

![Gossip](https://gossip.haus/images/gossip.png)

Gossip is a MUD chat network.

- [Grapevine](https://github.com/oestrich/grapevine)
- [Raisin](https://github.com/oestrich/raisin)
- [MUD Coders Slack](https://slack.mudcoders.com/)
- [Docs](https://gossip.haus/docs)
- [Patreon](https://www.patreon.com/exventure)

## WebSocket Protocol

View the websocket details on [Gossip][websocket-docs].

## Server

### Requirements

This is only required to run Gossip itself, the server. These are not required to connect as a game. See the above [websocket docs][websocket-docs] for connecting as a client.

- PostgreSQL 10
- Elixir 1.7.2
- Erlang 21.0.5
- node.js 8.6

### Setup

```bash
mix deps.get
mix compile
cd assets && npm install && node node_modules/brunch/bin/brunch build && cd ..
mix ecto.reset
mix phx.server
```

This will start a web server on port 4001. You can now load [http://localhost:4001/](http://localhost:4001/) to view the application.

### Running Tests

```bash
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate
mix test
```

### Docker

```bash
docker-compose build gossip
docker-compose up -d postgres
docker-compose run --rm gossip migrate
docker-compose up gossip
```

[websocket-docs]: https://gossip.haus/docs
