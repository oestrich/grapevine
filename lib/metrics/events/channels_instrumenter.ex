defmodule Metrics.Events.ChannelsInstrumenter do
  @moduledoc """
  Instrumentation for channels
  """

  use Prometheus.Metric

  require Logger

  @doc false
  def setup() do
    events = [
      {:channels, :send},
      {:channels, :subscribe},
      {:channels, :unsubscribe}
    ]

    Counter.declare(
      name: :grapevine_events_channels_rate_limited_count,
      help: "Total count of a game being rate limited",
      labels: [:game_id]
    )

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

    events = [[:grapevine, :events, :channels, :rate_limited] | events]

    :telemetry.attach_many("grapevine-events-channels", events, &handle_event/4, nil)
  end

  def handle_event([:grapevine, :events, :channels, :rate_limited], _value, metadata, _config) do
    %{game: game} = metadata

    Logger.warn(fn ->
      "Rate limit hit for #{game.name} (#{game.id})"
    end)

    Counter.inc(name: :grapevine_events_channels_rate_limited_count, labels: [game.id])
  end

  def handle_event([:grapevine, :events, :channels, :send], _value, _metadata, _config) do
    Counter.inc(name: :grapevine_events_channels_send_count)
  end

  def handle_event([:grapevine, :events, :channels, :subscribe], _value, metadata, _config) do
    %{channel: channel_name} = metadata

    Logger.debug(fn ->
      "A socket subscribed to #{channel_name}"
    end)

    Counter.inc(name: :grapevine_events_channels_subscribe_count)
  end

  def handle_event([:grapevine, :events, :channels, :unsubscribe], _value, metadata, _config) do
    %{channel: channel_name} = metadata

    Logger.debug(fn ->
      "A socket unsubscribed to #{channel_name}"
    end)

    Counter.inc(name: :grapevine_events_channels_unsubscribe_count)
  end
end
