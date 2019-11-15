import Config

config :grapevine_socket, ecto_repos: [GrapevineData.Repo]
config :grapevine_socket, :pubsub, start: true

config :phoenix, :json_library, Jason

config :porcelain, driver: Porcelain.Driver.Basic
