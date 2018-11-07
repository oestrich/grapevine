defmodule Gossip.Application do
  @moduledoc false

  use Application

  @report_errors Application.get_env(:gossip, :errors)[:report]

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Gossip.Repo, []),
      supervisor(Web.Endpoint, []),
      {Gossip.Presence, []},
      {Metrics.Server, []},
      {Telemetry.Poller, telemetry_opts()},
    ]

    Metrics.Setup.setup()

    if @report_errors do
      {:ok, _} = Logger.add_backend(Sentry.LoggerBackend)
    end

    opts = [strategy: :one_for_one, name: Gossip.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    Web.Endpoint.config_change(changed, removed)
    :ok
  end

  defp telemetry_opts() do
    [
      measurements: [
        {Metrics.GameInstrumenter, :dispatch_game_count, []},
      ],
      period: 10_000
    ]
  end
end
