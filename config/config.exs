# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :gossip,
  namespace: Web,
  ecto_repos: [Gossip.Repo]

# Configures the endpoint
config :gossip, Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Pqncs1RkrPq/7DiOEo/7U0DGsm503zjPQMerRQO3YVFUtOXpDq6PKI5xBfwBCWmB",
  render_errors: [view: Web.ErrorView, accepts: ~w(html json)],
  http: [dispatch: [
    {:_, [
      {"/socket", Web.SocketHandler, []},
      {:_, Phoenix.Endpoint.Cowboy2Handler, {Web.Endpoint, []}}
    ]}]],
  pubsub: [name: Gossip.PubSub,
           adapter: Phoenix.PubSub.PG2]

config :gossip, :socket, tls: false

config :gossip, :errors, report: false

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

config :distillery, no_warn_missing: [:elixir_make]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
