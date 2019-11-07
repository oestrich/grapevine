defmodule Socket.Presence.Client do
  @moduledoc """
  Implementation of the Presence client
  """

  alias GrapevineData.Games
  alias Socket.Presence.GrapevineApplication

  import Socket.Presence, only: [ets_key: 0]

  @timeout_seconds 60

  @doc """
  Number of seconds that a game can be offline before the game is considered offline
  """
  def timeout_seconds(), do: @timeout_seconds

  @doc """
  Get a list of games that are connected and online
  """
  def online_games() do
    keys()
    |> Enum.map(&fetch_from_ets/1)
    |> Enum.filter(&filter_online/1)
    |> Enum.map(&fetch_from_db/1)
    |> Enum.reject(&is_nil/1)
    |> append_grapevine()
  end

  defp append_grapevine(games) do
    grapevine_presence = %Socket.Presence.State{
      game: %GrapevineApplication{},
      players: ["system"],
      channels: [],
      supports: ["channels", "players", "tells"],
      timestamp: Timex.now()
    }

    [grapevine_presence | games]
  end

  @doc """
  Fetch a game by id from ETS
  """
  def fetch_from_ets(id) do
    case :ets.lookup(ets_key(), id) do
      [{^id, presence}] ->
        {id, presence}

      _ ->
        nil
    end
  end

  @doc """
  Determine if a game is online based on presence from ETS
  """
  def game_online?(presence) do
    oldest_online = Timex.now() |> Timex.shift(seconds: -1 * @timeout_seconds)
    Timex.after?(presence.timestamp, oldest_online)
  end

  defp filter_online(nil), do: false

  defp filter_online({_game_id, presence}) do
    game_online?(presence)
  end

  defp fetch_from_db({"game:" <> game_id, presence}) do
    case Games.get(game_id) do
      {:ok, game} ->
        Map.put(presence, :game, game)

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
