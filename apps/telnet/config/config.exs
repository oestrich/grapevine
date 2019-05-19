use Mix.Config

config :phoenix, :json_library, Jason
config :grapevine_telnet, :pubsub, start: true
config :grapevine_telnet, :errors, report: false

if File.exists?("config/#{Mix.env()}.exs") do
  import_config("#{Mix.env()}.exs")
end
