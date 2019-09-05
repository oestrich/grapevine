import Config

# Configure your database
config :grapevine_data, GrapevineData.Repo,
  database: "grapevine_test",
  hostname: "localhost",
  username: "postgres",
  password: "postgres",
  pool: Ecto.Adapters.SQL.Sandbox
