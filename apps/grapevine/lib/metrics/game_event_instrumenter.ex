defmodule Metrics.GameEventInstrumenter do
  @moduledoc """
  Instrumentation for a game's events
  """

  use Prometheus.Metric

  require Logger

  @doc false
  def setup() do
    events = [
      [:grapevine, :game_events, :create, :success],
      [:grapevine, :game_events, :create, :failure],
      [:grapevine, :game_events, :update, :success],
      [:grapevine, :game_events, :update, :failure],
      [:grapevine, :game_events, :delete, :success],
      [:grapevine, :game_events, :delete, :failure]
    ]

    :telemetry.attach_many("grapevine-game-events", events, &handle_event/4, nil)
  end

  def handle_event(
        [:grapevine, :game_events, :create, status],
        %{count: count},
        metadata,
        _config
      ) do
    Logger.debug(fn ->
      "Creating #{count} new game event(s) for game #{metadata[:game_id]} was a #{status}"
    end)
  end

  def handle_event(
        [:grapevine, :game_events, :update, status],
        %{count: count},
        metadata,
        _config
      ) do
    Logger.debug(fn ->
      "Updating #{count} game event(s) for game #{metadata[:game_id]} was a #{status}"
    end)
  end

  def handle_event(
        [:grapevine, :game_events, :delete, status],
        %{count: count},
        metadata,
        _config
      ) do
    Logger.debug(fn ->
      "Deleting #{count} game event(s) for game #{metadata[:game_id]} was a #{status}"
    end)
  end
end
