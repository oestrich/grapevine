import Config

#
# Don't forget to update .travis/test.exs!
#

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :grapevine, Web.Endpoint,
  http: [port: 4001],
  url: [host: "localhost"],
  server: false

config :grapevine, :socket, http: [port: 4111]

config :logger, level: :error

config :logger, :console, metadata: [:type]

# Configure your database
config :grapevine_data, GrapevineData.Repo,
  database: "grapevine_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :bcrypt_elixir, :log_rounds, 4

config :grapevine, Grapevine.Mailer, adapter: Bamboo.TestAdapter

config :grapevine, :modules,
  telnet: Test.Telnet,
  client: Test.FakeClient

config :stein, :storage, backend: :test

config :grapevine, :web, url: [host: "www.example.com"]

if File.exists?("config/test.extra.exs") do
  import_config("test.extra.exs")
end
