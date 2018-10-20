defmodule Web.Socket.Players do
  @moduledoc """
  Player status subscription feature module
  """

  alias Gossip.Presence
  alias Web.Socket.Core

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
    case name in state.players do
      true ->
        {:ok, state}

      false ->
        sign_player_in(state, name)
    end
  end

  def player_sign_in(_state, _event), do: :error

  defp sign_player_in(state, name) do
    maybe_broadcast_signin(state, name)

    players = Enum.uniq([name | state.players])
    state = %{state | players: players}
    Presence.update_game(state)

    {:ok, state}
  end

  defp maybe_broadcast_signin(state, name) do
    payload = %{
      "game" => state.game.short_name,
      "game_id" => state.game.client_id,
      "name" => name
    }

    case state.game.display do
      true ->
        Web.Endpoint.broadcast("players:status", "players/sign-in", payload)

      false ->
        :ok
    end
  end

  @doc """
  Receive a new player sign out, broadcast it
  """
  def player_sign_out(state, %{"payload" => %{"name" => name}}) do
    case name in state.players do
      true ->
        sign_player_out(state, name)

      false ->
        {:ok, :skip, state}
    end
  end

  def player_sign_out(_state, _event), do: :error

  defp sign_player_out(state, name) do
    maybe_broadcast_signout(state, name)

    players = List.delete(state.players, name)
    state = %{state | players: players}
    Presence.update_game(state)

    {:ok, state}
  end

  defp maybe_broadcast_signout(state, name) do
    payload = %{
      "game" => state.game.short_name,
      "game_id" => state.game.client_id,
      "name" => name
    }

    case state.game.display do
      true ->
        Web.Endpoint.broadcast("players:status", "players/sign-out", payload)

      false ->
        :ok
    end
  end

  @doc """
  Request player status, of connected games
  """
  def request_status(state, %{"ref" => ref, "payload" => %{"game" => game_name}}) when ref != nil do
    Presence.online_games()
    |> Enum.find(&find_game(&1, game_name))
    |> maybe_broadcast_state(ref)

    {:ok, :skip, state}
  end

  def request_status(state, %{"ref" => ref}) when ref != nil do
    Presence.online_games()
    |> Enum.filter(&(&1.game.display))
    |> Core.remove_self_from_game_list(state)
    |> Enum.each(&broadcast_state(&1, ref))

    {:ok, :skip, state}
  end

  def request_status(_state, _), do: :error

  defp find_game(state, name) do
    state.game.short_name == name
  end

  defp maybe_broadcast_state(nil, _ref), do: :ok

  defp maybe_broadcast_state(game, ref), do: broadcast_state(game, ref)

  defp broadcast_state(state, ref) do
    event = %{
      "event" => "players/status",
      "ref" => ref,
      "payload" => %{
        "game" => state.game.short_name,
        "players" => state.players
      }
    }

    send(self(), {:broadcast, event})
  end
end
