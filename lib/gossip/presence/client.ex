defmodule Gossip.Presence.Client do
  @moduledoc """
  Implementation of the Presence client
  """

  alias Gossip.Games

  import Gossip.Presence, only: [ets_key: 0]

  @timeout_seconds 60

  @doc """
  Get a list of games that are connected and online
  """
  def online_games() do
    keys()
    |> Enum.map(&fetch_game_from_ets/1)
    |> Enum.filter(&filter_online/1)
    |> Enum.map(&fetch_game_from_db/1)
    |> Enum.reject(&is_nil/1)
  end

  defp fetch_game_from_ets(game_id) do
    case :ets.lookup(ets_key(), game_id) do
      [{^game_id, players, timestamp}] ->
        {game_id, players, timestamp}

      _ ->
        nil
    end
  end

  defp filter_online(nil), do: false

  defp filter_online({_game_id, _players, timestamp}) do
    oldest_online = Timex.now() |> Timex.shift(seconds: -1 * @timeout_seconds)
    Timex.after?(timestamp, oldest_online)
  end

  defp fetch_game_from_db({game_id, players, timestamp}) do
    with {:ok, game} <- Games.get(game_id) do
      {game, players, timestamp}
    end
  end

  defp keys() do
    key = :ets.first(ets_key())
    keys(key, [key])
  end

  defp keys(:"$end_of_table", [:"$end_of_table" | accumulator]), do: accumulator

  defp keys(current_key, accumulator) do
    next_key = :ets.next(ets_key(), current_key)
    keys(next_key, [next_key | accumulator])
  end
end
