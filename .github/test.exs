import Config

# Configure your database
config :grapevine_data, GrapevineData.Repo,
  database: "grapevine_test",
  hostname: "postgres",
  username: "postgres",
  password: "postgres",
  port: 5433,
  pool: Ecto.Adapters.SQL.Sandbox
