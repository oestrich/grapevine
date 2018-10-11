defmodule Gossip.Presence.Notices do
  @moduledoc """
  Send a notice if a game comes online or goes offline
  """

  alias Gossip.Games

  @doc """
  Maybe send a notice to games that care that another game went online

  Does not send a notice if there are multiple sockets connected for a game.
  """
  def maybe_broadcast_connect_event(state, socket) do
    with {:ok, game_id} <- get_game_id(state, socket),
         {:ok, :only} <- check_only_socket(state, socket, game_id) do
      broadcast_connect_event(game_id)
    end
  end

  @doc """
  Maybe send a notice to games that care that another game went offline

  Does not send a notice if there are multiple sockets connected for a game.
  """
  def maybe_broadcast_disconnect_event(state, socket) do
    with {:ok, game_id} <- get_game_id(state, socket),
         {:ok, :only} <- check_only_socket(state, socket, game_id) do
      broadcast_disconnect_event(game_id)
    end
  end

  defp get_game_id(state, socket) do
    socket = Enum.find(state.sockets, fn {_game_id, pid} -> pid == socket end)

    case socket do
      nil ->
        {:error, :not_found}

      {game_id, _} ->
        {:ok, game_id}
    end
  end

  defp check_only_socket(state, socket, game_id) do
    sockets =
      state.sockets
      |> Enum.reject(&elem(&1, 1) == socket)
      |> Enum.filter(&elem(&1, 0) == game_id)

    case Enum.empty?(sockets) do
      true ->
        {:ok, :only}

      false ->
        {:error, :still_online}
    end
  end

  defp broadcast_connect_event(game_id) do
    with {:ok, game} <- Games.get(game_id) do
      payload = %{
        "game" => game.short_name,
        "game_id" => game.client_id
      }
      Web.Endpoint.broadcast("games:status", "games/connect", payload)
    end
  end

  defp broadcast_disconnect_event(game_id) do
    with {:ok, game} <- Games.get(game_id) do
      payload = %{"game" => game.short_name}
      Web.Endpoint.broadcast("games:status", "games/disconnect", payload)
    end
  end
end
