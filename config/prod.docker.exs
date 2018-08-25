use Mix.Config

config :gossip, Gossip.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "gossip",
  hostname: "postgres",
  username: "gossip",
  password: "gossip",
  pool_size: 10

config :gossip, Web.Endpoint,
  http: [port: 4001],
  url: [host: {:system, "HOST"}, port: 443, scheme: "https"],
  server: true,
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info

config :phoenix, :serve_endpoints, true
