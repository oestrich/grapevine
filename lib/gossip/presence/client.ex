defmodule Gossip.Presence.Client do
  @moduledoc """
  Implementation of the Presence client
  """

  alias Gossip.Applications
  alias Gossip.Games

  import Gossip.Presence, only: [ets_key: 0]

  @timeout_seconds 60

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
    case :ets.lookup(ets_key(), id) do
      [{^id, state}] ->
        {id, state}

      _ ->
        nil
    end
  end

  @doc """
  Determine if a game is online based on state from ETS
  """
  def game_online?(state) do
    oldest_online = Timex.now() |> Timex.shift(seconds: -1 * @timeout_seconds)
    Timex.after?(state.timestamp, oldest_online)
  end

  defp filter_online(nil), do: false

  defp filter_online({_game_id, state}) do
    game_online?(state)
  end

  defp fetch_from_db({"game:" <> game_id, state}) do
    case Games.get(game_id) do
      {:ok, game} ->
        Map.put(state, :game, game)

      {:error, :not_found} ->
        nil
    end
  end

  defp fetch_from_db({"application:" <> application_id, state}) do
    case Applications.get(application_id) do
      {:ok, application} ->
        Map.put(state, :game, application)

      {:error, :not_found} ->
        nil
    end
  end

  def keys() do
    key = :ets.first(ets_key())
    keys(key, [key])
  end

  def keys(:"$end_of_table", [:"$end_of_table" | accumulator]), do: accumulator

  def keys(current_key, accumulator) do
    next_key = :ets.next(ets_key(), current_key)
    keys(next_key, [next_key | accumulator])
  end
end
