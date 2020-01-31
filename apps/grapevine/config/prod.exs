import Config

config :grapevine, :decanter, enabled: false

config :logger, level: :info, backends: [:console, Timber.LoggerBackends.HTTP], utc_log: true
