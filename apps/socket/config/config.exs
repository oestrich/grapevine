import Config

config :porcelain, driver: Porcelain.Driver.Basic
config :grapevine_socket, :pubsub, start: true

if File.exists?("config/#{Mix.env()}.exs") do
  import_config "#{Mix.env()}.exs"
end
