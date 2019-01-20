use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :gossip, Web.Endpoint,
  http: [port: 4001],
  server: false

config :logger, level: :error

# Configure your database
config :gossip, Gossip.Repo,
  database: "gossip_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :bcrypt_elixir, :log_rounds, 4

config :gossip, Gossip.Mailer, adapter: Bamboo.TestAdapter

config :gossip, :modules, client: Test.FakeClient
