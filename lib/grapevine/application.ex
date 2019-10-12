defmodule Grapevine.Application do
  @moduledoc false

  use Application

  @env Mix.env()

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      cluster_supervisor(),
      supervisor(Web.Endpoint, []),
      {Socket.Application, [name: Socket.Application]},
      {Grapevine.Presence, [name: Grapevine.Presence]},
      {Grapevine.PlayerPresence, [name: Grapevine.PlayerPresence]},
      {Grapevine.Client.Server, [name: Grapevine.Client.Server]},
      {Metrics.Server, []},
      {:telemetry_poller, telemetry_opts()},
      {Grapevine.Telnet.Worker, [name: Grapevine.Telnet.Worker]},
      {Grapevine.CNAMEs, [name: Grapevine.CNAMEs]},
      {Grapevine.Featured, [name: Grapevine.Featured]},
      {Grapevine.Statistics.Server, []},
      {Grapevine.Notifications, []}
    ]

    Metrics.Setup.setup()

    report_errors = Application.get_env(:grapevine, :errors)[:report]

    if report_errors do
      Logger.add_backend(Sentry.LoggerBackend)
    end

    start_telnet_application()

    children = Enum.reject(children, &is_nil/1)
    opts = [strategy: :one_for_one, name: Grapevine.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    Web.Endpoint.config_change(changed, removed)
    :ok
  end

  defp cluster_supervisor() do
    topologies = Application.get_env(:grapevine, :topologies)

    if topologies && Code.ensure_compiled?(Cluster.Supervisor) do
      {Cluster.Supervisor, [topologies, [name: Grapevine.ClusterSupervisor]]}
    end
  end

  defp telemetry_opts() do
    [
      measurements: [
        {Metrics.GameInstrumenter, :dispatch_game_count, []},
        {Metrics.SocketInstrumenter, :dispatch_socket_count, []}
      ],
      name: Grapevine.Poller,
      period: 10_000
    ]
  end

  # Start the telnet application in development mode
  defp start_telnet_application() do
    if @env == :dev do
      :application.start(:telnet)
      :application.start(:grapevine_telnet)
    end
  end
end
