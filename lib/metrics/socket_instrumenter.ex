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
      name: :grapevine_socket_count,
      help: "Number of sockets connected to grapevine"
    )

    Counter.declare(
      name: :grapevine_socket_heartbeat_count,
      help: "Total count of heartbeats"
    )

    Counter.declare(
      name: :grapevine_socket_heartbeat_disconnect_count,
      help: "Total count of disconnects due to heartbeat misses"
    )

    Counter.declare(
      name: :grapevine_socket_connect_count,
      help: "Total count of sockets connecting"
    )

    Counter.declare(
      name: :grapevine_socket_connect_success_count,
      help: "Total count of successful sockets connecting"
    )

    Counter.declare(
      name: :grapevine_socket_connect_failure_count,
      help: "Total count of failed sockets connecting"
    )

    Counter.declare(
      name: :grapevine_socket_unknown_event_count,
      help: "Total count of unknown events sent to the socket"
    )

    events = [
      [:grapevine, :sockets, :connect],
      [:grapevine, :sockets, :connect, :failure],
      [:grapevine, :sockets, :connect, :success],
      [:grapevine, :sockets, :events, :unknown],
      [:grapevine, :sockets, :heartbeat],
      [:grapevine, :sockets, :heartbeat, :disconnect],
      [:grapevine, :sockets, :online]
    ]

    :telemetry.attach_many("grapevine-sockets", events, &handle_event/4, nil)
  end

  @doc """
  Dispatch a sockets online telemetry execute

  Called from the telemetry-poller
  """
  def dispatch_socket_count() do
    :telemetry.execute([:grapevine, :sockets, :online], %{count: Server.online_sockets()}, %{})
  end

  def handle_event([:grapevine, :sockets, :online], %{count: count}, _metadata, _config) do
    Gauge.set([name: :grapevine_socket_count], count)
  end

  def handle_event([:grapevine, :sockets, :heartbeat], _count, %{payload: payload}, _config) do
    Logger.debug(fn ->
      "HEARTBEAT: #{inspect(payload)}"
    end)

    Counter.inc(name: :grapevine_socket_heartbeat_count)
  end

  def handle_event([:grapevine, :sockets, :heartbeat, :disconnect], _count, _metadata, _config) do
    Logger.debug("Inactive heartbeat", type: :heartbeat)
    Counter.inc(name: :grapevine_socket_heartbeat_disconnect_count)
  end

  def handle_event([:grapevine, :sockets, :connect], _count, _metadata, _config) do
    Counter.inc(name: :grapevine_socket_connect_count)
  end

  def handle_event([:grapevine, :sockets, :connect, :success], _count, metadata, _config) do
    Logger.info(fn ->
      channels = inspect(metadata.channels)
      supports = inspect(metadata.supports)

      "Authenticated #{metadata.game} - subscribed to #{channels} - supports #{supports}"
    end)

    Counter.inc(name: :grapevine_socket_connect_success_count)
  end

  def handle_event([:grapevine, :sockets, :connect, :failure], _count, %{reason: reason}, _config) do
    Logger.debug(fn ->
      "Disconnecting a socket - #{reason}"
    end)

    Counter.inc(name: :grapevine_socket_connect_failure_count)
  end

  def handle_event([:grapevine, :sockets, :events, :unknown], _count, metadata, _config) do
    Logger.warn(fn ->
      "Getting an unknown frame - #{inspect(metadata.state)} - #{inspect(metadata.frame)}"
    end)

    Counter.inc(name: :grapevine_socket_unknown_event_count)
  end
end
