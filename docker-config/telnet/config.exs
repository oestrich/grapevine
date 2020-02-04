import Config

config :grapevine_telnet, :pubsub, start: true

config :grapevine_telnet,
  topologies: [
    local: [
      strategy: Cluster.Strategy.Epmd,
      config: [hosts: [:grapevine@web, :telnet@telnet, :socket@socket]]
    ]
  ]
