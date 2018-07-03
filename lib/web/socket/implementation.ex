defmodule Web.Socket.Implementation do
  alias Gossip.Games

  def receive(state = %{status: "inactive"}, %{"event" => "authenticate", "payload" => payload}) do
    case Games.validate_socket(Map.get(payload, "client_id"), Map.get(payload, "client_secret"), payload) do
      {:ok, game} ->
        state =
          state
          |> Map.put(:status, "active")
          |> Map.put(:game, game)

        listen_to_channels(game)
        notify_of_subscribed_channels(game)

        {:ok, %{event: "authenticate", status: "success"}, state}

      {:error, :invalid} ->
        {:ok, %{event: "authenticate", status: "failure", error: "invalid credentials"}, state}
    end
  end

  def receive(state = %{status: "active"}, %{"event" => "messages/new", "payload" => payload}) do
    case Map.fetch(payload, "channel") do
      {:ok, channel} ->
        payload =
          payload
          |> Map.put("id", UUID.uuid4())
          |> Map.put("game", state.game.short_name)
          |> Map.put("game_id", state.game.client_id)
          |> Map.take(["id", "channel", "game", "game_id", "name", "message"])

        Web.Endpoint.broadcast("channels:#{channel}", "messages/broadcast", payload)
        {:ok, state}
    end
  end

  def receive(state, _frame) do
    {:ok, %{status: "unknown"}, state}
  end

  defp listen_to_channels(game) do
    game.channels
    |> Enum.each(fn channel ->
      Web.Endpoint.subscribe("channels:#{channel.name}")
    end)
  end

  defp notify_of_subscribed_channels(game) do
    channels = game.channels |> Enum.map(&(&1.name))

    event = %{
      event: "channels/subscribed",
      payload: %{
        channels: channels,
      },
    }

    send(self(), {:broadcast, event})
  end
end
