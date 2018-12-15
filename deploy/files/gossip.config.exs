use Mix.Config

# In this file, we keep production configuration that
# you'll likely want to automate and keep away from
# your version control system.
#
# You should document the content of this
# file or create a script for recreating it, since it's
# kept out of version control and might be hard to recover
# or recreate for your teammates (or yourself later on).
config :gossip, Web.Endpoint,
  secret_key_base: ""

config :gossip, Web.Endpoint,
  url: [host: "gossip.haus", port: 443, scheme: "https"],
  cache_static_manifest: "priv/static/cache_manifest.json"

config :gossip, :socket, tls: true

# Configure your database
config :gossip, Gossip.Repo,
  database: "gossip",
  hostname: "localhost",
  pool_size: 10

config :gossip, :errors, report: true

config :sentry,
  dsn: "",
  environment_name: :prod,
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  tags: %{env: "production"},
  included_environments: [:prod]

config :gossip, :grapevine, cors_host: "https://grapevine.haus"
