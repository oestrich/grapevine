defmodule Metrics.Events.GamesInstrumenter do
  @moduledoc """
  Instrumentation for events
  """

  use Prometheus.Metric

  @doc false
  def setup() do
    events = [
      {:games, :status}
    ]

    Enum.each(events, fn {module, event} ->
      Counter.declare(
        name: String.to_atom("grapevine_events_#{module}_#{event}_count"),
        help: "Total count of '#{module}/#{event}' events sent from the client"
      )
    end)

    events =
      Enum.map(events, fn {module, event} ->
        [:grapevine, :events, module, event]
      end)

    :telemetry.attach_many("grapevine-events-games", events, &handle_event/4, nil)
  end

  def handle_event([:grapevine, :events, :games, :status], _count, _metadata, _config) do
    Counter.inc(name: :grapevine_events_games_status_count)
  end
end
