defmodule Metrics.GameInstrumenter do
  @moduledoc """
  Instrumentation for games
  """

  use Prometheus.Metric

  alias Socket.Presence

  @doc false
  def setup() do
    Gauge.declare(
      name: :grapevine_game_online_count,
      help: "Number of games connected to grapevine"
    )

    Counter.declare(
      name: :grapevine_game_create_total,
      help: "Number of created games"
    )

    events = [
      [:grapevine, :games, :online],
      [:grapevine, :games, :create]
    ]

    :telemetry.attach_many("grapevine-games", events, &handle_event/4, nil)
  end

  def dispatch_game_count() do
    count = length(Presence.online_games())
    :telemetry.execute([:grapevine, :games, :online], %{count: count}, %{})
  end

  def handle_event([:grapevine, :games, :online], %{count: count}, _metadata, _config) do
    Gauge.set([name: :grapevine_game_online_count], count)
  end

  def handle_event([:grapevine, :games, :create], _count, _metadata, _config) do
    Counter.inc(name: :grapevine_game_create_total)
  end
end
