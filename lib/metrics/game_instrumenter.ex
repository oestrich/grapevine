defmodule Metrics.GameInstrumenter do
  @moduledoc """
  Instrumentation for games
  """

  use Prometheus.Metric

  @doc false
  def setup() do
    Gauge.declare(
      name: :gossip_game_count,
      help: "Number of games connected to gossip"
    )
  end

  def set_games(count) do
    Gauge.set([name: :gossip_game_count], count)
  end
end
