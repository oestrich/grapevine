defmodule Web.ChatChannel do
  @moduledoc """
  Follow along with the grapevine from the site
  """

  use Phoenix.Channel

  alias Grapevine.Channels

  def join("channels:" <> channel, _message, socket) do
    assign_channel(socket, channel)
  end

  defp assign_channel(socket, channel) do
    case Channels.get(channel) do
      {:ok, channel} ->
        socket = assign(socket, :channel, channel)
        {:ok, socket}

      {:error, :not_found} ->
        {:error, %{reason: "no such channel"}}
    end
  end
end
