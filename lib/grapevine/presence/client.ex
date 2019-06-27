defmodule Grapevine.Presence.Client do
  @moduledoc """
  Main node version of the socket presence
  """

  alias GrapevineData.Games

  @ets_key :grapevine_presence_cache
  @timeout_seconds 60

  @doc """
  Create the ets table for the node cache
  """
  def create_table() do
    :ets.new(@ets_key, [:set, :protected, :named_table])
  end

  @doc """
  Update the local cache of the game's presence
  """
  def update_presence(presence) do
    :ets.insert(@ets_key, {presence.game_id, presence})
  end

  @doc """
  Get a list of games that are connected and online
  """
  def online_games() do
    keys()
    |> Enum.map(&fetch_from_ets/1)
    |> Enum.filter(&filter_online/1)
    |> Enum.map(&fetch_from_db/1)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Fetch a game by id from ETS
  """
  def fetch_from_ets(id) do
    case :ets.lookup(@ets_key, id) do
      [{^id, presence}] ->
        {id, presence}

      _ ->
        nil
    end
  end

  @doc """
  Filter for presence online status
  """
  def filter_online(nil), do: false

  def filter_online({_game_id, presence}) do
    game_online?(presence)
  end

  @doc """
  Determine if a game is online based on presence from ETS
  """
  def game_online?(presence) do
    oldest_online = Timex.now() |> Timex.shift(seconds: -1 * @timeout_seconds)
    Timex.after?(presence.timestamp, oldest_online)
  end

  @doc """
  Load the game from the database
  """
  def fetch_from_db({game_id, presence}) do
    case Games.get(game_id) do
      {:ok, game} ->
        Map.put(presence, :game, game)

      {:error, :not_found} ->
        nil
    end
  end

  def keys() do
    key = :ets.first(@ets_key)
    keys(key, [key])
  end

  def keys(:"$end_of_table", [:"$end_of_table" | accumulator]), do: accumulator

  def keys(current_key, accumulator) do
    next_key = :ets.next(@ets_key, current_key)
    keys(next_key, [next_key | accumulator])
  end
end
