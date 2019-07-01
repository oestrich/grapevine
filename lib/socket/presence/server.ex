defmodule Socket.Presence.Server do
  @moduledoc """
  Implementation of the Presence server
  """

  import Socket.Presence, only: [ets_key: 0]

  alias GrapevineData.Statistics
  alias Socket.PlayerPresence
  alias Socket.Presence.Client
  alias Socket.Presence.Notices
  alias Socket.Presence.State
  alias Socket.PubSub

  def track(state, socket, game) do
    state = Map.put(state, :sockets, [{game.id, socket} | state.sockets])
    Notices.maybe_broadcast_connect_event(state, socket)
    {:ok, state}
  end

  def remove_socket(state, socket) do
    Notices.maybe_start_broadcast_disconnect_event(state, socket)

    sockets =
      state.sockets
      |> Enum.reject(fn {_game_id, pid} ->
        pid == socket
      end)

    {:ok, %{state | sockets: sockets}}
  end

  def update_game(state, game, supports, channels, players) do
    presence = %State{
      supports: supports,
      channels: channels,
      players: players,
      timestamp: Timex.now()
    }

    :ets.insert(ets_key(), {ets_key(game), presence})
    broadcast_update(game, presence)
    PlayerPresence.update_count(game.id, length(players || []))
    {:ok, state}
  end

  defp broadcast_update(game, presence) do
    presence =
      presence
      |> Map.take([:supports, :channels, :players, :timestamp])
      |> Map.put(:game_id, game.id)

    PubSub.broadcast("game:presence", "games/update", presence)
  end

  def record_statistics(state) do
    Client.online_games()
    |> Enum.each(fn presence ->
      Statistics.record_socket_players(presence.game, presence.players, Timex.now())
    end)

    {:ok, state}
  end

  defp ets_key(game) do
    "game:#{game.id}"
  end
end
