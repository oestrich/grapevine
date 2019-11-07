import Config

config :grapevine_socket, http: [port: 4111]

config :bcrypt_elixir, :log_rounds, 4
config :logger, level: :warn

config :grapevine_data, GrapevineData.Repo,
  database: "grapevine_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

if File.exists?("config/test.extra.exs") do
  import_config("test.extra.exs")
end
