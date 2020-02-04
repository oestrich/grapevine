# Grapevine

![Grapevine](https://grapevine.haus/images/grapevine.png)

Grapevine is a MUD chat network.

- [MUD Coders Slack](https://slack.mudcoders.com/)
- [Docs](https://grapevine.haus/docs)
- [Trello](https://trello.com/b/bWZ00VpS/grapevine)
- [Patreon](https://www.patreon.com/ericoestrich)
- [Discord](https://discord.gg/GPEa6dB)

## WebSocket Protocol

View the websocket details on [Grapevine][websocket-docs].

## Server

### Requirements

This is only required to run Grapevine itself, the server. These are not required to connect as a game. See the above [websocket docs][websocket-docs] for connecting as a client.

- PostgreSQL 11
- Elixir 1.9.0
- Erlang 22.0.4
- node.js 10.13.0
- [Yarn](https://yarnpkg.com/en/docs/install)

### Setup

```bash
cd apps/grapevine
mix deps.get
mix compile
yarn --cwd assets
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

### Telnet Web Client

Telnet connections live in the `apps/telnet` application. This node holds the telnet connections so the main application can reboot on deploys and not drop active game connections.

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

### Docker Compose

To run a production like system locally, you can use [docker-compose](https://docs.docker.com/compose/).

The following commands will get a system running locally at `http://grapevine.local`. This also assumes you have something listening locally (such as nginx) that will proxy port 80 traffic to port 4100.

```bash
docker-compose build
docker-compose up -d postgres
docker-compose up -d socket
docker-compose up -d telnet
docker-compose run --rm web eval "Grapevine.ReleaseTasks.migrate()"
docker-compose run --rm web eval "Grapevine.ReleaseTasks.seed()"
docker-compose up web
```

#### Simple nginx config

This nginx config will configure your server to listen for `grapevine.local` and forward to either a local development server or the docker-compose setup from above.

```nginx
    upstream grapevine {
            server localhost:4100;
    }

    server {
            listen 80;
            server_name grapevine.local;

            location / {
                    proxy_set_header Host $host;
                    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                    proxy_set_header X-Real-IP $remote_addr;
                    proxy_set_header X-Forwarded-Proto $scheme;
                    proxy_http_version 1.1;
                    proxy_set_header Upgrade $http_upgrade;
                    proxy_set_header Connection "upgrade";
                    proxy_pass http://grapevine;
            }
    }
```

## Setting up a new Play CNAME

- Game sets the CNAME to `client.grapevine.haus`
- Game must have a homepage url
- Game must have the web client enabled
- Update game's record for their CNAME
- Update nginx config for new domain
- Run certbot for the new domain
- Refresh CNAMEs in ETS `Grapevine.CNAMEs.reload()`

[websocket-docs]: https://grapevine.haus/docs

## Kubernetes

Some notes on installing into kubernetes:

```bash
# Set up nginx ingress
helm install nginx-ingress stable/nginx-ingress --set controller.publishService.enabled=true
```
