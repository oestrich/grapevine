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
      {:channels, :unsubscribe},
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

    :telemetry.attach_many("gossip-events-channels", events, &handle_event/4, nil)
  end

  def handle_event([:gossip, :events, :channels, :send], _value, _metadata, _config) do
    Counter.inc(name: :gossip_events_channels_send_count)
  end

  def handle_event([:gossip, :events, :channels, :subscribe], _value, %{channel: channel_name}, _config) do
    Logger.debug(fn ->
      "A socket subscribed to #{channel_name}"
    end)

    Counter.inc(name: :gossip_events_channels_subscribe_count)
  end

  def handle_event([:gossip, :events, :channels, :unsubscribe], _value, %{channel: channel_name}, _config) do
    Logger.debug(fn ->
      "A socket unsubscribed to #{channel_name}"
    end)

    Counter.inc(name: :gossip_events_channels_unsubscribe_count)
  end
end
