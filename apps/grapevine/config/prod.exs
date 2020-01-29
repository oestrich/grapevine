import Config

config :grapevine, :decanter, enabled: false

host = System.get_env("WEB_HOST", "grapevine.haus")
scheme = System.get_env("WEB_SCHEME", "https")
port = String.to_integer(System.get_env("WEB_PORT", "443"))

config :grapevine, :web, url: [host: host, scheme: scheme, port: port]

config :logger, level: :info, backends: [:console, Timber.LoggerBackends.HTTP], utc_log: true
