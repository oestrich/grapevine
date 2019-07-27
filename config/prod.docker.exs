import Config

config :grapevine, GrapevineData.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "grapevine",
  hostname: "postgres",
  username: "grapevine",
  password: "grapevine",
  pool_size: 10

config :grapevine, Web.Endpoint,
  http: [port: 4100],
  url: [host: "grapevine.haus", port: 443, scheme: "https"],
  cache_static_manifest: "priv/static/cache_manifest.json"

config :grapevine, :socket, tls: true

# Configure your database
config :grapevine_data, GrapevineData.Repo,
  hostname: "localhost",
  username: "grapevine",
  password: "password",
  database: "grapevine",
  pool_size: 10

config :grapevine, :errors, report: false
