use Mix.Config

# Configure your database
config :grapevine_data, GrapevineData.Repo,
  database: "grapevine_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :bcrypt_elixir, :log_rounds, 4

config :logger, level: :warn

config :stein, :storage, backend: :test

if File.exists?("config/test.extra.exs") do
  import_config("test.extra.exs")
end
