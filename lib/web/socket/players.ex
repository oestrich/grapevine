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

  @doc """
  Request player status, of connected games
  """
  def request_status(state, %{"ref" => ref, "payload" => %{"game" => game_name}}) when ref != nil do
    case supports_players?(state) do
      true ->
        Presence.online_games()
        |> Enum.find(&find_game(&1, game_name))
        |> maybe_broadcast_state(ref)

        {:ok, state}

      false ->
        {:error, :missing_support}
    end
  end

  def request_status(state, %{"ref" => ref}) when ref != nil do
    case supports_players?(state) do
      true ->
        Enum.each(Presence.online_games, &broadcast_state(&1, ref))

        {:ok, state}

      false ->
        {:error, :missing_support}
    end
  end

  def request_status(_state, _), do: :error

  defp find_game({game, _support, _players, _timestamp}, name) do
    game.short_name == name
  end

  defp maybe_broadcast_state(nil, _ref), do: :ok

  defp maybe_broadcast_state(game, ref), do: broadcast_state(game, ref)

  defp broadcast_state({game, supports, players, _timestamp}, ref) do
    event = %{
      "event" => "players/status",
      "ref" => ref,
      "payload" => %{
        "game" => game.short_name,
        "supports" => supports,
        "players" => players
      }
    }

    send(self(), {:broadcast, event})
  end
end
