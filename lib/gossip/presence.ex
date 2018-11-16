defmodule Gossip.Presence do
  @moduledoc """
  Track online presence of games
  """

  use GenServer

  alias Gossip.Applications.Application
  alias Gossip.Games.Game
  alias Gossip.Presence.Client
  alias Gossip.Presence.Notices
  alias Gossip.Presence.Server

  @ets_key :gossip_presence

  @record_statistics_tick 15 * 60 * 1000

  @type supports :: [String.t()]
  @type players :: [String.t()]

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Update a game and their players presence
  """
  @spec update_game(Game.t(), supports(), players()) :: :ok
  def update_game(game, supports, players) do
    GenServer.call(__MODULE__, {:update, game, supports, players})
  end

  @spec update_game(Socket.state()) :: :ok
  def update_game(state) do
    GenServer.call(__MODULE__, {:update, state.game, state.supports, state.players})
  end

  @spec track(Socket.state()) :: :ok
  def track(state) do
    case state.game do
      %Application{} ->
        :ok

      %Game{} ->
        message = {:track, self(), state.game, state.supports, state.players}
        GenServer.call(__MODULE__, message)
    end
  end

  @doc false
  def delay_disconnect(type, game_id) do
    Process.send_after(__MODULE__, {:disconnected, type, game_id}, :timer.seconds(Client.timeout_seconds()))
  end

  # for tests
  @doc false
  def reset() do
    GenServer.call(__MODULE__, {:reset})
  end

  @doc """
  Get a list of online games
  """
  @spec online_games() :: [{Game.t(), players()}]
  def online_games(), do: Client.online_games()

  @doc false
  def ets_key(), do: @ets_key

  def init(_) do
    create_table()
    Process.flag(:trap_exit, true)
    {:ok, initial_state()}
  end

  def handle_call({:track, socket, game, supports, players}, _from, state) do
    Process.link(socket)
    {:ok, state} = Server.track(state, socket, game)
    {:ok, state} = Server.update_game(state, game, supports, players)
    schedule_statistics_recording()
    {:reply, :ok, state}
  end

  def handle_call({:update, game, supports, players}, _from, state) do
    {:ok, state} = Server.update_game(state, game, supports, players)
    {:reply, :ok, state}
  end

  def handle_call({:reset}, _from, _state) do
    :ets.delete(ets_key())
    create_table()
    {:reply, :ok, initial_state()}
  end

  def handle_info({:disconnected, type, game_id}, state) do
    Notices.maybe_broadcast_disconnect_event(type, game_id)
    {:noreply, state}
  end

  def handle_info({:EXIT, pid, _reason}, state) do
    {:ok, state} = Server.remove_socket(state, pid)
    {:noreply, state}
  end

  def handle_info({:record_statistics}, state) do
    {:ok, state} = Server.record_statistics(state)
    schedule_statistics_recording()
    {:noreply, state}
  end

  defp initial_state(), do: %{sockets: []}

  defp create_table() do
    :ets.new(@ets_key, [:set, :protected, :named_table])
  end

  defp schedule_statistics_recording() do
    Process.send_after(self(), {:record_statistics}, @record_statistics_tick)
  end
end
