defmodule Grapevine.Presence.Server do
  @moduledoc """
  Implementation of the Presence server
  """

  import Grapevine.Presence, only: [ets_key: 0]

  alias Grapevine.Applications.Application
  alias Grapevine.Games.Game
  alias Grapevine.Presence.Client
  alias Grapevine.Presence.Notices
  alias Grapevine.Presence.State
  alias Grapevine.Statistics

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
    :ets.insert(
      ets_key(),
      {ets_key(game),
       %State{supports: supports, channels: channels, players: players, timestamp: Timex.now()}}
    )

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
