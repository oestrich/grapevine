defmodule Metrics.ChannelsInstrumenter do
  @moduledoc """
  Instrumentation for channels
  """

  use Prometheus.Metric

  require Logger

  @doc false
  def setup() do
    Counter.declare(
      name: :gossip_channel_message_count,
      help: "Total count of messages being sent on channels"
    )

    Counter.declare(
      name: :gossip_channel_subscribe_count,
      help: "Total count of channel subscribe events"
    )

    Counter.declare(
      name: :gossip_channel_unsubscribe_count,
      help: "Total count of channel unsubscribe events"
    )

    events = [
      [:gossip, :channels, :send],
      [:gossip, :channels, :subscribe],
      [:gossip, :channels, :unsubscribe]
    ]

    Telemetry.attach_many("gossip-channels", events, __MODULE__, :handle_event, nil)
  end

  def handle_event([:gossip, :channels, :send], _value, _metadata, _config) do
    Counter.inc(name: :gossip_channel_message_count)
  end

  def handle_event([:gossip, :channels, :subscribe], _value, %{channel: channel_name}, _config) do
    Logger.debug(fn ->
      "A socket subscribed to #{channel_name}"
    end)

    Counter.inc(name: :gossip_channel_subscribe_count)
  end

  def handle_event([:gossip, :channels, :unsubscribe], _value, %{channel: channel_name}, _config) do
    Logger.debug(fn ->
      "A socket unsubscribed to #{channel_name}"
    end)

    Counter.inc(name: :gossip_channel_unsubscribe_count)
  end
end
