# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :grapevine,
  namespace: Web,
  ecto_repos: [GrapevineData.Repo]

# Configures the endpoint
config :grapevine, Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Pqncs1RkrPq/7DiOEo/7U0DGsm503zjPQMerRQO3YVFUtOXpDq6PKI5xBfwBCWmB",
  live_view: [signing_salt: "SWvL1X6M5XJHDfJjnWxhzUU4P5wwzIjR"],
  render_errors: [view: Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Grapevine.PubSub, adapter: Phoenix.PubSub.PG2]

config :phoenix, template_engines: [leex: Phoenix.LiveView.Engine]

config :grapevine, :socket, tls: false

config :grapevine, :errors, report: false

config :grapevine, :modules,
  telnet: Grapevine.Telnet.Worker,
  client: Grapevine.Client.Server

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

config :distillery, no_warn_missing: [:elixir_make]

config :sentry,
  filter: Grapevine.SentryFilter,
  json_library: Jason

config :bamboo, :json_library, Jason
config :ecto_sql, :json_library, Jason
config :phoenix, :json_library, Jason
config :postgrex, :json_library, Jason

config :stein, :storage, backend: :file

config :porcelain, driver: Porcelain.Driver.Basic

config :grapevine, GrapevineData.Mailer, alert_to: []

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
