defmodule Metrics.Events.GamesInstrumenter do
  @moduledoc """
  Instrumentation for events
  """

  use Prometheus.Metric

  @doc false
  def setup() do
    events = [
      {:games, :status},
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

    Telemetry.attach_many("gossip-events-games", events, __MODULE__, :handle_event, nil)
  end

  def handle_event([:gossip, :events, :games, :status], _count, _metadata, _config) do
    Counter.inc(name: :gossip_events_games_status_count)
  end
end
