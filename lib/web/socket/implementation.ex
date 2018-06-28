defmodule Web.Socket.Implementation do
  alias Gossip.Games

  def receive(state = %{status: "inactive"}, %{"event" => "authenticate", "payload" => payload}) do
    case Games.validate_socket(Map.get(payload, "client-id"), Map.get(payload, "client-secret")) do
      {:ok, game} ->
        state =
          state
          |> Map.put(:status, "active")
          |> Map.put(:game, game)

        Web.Endpoint.subscribe("channels:gossip")

        {:ok, %{event: "authenticate", status: "success"}, state}

      {:error, :invalid} ->
        {:ok, %{event: "authenticate", status: "failure", error: "invalid credentials"}, state}
    end
  end

  def receive(state = %{status: "active"}, %{"event" => "messages/new", "payload" => payload}) do
    case Map.fetch(payload, "channel") do
      {:ok, channel} ->
        payload = Map.put(payload, "game", state.game.name)
        Web.Endpoint.broadcast("channels:#{channel}", "messages/broadcast", payload)
        {:ok, state}
    end
  end

  def receive(state, _frame) do
    {:ok, %{status: "unknown"}, state}
  end
end
