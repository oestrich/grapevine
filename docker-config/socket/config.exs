import Config

config :grapevine_socket, :pubsub, start: true

config :grapevine_data, GrapevineData.Repo,
  hostname: "postgres",
  database: "grapevine",
  username: "grapevine",
  password: "grapevine",
  pool_size: 10

config :grapevine,
  topologies: [
    local: [
      strategy: Cluster.Strategy.Epmd,
      config: [hosts: [:grapevine@web, :telnet@telnet, :socket@socket]]
    ]
  ]
