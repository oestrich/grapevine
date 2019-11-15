import Config

config :grapevine_data, GrapevineData.Repo,
  database: "grapevine_dev",
  hostname: "localhost",
  pool_size: 10,
  log: false

config :grapevine_socket,
  topologies: [
    local: [
      strategy: Cluster.Strategy.Epmd,
      config: [hosts: [:grapevine@sisko, :socket@sisko]]
    ]
  ]
