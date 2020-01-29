import Config

config :grapevine, Web.Endpoint,
  http: [port: 4100],
  url: [host: "localhost"],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

# Watch static and templates for browser reloading.
config :grapevine, Web.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/web/views/.*(ex)$},
      ~r{lib/web/live/.*(ex)$},
      ~r{lib/web/templates/.*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :grapevine_data, GrapevineData.Repo,
  database: "grapevine_dev",
  hostname: "localhost",
  pool_size: 10,
  log: false

config :phoenix, :plug_init_mode, :runtime

config :grapevine, Grapevine.Mailer,
  adapter: Bamboo.LocalAdapter,
  alert_to: ["admin@example.com"]

config :grapevine, :web, host: "localhost", url: [host: "localhost", scheme: "http", port: 4100]

config :stein, :storage,
  backend: :file,
  file_backend_folder: "uploads/"

if File.exists?("config/dev.local.exs") do
  import_config("dev.local.exs")
end
