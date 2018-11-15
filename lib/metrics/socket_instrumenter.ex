defmodule Metrics.SocketInstrumenter do
  @moduledoc """
  Instrumentation for sockets
  """

  use Prometheus.Metric

  require Logger

  alias Metrics.Server

  @doc false
  def setup() do
    Gauge.declare(
      name: :gossip_socket_count,
      help: "Number of sockets connected to gossip"
    )

    Counter.declare(
      name: :gossip_socket_heartbeat_count,
      help: "Total count of heartbeats"
    )

    Counter.declare(
      name: :gossip_socket_heartbeat_disconnect_count,
      help: "Total count of disconnects due to heartbeat misses"
    )

    Counter.declare(
      name: :gossip_socket_connect_count,
      help: "Total count of sockets connecting"
    )

    Counter.declare(
      name: :gossip_socket_connect_success_count,
      help: "Total count of successful sockets connecting"
    )

    Counter.declare(
      name: :gossip_socket_connect_failure_count,
      help: "Total count of failed sockets connecting"
    )

    Counter.declare(
      name: :gossip_socket_unknown_event_count,
      help: "Total count of unknown events sent to the socket"
    )

    events = [
      [:gossip, :sockets, :connect],
      [:gossip, :sockets, :connect, :failure],
      [:gossip, :sockets, :connect, :success],
      [:gossip, :sockets, :events, :unknown],
      [:gossip, :sockets, :heartbeat],
      [:gossip, :sockets, :heartbeat, :disconnect],
      [:gossip, :sockets, :online],
    ]

    Telemetry.attach_many("gossip-sockets", events, __MODULE__, :handle_event, nil)
  end

  @doc """
  Dispatch a sockets online telemetry execute

  Called from the telemetry-poller
  """
  def dispatch_socket_count() do
    Telemetry.execute([:gossip, :sockets, :online], Server.online_sockets(), %{})
  end

  def handle_event([:gossip, :sockets, :online], count, _metadata, _config) do
    Gauge.set([name: :gossip_socket_count], count)
  end

  def handle_event([:gossip, :sockets, :heartbeat], _count, %{payload: payload}, _config) do
    Logger.debug(fn ->
      "HEARTBEAT: #{inspect(payload)}"
    end)

    Counter.inc(name: :gossip_socket_heartbeat_count)
  end

  def handle_event([:gossip, :sockets, :heartbeat, :disconnect], _count, _metadata, _config) do
    Logger.debug("Inactive heartbeat", type: :heartbeat)
    Counter.inc(name: :gossip_socket_heartbeat_disconnect_count)
  end

  def handle_event([:gossip, :sockets, :connect], _count, _metadata, _config) do
    Counter.inc(name: :gossip_socket_connect_count)
  end

  def handle_event([:gossip, :sockets, :connect, :success], _count, metadata, _config) do
    Logger.info("Authenticated #{metadata.game} - subscribed to #{inspect(metadata.channels)} - supports #{inspect(metadata.supports)}")

    Counter.inc(name: :gossip_socket_connect_success_count)
  end

  def handle_event([:gossip, :sockets, :connect, :failure], _count, %{reason: reason}, _config) do
    Logger.debug(fn ->
      "Disconnecting a socket - #{reason}"
    end)

    Counter.inc(name: :gossip_socket_connect_failure_count)
  end

  def handle_event([:gossip, :sockets, :events, :unknown], _count, %{state: state, frame: frame}, _config) do
    Logger.warn("Getting an unknown frame - #{inspect(state)} - #{inspect(frame)}")
    Counter.inc(name: :gossip_socket_unknown_event_count)
  end
end
