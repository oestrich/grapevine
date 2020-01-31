import Config

config :grapevine_data, GrapevineData.Repo,
  hostname: "postgres",
  database: "grapevine",
  username: "grapevine",
  password: "grapevine",
  pool_size: 10

config :grapevine, Web.Endpoint,
  secret_key_base: "4l9YWUraPyMz6OzreZ83U3La1xnI82ZYsnAskKzZin+yKQI8xPuV3VeCRoGRiNhK",
  url: [host: "grapevine.local", port: 80, scheme: "http"],
  cache_static_manifest: "priv/static/cache_manifest.json"

config :grapevine, :web, url: [host: "grapevine.local", scheme: "http", port: 80]

config :grapevine,
  topologies: [
    local: [
      strategy: Cluster.Strategy.Epmd,
      config: [hosts: [:grapevine@web, :telnet@telnet, :socket@socket]]
    ]
  ]

config :grapevine, :recaptcha, enabled: false

config :grapevine, :socket, tls: false

config :grapevine, :errors, report: false

config :grapevine, Grapevine.Mailer,
  alert_to: ["admin@example.com"],
  adapter: Bamboo.LocalAdapter

config :stein, :storage, backend: :file
