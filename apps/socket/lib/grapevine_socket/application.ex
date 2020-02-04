defmodule GrapevineSocket.Application do
  @moduledoc """
  Supervisor for the Grapevine socket

  A supervisor hoping to become a full fledged application
  """

  use Application

  @default_config [port: 4110]

  def start(_type, _args) do
    children = [
      cluster_supervisor(),
      phoenix_pubsub(),
      {GrapevineSocket.Presence, []},
      {GrapevineSocket.Metrics.Server, []},
      endpoint(),
      {:telemetry_poller, telemetry_opts()},
      {GrapevineSocket.Channels, [name: {:global, GrapevineSocket.Channels}]}
    ]

    report_errors = Application.get_env(:grapevine_socket, :errors)[:report]

    if report_errors do
      {:ok, _} = Logger.add_backend(Sentry.LoggerBackend)
    end

    GrapevineSocket.Metrics.Setup.setup()

    children = Enum.reject(children, &is_nil/1)
    opts = [strategy: :one_for_one, name: GrapevineSocket.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatch() do
    [
      {:_,
       [
         {"/socket", GrapevineSocket.Web.SocketHandler, []},
         {:_, Plug.Cowboy.Handler, {GrapevineSocket.Endpoint, []}}
       ]}
    ]
  end

  defp telemetry_opts() do
    [
      measurements: [
        {GrapevineSocket.Metrics.SocketInstrumenter, :dispatch_socket_count, []}
      ],
      name: GrapevineSocket.Poller,
      period: 10_000
    ]
  end

  defp phoenix_pubsub() do
    pubsub = Application.get_env(:grapevine_socket, :pubsub)

    if pubsub[:start] do
      {Phoenix.PubSub.PG2, [name: Grapevine.PubSub]}
    end
  end

  defp cluster_supervisor() do
    topologies = Application.get_env(:grapevine_socket, :topologies)

    if topologies do
      {Cluster.Supervisor, [topologies, [name: GrapevineSocket.ClusterSupervisor]]}
    end
  end

  defp endpoint() do
    config = Application.get_env(:grapevine_socket, :http, [])
    config = Keyword.merge(@default_config, config)

    Plug.Cowboy.child_spec(
      scheme: :http,
      plug: GrapevineSocket.Endpoint,
      options: [port: config[:port], dispatch: dispatch()]
    )
  end
end
