defmodule Metrics.ChannelsInstrumenter do
  @moduledoc """
  Instrumentation for channels
  """

  use Prometheus.Metric

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
  end

  @doc """
  A new message was sent on a channel
  """
  def send() do
    Counter.inc(name: :gossip_channel_message_count)
  end

  @doc """
  A channels/subscribe event
  """
  def subscribe() do
    Counter.inc(name: :gossip_channel_subscribe_count)
  end

  @doc """
  A channels/unsubscribe event
  """
  def unsubscribe() do
    Counter.inc(name: :gossip_channel_unsubscribe_count)
  end
end
