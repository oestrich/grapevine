defmodule Grapevine.PlayerPresence do
  @moduledoc """
  GenServer to track current player counts on Grapevine
  """

  use GenServer

  alias __MODULE__.Implementation

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, opts)
  end

  @doc """
  Sum the current total of players online
  """
  def current_total_count() do
    Implementation.current_total_count()
  end

  def update_count(game_id, count) do
    GenServer.cast(__MODULE__, {:update_count, game_id, count})
  end

  def init(opts) do
    opts = Enum.into(opts, %{})
    :ets.new(Implementation.table_name(opts), [:set, :protected, :named_table])

    :ok = :pg2.create(__MODULE__)
    :ok = :pg2.join(__MODULE__, self())

    {:ok, opts, {:continue, :load_table}}
  end

  def handle_continue(:load_table, state) do
    Implementation.load_table(state)
    {:noreply, state}
  end

  def handle_cast({:update_count, game_id, count}, state) do
    state = Implementation.update_count(state, game_id, count)
    {:noreply, state}
  end

  defmodule Implementation do
    @moduledoc false

    alias GrapevineData.Games
    alias Grapevine.PlayerPresence
    alias GrapevineData.Statistics
    alias Web.Endpoint

    def current_total_count() do
      keys()
      |> Enum.map(&lookup_key/1)
      |> Enum.filter(&fresh_keys/1)
      |> Enum.map(&count/1)
      |> Enum.sum()
    end

    defp lookup_key(key) do
      case :ets.lookup(PlayerPresence, key) do
        [{^key, count, recorded_at}] ->
          {count, recorded_at}

        _ ->
          0
      end
    end

    defp fresh_keys({_count, recorded_at}) do
      one_hour_ago = Timex.shift(Timex.now(), hours: -1)
      Timex.after?(recorded_at, one_hour_ago)
    end

    defp count({count, _recorded_at}), do: count

    def load_table(state) do
      Enum.each(Games.all_public(), fn game ->
        case Statistics.most_recent_count(game) do
          nil ->
            :ok

          {most_recent_count, recorded_at} ->
            :ets.insert(table_name(state), {game.id, most_recent_count, recorded_at})
        end
      end)
    end

    def update_count(state, game_id, count) do
      :ets.insert(table_name(state), {game_id, count, Timex.now()})
      Endpoint.broadcast("player:presence", "count/update", %{count: current_total_count()})
      state
    end

    def table_name(state) do
      Map.get(state, :table_name, PlayerPresence)
    end

    def keys(state \\ %{}) do
      key = :ets.first(table_name(state))
      keys(state, key, [key])
    end

    def keys(_state, :"$end_of_table", [:"$end_of_table" | accumulator]), do: accumulator

    def keys(state, current_key, accumulator) do
      next_key = :ets.next(table_name(state), current_key)
      keys(state, next_key, [next_key | accumulator])
    end
  end
end
