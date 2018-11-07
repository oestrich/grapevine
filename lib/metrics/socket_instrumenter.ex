defmodule Metrics.SocketInstrumenter do
  @moduledoc """
  Instrumentation for sockets
  """

  use Prometheus.Metric

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
      [:gossip, :sockets, :online]
    ]

    Telemetry.attach_many("grapevine-sockets", events, __MODULE__, :handle_event, nil)
  end

  def dispatch_socket_count() do
    Telemetry.execute([:gossip, :sockets, :online], Server.online_sockets(), %{})
  end

  def handle_event([:gossip, :sockets, :online], count, _metadata, _config) do
    Gauge.set([name: :gossip_socket_count], count)
  end

  def heartbeat() do
    Counter.inc(name: :gossip_socket_heartbeat_count)
  end

  def heartbeat_disconnect() do
    Counter.inc(name: :gossip_socket_heartbeat_disconnect_count)
  end

  def connect() do
    Counter.inc(name: :gossip_socket_connect_count)
  end

  def connect_success() do
    Counter.inc(name: :gossip_socket_connect_success_count)
  end

  def connect_failure() do
    Counter.inc(name: :gossip_socket_connect_failure_count)
  end

  def unknown_event() do
    Counter.inc(name: :gossip_socket_unknown_event_count)
  end
end
