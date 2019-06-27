use Mix.Config

# Configure your database
config :grapevine, GrapevineData.Repo,
  database: "grapevine_test",
  hostname: "localhost",
  username: "grapevine",
  password: "password",
  port: 5433,
  pool: Ecto.Adapters.SQL.Sandbox
