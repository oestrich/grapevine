use Mix.Config

config :grapevine, :socket, tls: true

config :grapevine, GrapevineData.Repo,
  database: "grapevine",
  hostname: "localhost",
  pool_size: 10

config :grapevine, :errors, report: true

config :sentry,
  dsn: "",
  environment_name: :prod,
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  tags: %{env: "production"},
  included_environments: [:prod]
