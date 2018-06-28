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

  def receive(state, frame) do
    IO.inspect frame
    {:ok, %{status: "unknown"}, state}
  end
end
