defmodule Metrics.StatisticsInstrumenter do
  @moduledoc """
  Instrumentation for statistic recording
  """

  use Prometheus.Metric

  require Logger

  @doc false
  def setup() do
    events = [
      {:players, :record}
    ]

    Enum.each(events, fn {noun, event} ->
      Counter.declare(
        name: String.to_atom("grapevine_statistics_#{noun}_#{event}_count"),
        help: "Total count of tracking for #{noun} #{event}"
      )
    end)

    events =
      Enum.map(events, fn {module, event} ->
        [:grapevine, :statistics, module, event]
      end)

    :telemetry.attach_many("grapevine-statistics", events, &handle_event/4, nil)
  end

  def handle_event([:grapevine, :statistics, :players, :record], _value, _metadata, _config) do
    Counter.inc(name: :grapevine_statistics_players_record_count)
  end
end
