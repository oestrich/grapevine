defmodule Grapevine.Application do
  @moduledoc false

  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Grapevine.Repo, []),
      supervisor(Web.Endpoint, []),
      {Grapevine.Presence, []},
      {Grapevine.Client.Server, [name: Grapevine.Client.Server]},
      {Metrics.Server, []},
      {Telemetry.Poller, telemetry_opts()},
      {Grapevine.Telnet.Worker, [name: Grapevine.Telnet.Worker]}
    ]

    Metrics.Setup.setup()

    report_errors = Application.get_env(:grapevine, :errors)[:report]

    if report_errors do
      {:ok, _} = Logger.add_backend(Sentry.LoggerBackend)
    end

    opts = [strategy: :one_for_one, name: Grapevine.Supervisor]
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
        {Metrics.SocketInstrumenter, :dispatch_socket_count, []}
      ],
      period: 10_000
    ]
  end
end
