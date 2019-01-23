use Mix.Config

#
# Don't forget to update .travis/test.exs!
#

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :grapevine, Web.Endpoint,
  http: [port: 4001],
  server: false

config :logger, level: :error

# Configure your database
config :grapevine, Grapevine.Repo,
  database: "grapevine_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :bcrypt_elixir, :log_rounds, 4

config :grapevine, Grapevine.Mailer, adapter: Bamboo.TestAdapter

config :grapevine, :modules, client: Test.FakeClient

config :grapevine, :storage, backend: :test
