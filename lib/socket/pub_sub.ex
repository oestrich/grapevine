defmodule Socket.PubSub do
  @moduledoc """
  Phoenix pubsub setup
  """

  @doc """
  Publish to the local phoenix channels layer
  """
  def broadcast(topic, event, payload) do
    Phoenix.PubSub.broadcast(Grapevine.PubSub, topic, %{
      __struct__: Phoenix.Socket.Broadcast,
      topic: topic,
      event: event,
      payload: payload
    })
  end

  def subscribe(topic) do
    Phoenix.PubSub.subscribe(Grapevine.PubSub, topic)
  end

  def unsubscribe(topic) do
    Phoenix.PubSub.unsubscribe(Grapevine.PubSub, topic)
  end
end
