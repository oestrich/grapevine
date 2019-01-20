use Mix.Config

config :grapevine, Grapevine.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "grapevine",
  hostname: "postgres",
  username: "grapevine",
  password: "grapevine",
  pool_size: 10

config :grapevine, Web.Endpoint,
  http: [port: 4001],
  url: [host: {:system, "HOST"}, port: 443, scheme: "https"],
  server: true,
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info

config :phoenix, :serve_endpoints, true
