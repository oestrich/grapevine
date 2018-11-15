defmodule Metrics.Events.PlayersInstrumenter do
  @moduledoc """
  Instrumentation for channels
  """

  use Prometheus.Metric

  require Logger

  @doc false
  def setup() do
    events = [
      {:players, :sign_in},
      {:players, :sign_out},
      {:players, :status},
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

    Telemetry.attach_many("gossip-events-players", events, __MODULE__, :handle_event, nil)
  end

  def handle_event([:gossip, :events, :players, :sign_in], _value, _metadata, _config) do
    Counter.inc(name: :gossip_events_players_sign_in_count)
  end

  def handle_event([:gossip, :events, :players, :sign_out], _value, _metadata, _config) do
    Counter.inc(name: :gossip_events_players_sign_out_count)
  end

  def handle_event([:gossip, :events, :players, :status], _value, _metadata, _config) do
    Counter.inc(name: :gossip_events_players_status_count)
  end
end
