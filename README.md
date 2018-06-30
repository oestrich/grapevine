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
## WebSocket Protocol

### Sign-in

Client sends:

```json
{"event": "authenticate", "payload": {"client-id": "client id", "client-secret": "client secret"}}
```

### Post a New Message

Client Sends

```json
{"event": "messages/new", "payload": {"channel": "gossip", "name": "Player", "message": "Hello everyone!"}}
```

### Receive a Broadcast

Server Sends

```json
{"event": "messages/broadcast", "payload": {"message": "Hello everyone!", "game": "ExVenture", "name": "Player"}}
```

### Receive subscribed channels

Server sends after authentication

```json
{"event": "channels/subscribed", "payload": {"channels": ["gossip"]}}
```

### Heartbeat

Server sends every ~15 seconds:

```json
{"event": "heartbeat"}
```
