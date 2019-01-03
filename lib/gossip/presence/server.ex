defmodule Gossip.Presence.Server do
  @moduledoc """
  Implementation of the Presence server
  """

  import Gossip.Presence, only: [ets_key: 0]

  alias Gossip.Applications.Application
  alias Gossip.Games.Game
  alias Gossip.Presence.Client
  alias Gossip.Presence.Notices
  alias Gossip.Statistics

  def track(state, socket, game) do
    state = Map.put(state, :sockets, [{type(game), game.id, socket} | state.sockets])
    Notices.maybe_broadcast_connect_event(state, socket)
    {:ok, state}
  end

  defp type(%Game{}), do: :game

  defp type(%Application{}), do: :game

  def remove_socket(state, socket) do
    Notices.maybe_start_broadcast_disconnect_event(state, socket)

    sockets =
      state.sockets
      |> Enum.reject(fn {_type, _game_id, pid} ->
        pid == socket
      end)

    {:ok, %{state | sockets: sockets}}
  end

  def update_game(state, game, supports, channels, players) do
    :ets.insert(ets_key(), {ets_key(game), %{supports: supports, channels: channels, players: players, timestamp: Timex.now()}})
    {:ok, state}
  end

  def record_statistics(state) do
    Client.online_games()
    |> Enum.filter(&(&1.type == :game))
    |> Enum.each(fn presence ->
      Statistics.record_socket_players(presence.game, presence.players, Timex.now())
    end)

    {:ok, state}
  end

  defp ets_key(game = %Game{}) do
    "game:#{game.id}"
  end

  defp ets_key(application = %Application{}) do
    "application:#{application.id}"
  end
end
