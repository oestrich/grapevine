defmodule Grapevine.Channels do
  @moduledoc """
  Extra functions for channels
  """

  alias Grapevine.PubSub
  alias GrapevineData.Channels

  def all(opts), do: Channels.all(opts)

  def get(id), do: Channels.get(id)

  @doc """
  Pause a live channel from new broadcasts for `minutes`
  """
  def pause(channel, minutes \\ 30) do
    channel
    |> broadcast("This channel has been paused for the next #{minutes} minutes")
    |> broadcast("Please remember to Be Excellent to everyone")

    PubSub.broadcast("system:channels", "pause", %{channel: channel, minutes: minutes})
  end

  defp broadcast(channel, message) do
    PubSub.broadcast("channels:#{channel}", "channels/broadcast", %{
      "channel" => channel,
      "game" => "Grapevine",
      "name" => "system",
      "message" => "[SYSTEM] #{message}"
    })

    channel
  end
end
