defmodule GrapevineSocket.MixProject do
  use Mix.Project

  def project do
    [
      app: :grapevine_socket,
      version: "2.3.0",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {GrapevineSocket.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:elixir_uuid, "~> 1.2"},
      {:grapevine_data, path: "../data"},
      {:jason, "~> 1.1"},
      {:libcluster, "~> 3.0"},
      {:phoenix, "~> 1.4"},
      {:phoenix_pubsub, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:prometheus_ex, "~> 3.0"},
      {:prometheus_plugs, "~> 1.1.1"},
      {:sentry, "~> 7.0"},
      {:telemetry, "~> 0.4"},
      {:telemetry_poller, "~> 0.2"},
      {:timex, "~> 3.1"}
    ]
  end

  defp releases() do
    [
      grapevine_socket: [
        include_executables_for: [:unix],
        applications: [
          runtime_tools: :permanent
        ],
        config_providers: [{GrapevineSocket.ConfigProvider, "/etc/grapevine_socket/config.exs"}]
      ]
    ]
  end
end
