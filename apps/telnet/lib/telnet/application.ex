defmodule GrapevineTelnet.Application do
  @moduledoc false

  use Application

  @default_metrics_config [server: true, host: [port: 4101]]
  @metrics Application.get_env(:grapevine_telnet, :metrics) || []

  def start(_type, _args) do
    children = [
      cluster_supervisor(),
      metrics_plug(),
      phoenix_pubsub(),
      {GrapevineTelnet.ClientSupervisor, [name: {:global, GrapevineTelnet.ClientSupervisor}]},
      {GrapevineTelnet.Presence, []},
      {:telemetry_poller, telemetry_opts()}
    ]

    report_errors = Application.get_env(:grapevine_telnet, :errors)[:report]

    if report_errors do
      {:ok, _} = Logger.add_backend(Sentry.LoggerBackend)
    end

    GrapevineTelnet.Metrics.Setup.setup()

    children = Enum.reject(children, &is_nil/1)
    opts = [strategy: :one_for_one, name: GrapevineTelnet.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp cluster_supervisor() do
    topologies = Application.get_env(:grapevine_telnet, :topologies)

    if topologies && Code.ensure_compiled?(Cluster.Supervisor) do
      {Cluster.Supervisor, [topologies, [name: GrapevineTelnet.ClusterSupervisor]]}
    end
  end

  defp telemetry_opts() do
    [
      measurements: [
        {GrapevineTelnet.Metrics.ClientInstrumenter, :dispatch_client_count, []}
      ],
      name: GrapevineTelnet.Poller,
      period: 10_000
    ]
  end

  defp metrics_plug() do
    metrics = Keyword.merge(@default_metrics_config, @metrics)

    if metrics[:server] do
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: GrapevineTelnet.Endpoint,
        options: metrics[:host]
      )
    end
  end

  defp phoenix_pubsub() do
    pubsub = Application.get_env(:grapevine_telnet, :pubsub)

    if pubsub[:start] do
      {Phoenix.PubSub.PG2, [name: Grapevine.PubSub]}
    end
  end
end
