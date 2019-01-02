defmodule Metrics.StatisticsInstrumenter do
  @moduledoc """
  Instrumentation for statistic recording
  """

  use Prometheus.Metric

  require Logger

  @doc false
  def setup() do
    events = [
      {:players, :record},
    ]

    Enum.each(events, fn {noun, event} ->
      Counter.declare(
        name: String.to_atom("gossip_statistics_#{noun}_#{event}_count"),
        help: "Total count of tracking for #{noun} #{event}"
      )
    end)

    events = Enum.map(events, fn {module, event} ->
      [:gossip, :statistics, module, event]
    end)

    :telemetry.attach_many("gossip-statistics", events, &handle_event/4, nil)
  end

  def handle_event([:gossip, :statistics, :players, :record], _value, _metadata, _config) do
    Counter.inc(name: :gossip_statistics_players_record_count)
  end
end
