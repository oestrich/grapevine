defmodule Metrics.GameEventInstrumenter do
  @moduledoc """
  Instrumentation for a game's events
  """

  use Prometheus.Metric

  require Logger

  @doc false
  def setup() do
    events = [
      [:gossip, :game_events, :create, :success],
      [:gossip, :game_events, :create, :failure],
      [:gossip, :game_events, :update, :success],
      [:gossip, :game_events, :update, :failure],
      [:gossip, :game_events, :delete, :success],
      [:gossip, :game_events, :delete, :failure],
    ]

    Telemetry.attach_many("gossip-game-events", events, __MODULE__, :handle_event, nil)
  end

  def handle_event([:gossip, :game_events, :create, status], count, metadata, _config) do
    Logger.debug(fn ->
      "Creating #{count} new game event(s) for game #{metadata[:game_id]} was a #{status}"
    end)
  end

  def handle_event([:gossip, :game_events, :update, status], count, metadata, _config) do
    Logger.debug(fn ->
      "Updating #{count} game event(s) for game #{metadata[:game_id]} was a #{status}"
    end)
  end

  def handle_event([:gossip, :game_events, :delete, status], count, metadata, _config) do
    Logger.debug(fn ->
      "Deleting #{count} game event(s) for game #{metadata[:game_id]} was a #{status}"
    end)
  end
end
