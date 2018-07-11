defmodule Web.Socket.Players do
  @moduledoc """
  Player status subscription feature module
  """

  alias Gossip.Presence

  @doc """
  Maybe subcsribe to the players status channel, only if the socket supports it
  """
  def maybe_listen_to_players_channel(state) do
    case supports_players?(state) do
      true ->
        Web.Endpoint.subscribe("players:status")

      false ->
        :ok
    end
  end

  @doc """
  Check if the socket supports players
  """
  def supports_players?(state), do: "players" in state.supports

  @doc """
  Receive a new player sign in, broadcast it
  """
  def player_sign_in(state, %{"payload" => %{"name" => name}}) do
    case supports_players?(state) do
      true ->
        payload = %{
          "game" => state.game.short_name,
          "game_id" => state.game.client_id,
          "name" => name
        }

        Web.Endpoint.broadcast("players:status", "players/sign-in", payload)

        players = Enum.uniq([name | state.players])
        state = %{state | players: players}
        Presence.update_game(state)

        {:ok, state}

      false ->
        {:error, :missing_support}
    end
  end

  def player_sign_in(_state, _event), do: :error

  @doc """
  Receive a new player sign out, broadcast it
  """
  def player_sign_out(state, %{"payload" => %{"name" => name}}) do
    case supports_players?(state) do
      true ->
        payload = %{
          "game" => state.game.short_name,
          "game_id" => state.game.client_id,
          "name" => name
        }

        Web.Endpoint.broadcast("players:status", "players/sign-out", payload)

        players = List.delete(state.players, name)
        state = %{state | players: players}
        Presence.update_game(state)

        {:ok, state}

      false ->
        {:error, :missing_support}
    end
  end

  def player_sign_out(_state, _event), do: :error
end
