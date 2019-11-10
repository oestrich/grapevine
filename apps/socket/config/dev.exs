import Config

config :grapevine_data, GrapevineData.Repo,
  database: "grapevine_dev",
  hostname: "localhost",
  pool_size: 10,
  log: false
