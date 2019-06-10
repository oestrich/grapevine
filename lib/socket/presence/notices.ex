defmodule Socket.Presence.Notices do
  @moduledoc """
  Send a notice if a game comes online or goes offline
  """

  alias Socket.Handler.Games
  alias Socket.Presence
  alias Socket.Presence.Client

  @doc """
  Maybe send a notice to games that care that another game went online

  Does not send a notice if:
  - there are multiple sockets connected for a game
  - the game is still "online", a socket is offline but too recently
  """
  def maybe_broadcast_connect_event(state, socket) do
    with {:ok, game_id} <- get_game_id(state, socket),
         {:ok, :only} <- check_only_socket(state, socket, game_id),
         {:ok, :offline} <- check_game_offline(game_id) do
      Games.broadcast_connect_event(game_id)
    end
  end

  @doc """
  Maybe send a notice to games that care that another game went offline

  Sends a delayed message to the presence server to check back later and
  determines if the game is still indeed offline after the `Presence` server
  thinks the game is offline.

  Does not send a notice if there are multiple sockets connected for a game
  """
  def maybe_start_broadcast_disconnect_event(state, socket) do
    with {:ok, game_id} <- get_game_id(state, socket),
         {:ok, :only} <- check_only_socket(state, socket, game_id) do
      Presence.delay_disconnect(game_id)
    end
  end

  @doc """
  Maybe send a notice to games that care that another game went offline

  Sends a notice only if the game is still offline.
  """
  def maybe_broadcast_disconnect_event(game_id) do
    with {:ok, :offline} <- check_game_offline(game_id) do
      Games.broadcast_disconnect_event(game_id)
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
      |> Enum.reject(fn {_game_id, socket_pid} ->
        socket_pid == socket
      end)
      |> Enum.filter(fn {socket_game_id, _socket_pid} ->
        socket_game_id == game_id
      end)

    case Enum.empty?(sockets) do
      true ->
        {:ok, :only}

      false ->
        {:error, :still_online}
    end
  end

  defp check_game_offline(game_id) do
    case Client.fetch_from_ets("game:#{game_id}") do
      nil ->
        {:ok, :offline}

      {_, state} ->
        case Client.game_online?(state) do
          false ->
            {:ok, :offline}

          true ->
            :error
        end
    end
  end
end
