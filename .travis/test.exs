use Mix.Config

# Configure your database
config :grapevine_data, GrapevineData.Repo,
  database: "grapevine_test",
  hostname: "localhost",
  username: "grapevine",
  password: "password",
  port: 5433,
  pool: Ecto.Adapters.SQL.Sandbox
