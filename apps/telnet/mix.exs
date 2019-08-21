defmodule GrapevineTelnet.MixProject do
  use Mix.Project

  def project do
    [
      app: :grapevine_telnet,
      version: "1.0.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {GrapevineTelnet.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:elixir_uuid, "~> 1.2"},
      {:jason, "~> 1.1"},
      {:libcluster, "~> 3.0"},
      {:plug_cowboy, "~> 2.0"},
      {:phoenix, "~> 1.4", override: true},
      {:phoenix_pubsub, "~> 1.0"},
      {:prometheus_ex, "~> 3.0"},
      {:prometheus_plugs, "~> 1.1.1"},
      {:sentry, "~> 7.0"},
      {:telemetry, "~> 0.3"},
      {:telemetry_poller, "~> 0.2"},
      {:telnet, git: "https://github.com/oestrich/telnet-elixir.git"},
      {:timex, "~> 3.1"}
    ]
  end

  defp releases() do
    [
      telnet: [
        include_executables_for: [:unix],
        applications: [
          grapevine_telnet: :permanent,
          runtime_tools: :permanent
        ],
        config_providers: [{GrapevineTelnet.ConfigProvider, "/etc/telnet/config.exs"}]
      ]
    ]
  end
end
