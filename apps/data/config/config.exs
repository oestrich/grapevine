use Mix.Config

config :grapevine_data, ecto_repos: [GrapevineData.Repo]

import_config "#{Mix.env()}.exs"
