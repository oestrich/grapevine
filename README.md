# Gossip

Gossip is a MUD chat network.

- [MUD Coders Slack](https://slack.mudcoders.com/)
- [Docs](https://gossip.haus/docs)
- [Patreon](https://www.patreon.com/midmud)

## WebSocket Protocol

View the websocket details on [Gossip][websocket-docs].

## Server

### Requirements

This is only required to run Gossip itself, the server. These are not required to connect as a game. See the above [websocket docs][websocket-docs] for connecting as a client.

- PostgreSQL 10
- Elixir 1.6.6
- Erlang 21.0.2.
- node.js 8.6

### Setup

```bash
mix deps.get
mix compile
cd assets && npm install && node node_modules/brunch/bin/brunch build && cd ..
mix ecto.reset
mix phx.server
```

This will start a web server on port 4000. You can now load [http://localhost:4000/](http://localhost:4000/) to view the application.

### Running Tests

```bash
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate
mix test
```

[websocket-docs]: https://gossip.haus/docs
