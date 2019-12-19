defmodule Grapevine.PubSub do
  @moduledoc """
  Local pubsub layer Phoenix channels
  """

  @doc """
  Broadcast an event/payload to a topic
  """
  def broadcast(topic, event, payload) do
    Web.Endpoint.broadcast(topic, event, payload)
  end
end
