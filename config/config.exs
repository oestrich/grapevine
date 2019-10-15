import Config

config(:grapevine, namespace: Web, ecto_repos: [GrapevineData.Repo])

config(:grapevine, :decanter, enabled: true)

config :grapevine, Web.Endpoint,
  secret_key_base: "Pqncs1RkrPq/7DiOEo/7U0DGsm503zjPQMerRQO3YVFUtOXpDq6PKI5xBfwBCWmB",
  live_view: [signing_salt: "SWvL1X6M5XJHDfJjnWxhzUU4P5wwzIjR"],
  render_errors: [view: Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Grapevine.PubSub, adapter: Phoenix.PubSub.PG2]

config :grapevine, :modules,
  telnet: Grapevine.Telnet.Worker,
  client: Grapevine.Client.Server

# runtime
config(:grapevine, Grapevine.Mailer, alert_to: [])

config(:grapevine, :errors, report: false)

config(:grapevine, :socket, tls: false)

# Configures Elixir's Logger
config(:bamboo, :json_library, Jason)

config(:ecto_sql, :json_library, Jason)

config(:logger, :console, format: "$time $metadata[$level] $message\n", metadata: [:user_id])

config(:phoenix, :json_library, Jason)

config(:phoenix, template_engines: [leex: Phoenix.LiveView.Engine])

config(:porcelain, driver: Porcelain.Driver.Basic)

config(:postgrex, :json_library, Jason)

config(:sentry, filter: Grapevine.SentryFilter, json_library: Jason)

config(:stein, :storage, backend: :file)

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
