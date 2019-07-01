import Config

config(:grapevine, Web.Endpoint,
  http: [port: 4100],
  url: [host: "grapevine.haus", port: 443, scheme: "https"],
  cache_static_manifest: "priv/static/cache_manifest.json"
)

config(:grapevine_data, GrapevineData.Repo, pool_size: 10, log: false)

config(:phoenix, :serve_endpoints, true)

config(:stein, :storage, backend: :s3)

config(:sentry,
  environment_name: :prod,
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  tags: %{env: "production"},
  included_environments: [:prod]
)
