defmodule Web.ChatChannel do
  @moduledoc """
  Chat with users on a gossip channel
  """

  use Web, :channel

  alias GrapevineData.Channels
  alias Grapevine.Client
  alias Grapevine.Client.Broadcast

  def join("chat:" <> channel, _message, socket) do
    case Map.has_key?(socket.assigns, :user) do
      true ->
        socket
        |> assign_channel(channel)

      false ->
        {:error, %{reason: "user required"}}
    end
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

  def handle_in("send", %{"message" => message}, socket) do
    %{channel: channel, user: user} = socket.assigns

    message = %Broadcast{
      channel: channel,
      user: user,
      message: message
    }

    Client.broadcast(message)

    {:noreply, socket}
  end
end
