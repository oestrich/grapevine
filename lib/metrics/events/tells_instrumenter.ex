defmodule Metrics.Events.TellsInstrumenter do
  @moduledoc """
  Instrumentation for channels
  """

  use Prometheus.Metric

  require Logger

  @doc false
  def setup() do
    events = [
      {:tells, :send},
    ]

    Enum.each(events, fn {module, event} ->
      Counter.declare(
        name: String.to_atom("gossip_events_#{module}_#{event}_count"),
        help: "Total count of '#{module}/#{event}' events sent from the client"
      )
    end)

    events = Enum.map(events, fn {module, event} ->
      [:gossip, :events, module, event]
    end)

    :telemetry.attach_many("gossip-events-tells", events, &handle_event/4, nil)
  end

  def handle_event([:gossip, :events, :tells, :send], _value, _metadata, _config) do
    Counter.inc(name: :gossip_events_tells_send_count)
  end
end
