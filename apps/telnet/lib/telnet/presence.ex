defmodule GrapevineTelnet.Presence do
  @moduledoc """
  Small gen server to tick and record gauge metrics
  """

  use GenServer

  alias __MODULE__.Implementation
  alias __MODULE__.OpenClient
  alias GrapevineTelnet.PubSub
  alias GrapevineTelnet.Statistics

  @ets_key GrapevineTelnet.Presence

  defmodule OpenClient do
    @moduledoc """
    Struct for tracking open clients
    """

    defstruct [:pid, :sid, :opened_at, :last_sent_at, :game, :player_name]
  end

  @doc false
  def ets_key(), do: @ets_key

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: {:global, __MODULE__})
  end

  @doc """
  Get the count of online clients
  """
  @spec online_client_count() :: integer()
  def online_client_count() do
    GenServer.call({:global, __MODULE__}, {:clients, :online, :count})
  end

  @doc """
  Fetch clients that are online
  """
  def online_clients() do
    GenServer.call({:global, __MODULE__}, {:clients, :online})
  end

  @doc """
  Fetch clients for a specific game
  """
  def online_clients_for(game) do
    GenServer.call({:global, __MODULE__}, {:clients, :online, :game, game.id})
  end

  @doc """
  Let the server know a web client came online
  """
  def client_online(sid, opts) do
    GenServer.cast({:global, __MODULE__}, {:client, :online, self(), sid, opts, Timex.now()})
  end

  @doc """
  Let the server know a web client came online
  """
  def socket_sent() do
    GenServer.cast({:global, __MODULE__}, {:client, :socket_sent, self(), Timex.now()})
  end

  @doc """
  Update the client presence with the player name sent from the server
  """
  def set_player_name(player_name) do
    GenServer.cast({:global, __MODULE__}, {:client, :set_player_name, self(), player_name})
  end

  def init(_) do
    Process.flag(:trap_exit, true)
    create_table()
    {:ok, %{clients: []}}
  end

  def handle_call({:clients, :online, :count}, _from, state) do
    {:reply, length(state.clients), state}
  end

  def handle_call({:clients, :online, :game, game_id}, _from, state) do
    {:reply, Implementation.online_clients_for(game_id), state}
  end

  def handle_call({:clients, :online}, _from, state) do
    {:reply, Implementation.online_clients(), state}
  end

  def handle_cast({:client, :online, pid, sid, opts, opened_at}, state) do
    Process.link(pid)

    game = Keyword.get(opts, :game)

    open_client = %OpenClient{
      pid: pid,
      sid: sid,
      game: game,
      opened_at: opened_at
    }

    Statistics.session_started(game, sid)

    :ets.insert(@ets_key, {pid, game.id, open_client})

    broadcast("client/online", open_client)

    {:noreply, Map.put(state, :clients, [pid | state.clients])}
  end

  def handle_cast({:client, :socket_sent, pid, last_sent_at}, state) do
    case Implementation.fetch_from_ets(pid) do
      nil ->
        {:noreply, state}

      open_client ->
        open_client = %{open_client | last_sent_at: last_sent_at}
        :ets.insert(@ets_key, {pid, open_client.game.id, open_client})
        broadcast("client/update", open_client)
        {:noreply, state}
    end
  end

  def handle_cast({:client, :set_player_name, pid, player_name}, state) do
    case Implementation.fetch_from_ets(pid) do
      nil ->
        {:noreply, state}

      open_client ->
        open_client = %{open_client | player_name: player_name}
        :ets.insert(@ets_key, {pid, open_client.game.id, open_client})
        broadcast("client/update", open_client)
        {:noreply, state}
    end
  end

  def handle_info({:EXIT, pid, _reason}, state) do
    open_client = Implementation.fetch_from_ets(pid)
    Statistics.session_closed(open_client.sid)
    broadcast("client/offline", open_client)

    state = Map.put(state, :clients, List.delete(state.clients, pid))
    :ets.delete(@ets_key, pid)

    {:noreply, state}
  end

  defp broadcast(event, client) do
    PubSub.broadcast("telnet:presence", event, client)
  end

  defp create_table() do
    :ets.new(@ets_key, [:set, :protected, :named_table])
  end

  defmodule Implementation do
    @moduledoc false

    alias GrapevineTelnet.Presence

    @doc """
    Fetch all online web clients
    """
    def online_clients() do
      keys()
      |> Enum.map(&fetch_from_ets/1)
      |> Enum.reject(&(&1 == :error))
    end

    @doc """
    Fetch online web clients for a specific game
    """
    def online_clients_for(game_id) do
      matched_games = :ets.match_object(Presence.ets_key(), {:_, game_id, :_})

      Enum.map(matched_games, fn {_pid, _game, open_client} ->
        open_client
      end)
    end

    def fetch_from_ets(pid) do
      case :ets.lookup(Presence.ets_key(), pid) do
        [{^pid, _game_id, open_client}] ->
          open_client

        _ ->
          :error
      end
    end

    def keys() do
      key = :ets.first(Presence.ets_key())
      keys(key, [key])
    end

    def keys(:"$end_of_table", [:"$end_of_table" | accumulator]), do: accumulator

    def keys(current_key, accumulator) do
      next_key = :ets.next(Presence.ets_key(), current_key)
      keys(next_key, [next_key | accumulator])
    end
  end
end
