defmodule Grapevine.Presence.Notices do
  @moduledoc """
  Send a notice if a game comes online or goes offline
  """

  alias Grapevine.Presence
  alias Grapevine.Presence.Client
  alias Socket.Handler.Games

  @doc """
  Maybe send a notice to games that care that another game went online

  Does not send a notice if:
  - there are multiple sockets connected for a game
  - the game is still "online", a socket is offline but too recently
  """
  def maybe_broadcast_connect_event(state, socket) do
    with {:ok, type, game_id} <- get_game_id(state, socket),
         {:ok, :only} <- check_only_socket(state, socket, type, game_id),
         {:ok, :offline} <- check_game_offline(type, game_id) do
      Games.broadcast_connect_event(type, game_id)
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
    with {:ok, type, game_id} <- get_game_id(state, socket),
         {:ok, :only} <- check_only_socket(state, socket, type, game_id) do
      Presence.delay_disconnect(type, game_id)
    end
  end

  @doc """
  Maybe send a notice to games that care that another game went offline

  Sends a notice only if the game is still offline.
  """
  def maybe_broadcast_disconnect_event(type, game_id) do
    with {:ok, :offline} <- check_game_offline(type, game_id) do
      Games.broadcast_disconnect_event(type, game_id)
    end
  end

  defp get_game_id(state, socket) do
    socket = Enum.find(state.sockets, fn {_type, _game_id, pid} -> pid == socket end)

    case socket do
      nil ->
        {:error, :not_found}

      {type, game_id, _} ->
        {:ok, type, game_id}
    end
  end

  defp check_only_socket(state, socket, type, game_id) do
    sockets =
      state.sockets
      |> Enum.reject(&(elem(&1, 2) == socket))
      |> Enum.filter(&(elem(&1, 0) == type && elem(&1, 1) == game_id))

    case Enum.empty?(sockets) do
      true ->
        {:ok, :only}

      false ->
        {:error, :still_online}
    end
  end

  defp check_game_offline(type, game_id) do
    case Client.fetch_from_ets("#{type}:#{game_id}") do
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
