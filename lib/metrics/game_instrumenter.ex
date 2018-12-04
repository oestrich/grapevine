defmodule Metrics.GameInstrumenter do
  @moduledoc """
  Instrumentation for games
  """

  use Prometheus.Metric

  alias Gossip.Presence

  @doc false
  def setup() do
    Gauge.declare(
      name: :gossip_game_count,
      help: "Number of games connected to gossip"
    )

    events = [
      [:gossip, :games, :online]
    ]

    Telemetry.attach_many("gossip-games", events, __MODULE__, :handle_event, nil)
  end

  def dispatch_game_count() do
    count = length(Presence.online_games())
    Telemetry.execute([:gossip, :games, :online], count, %{})
  end

  def handle_event([:gossip, :games, :online], count, _metadata, _config) do
    Gauge.set([name: :gossip_game_count], count)
  end
end
