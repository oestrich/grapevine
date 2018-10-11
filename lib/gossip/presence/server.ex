defmodule Gossip.Presence.Server do
  @moduledoc """
  Implementation of the Presence server
  """

  import Gossip.Presence, only: [ets_key: 0]

  alias Gossip.Applications.Application
  alias Gossip.Games.Game
  alias Gossip.Presence.Notices

  def track(state, socket, game) do
    state = Map.put(state, :sockets, [{game.id, socket} | state.sockets])
    Notices.maybe_broadcast_connect_event(state, socket)
    {:ok, state}
  end

  def remove_socket(state, socket) do
    Notices.maybe_broadcast_disconnect_event(state, socket)

    sockets =
      state.sockets
      |> Enum.reject(fn {_game_id, pid} ->
        pid == socket
      end)

    {:ok, %{state | sockets: sockets}}
  end

  def update_game(state, game, supports, players) do
    :ets.insert(ets_key(), {ets_key(game), %{supports: supports, players: players, timestamp: Timex.now()}})
    {:ok, state}
  end

  defp ets_key(game = %Game{}) do
    "game:#{game.id}"
  end

  defp ets_key(application = %Application{}) do
    "application:#{application.id}"
  end
end
