defmodule Metrics.ClientInstrumenter do
  @moduledoc """
  Instrumentation for sockets
  """

  use Prometheus.Metric

  require Logger

  alias Metrics.Server

  @doc false
  def setup() do
    Gauge.declare(
      name: :grapevine_client_count,
      help: "Number of clients grapevine has open"
    )

    events = [
      [:grapevine, :clients, :online]
    ]

    :telemetry.attach_many("grapevine-clients", events, &handle_event/4, nil)
  end

  @doc """
  Dispatch a clients online telemetry execute

  Called from the telemetry-poller
  """
  def dispatch_client_count() do
    :telemetry.execute([:grapevine, :clients, :online], Server.online_clients(), %{})
  end

  def handle_event([:grapevine, :clients, :online], count, _metadata, _config) do
    Gauge.set([name: :grapevine_client_count], count)
  end
end
