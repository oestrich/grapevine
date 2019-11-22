defmodule Web.ChatChannel do
  @moduledoc """
  Chat with users on a gossip channel
  """

  use Web, :channel

  alias GrapevineData.Channels
  alias GrapevineData.Messages
  alias Grapevine.Client
  alias Grapevine.Client.Broadcast

  @initial_replay_count 25

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
        Web.Endpoint.subscribe("channels:#{channel.name}")

        messages =
          channel
          |> Messages.for(limit: @initial_replay_count)
          |> Enum.map(&Map.take(&1, [:inserted_at, :name, :game, :text]))
          |> Enum.map(&convert_message_to_utc/1)
          |> Enum.reverse()

        {:ok, %{messages: messages}, socket}

      {:error, :not_found} ->
        {:error, %{reason: "no such channel"}}
    end
  end

  defp convert_message_to_utc(message) do
    Map.put(message, :inserted_at, Timex.Timezone.convert(message.inserted_at, "UTC"))
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

  def handle_info(%{event: "channels/broadcast", payload: payload}, socket) do
    payload =
      payload
      |> Map.put("inserted_at", Timex.now())
      |> Map.delete("game_id")

    push(socket, "broadcast", payload)
    {:noreply, socket}
  end
end
