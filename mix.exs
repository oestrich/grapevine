defmodule Grapevine.Mixfile do
  use Mix.Project

  def project do
    [
      app: :grapevine,
      version: "2.3.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Grapevine.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bamboo, "~> 1.1"},
      {:bamboo_smtp, "~> 1.5"},
      {:briefly, "~> 0.3"},
      {:cowboy, "~> 2.0"},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:discourse, "~> 0.0.1"},
      {:distillery, "~> 2.0", runtime: false},
      {:earmark, "~> 1.2"},
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0"},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:gettext, "~> 0.11"},
      {:grapevine_telnet, path: "./apps/telnet/", runtime: false},
      {:hackney, "~> 1.9"},
      {:jason, "~> 1.1"},
      {:libcluster, "~> 3.0"},
      {:logster, "~> 0.10.0"},
      {:phoenix, "~> 1.4", override: true},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_live_view, github: "phoenixframework/phoenix_live_view"},
      {:phoenix_pubsub, "~> 1.0"},
      {:pid_file, "~> 0.1.0"},
      {:plug_cowboy, "~> 2.0", override: true},
      {:poison, "~> 3.0"},
      {:porcelain, "~> 2.0"},
      {:postgrex, ">= 0.0.0"},
      {:prometheus_ex, git: "https://github.com/deadtrickster/prometheus.ex.git", override: true},
      {:prometheus_plugs, "~> 1.1.1"},
      {:sentry, "~> 7.0"},
      {:stein, git: "https://github.com/smartlogic/stein.git"},
      {:sweet_xml, "~> 0.6"},
      {:telemetry, "~> 0.3"},
      {:telemetry_poller, "~> 0.2"},
      {:telnet, git: "https://github.com/oestrich/telnet-elixir.git"},
      {:timber, "~> 3.0"},
      {:timex, "~> 3.1"},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.migrate.reset": ["ecto.drop", "ecto.create", "ecto.migrate"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
