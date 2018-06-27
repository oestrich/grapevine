# Gossip

Gossip is a MUD chat network.

## Requirements

- PostgreSQL 10
- Elixir 1.6
- Erlang 20
- node.js 8.6

## Setup

```bash
mix deps.get
mix compile
cd assets && npm install && node node_modules/brunch/bin/brunch build && cd ..
mix ecto.reset
mix run --no-halt
```

This will start a web server on port 4000. You can now load [http://localhost:4000/](http://localhost:4000/) to view the application.

## Running Tests

```bash
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate
mix test
```
