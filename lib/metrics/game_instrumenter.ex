defmodule Metrics.GameInstrumenter do
  @moduledoc """
  Instrumentation for games
  """

  use Prometheus.Metric

  alias Gossip.Presence

  @doc false
  def setup() do
    Gauge.declare(
      name: :gossip_game_online_count,
      help: "Number of games connected to gossip"
    )

    Counter.declare(
      name: :gossip_game_create_total,
      help: "Number of created games"
    )

    events = [
      [:gossip, :games, :online],
      [:gossip, :games, :create]
    ]

    :telemetry.attach_many("gossip-games", events, &handle_event/4, nil)
  end

  def dispatch_game_count() do
    count = length(Presence.online_games())
    :telemetry.execute([:gossip, :games, :online], count, %{})
  end

  def handle_event([:gossip, :games, :online], count, _metadata, _config) do
    Gauge.set([name: :gossip_game_online_count], count)
  end

  def handle_event([:gossip, :games, :create], _count, _metadata, _config) do
    Counter.inc(name: :gossip_game_create_total)
  end
end
