import Config

config :grapevine, :web, url: [host: "grapevine.haus", scheme: "https", port: 443]

config :logger, level: :info, backends: [:console, Timber.LoggerBackends.HTTP], utc_log: true
