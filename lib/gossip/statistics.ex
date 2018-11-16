defmodule Gossip.Statistics do
  @moduledoc """
  Track statistics about a game
  """

  import Ecto.Query

  alias Gossip.Repo
  alias Gossip.Statistics.PlayerStatistic

  @doc """
  Record a game's player count at a specific time
  """
  def record_players(game, player_count, time) do
    %PlayerStatistic{}
    |> PlayerStatistic.changeset(game, player_count, time)
    |> Repo.insert()
  end

  def all_player_counts(game) do
    PlayerStatistic
    |> where([ps], ps.game_id == ^game.id)
    |> order_by([ps], desc: ps.recorded_at)
    |> Repo.all()
  end

  @doc """
  Get the last week's worth of statistics
  """
  def last_week(game) do
    last_week =
      Timex.now()
      |> Timex.shift(weeks: -1)
      |> Timex.set(hour: 0, minute: 0, second: 0)
      |> DateTime.truncate(:second)

    stats =
      PlayerStatistic
      |> where([ps], ps.game_id == ^game.id)
      |> where([ps], ps.recorded_at >= ^last_week)
      |> Repo.all()

    interval = Timex.Interval.new([
      from: last_week,
      until: Timex.now(),
      step: [minutes: 15]
    ])

    Enum.map(interval, fn time ->
      {time, find_nearest_stats(stats, time)}
    end)
  end

  defp find_nearest_stats(stats, time) do
    value = Enum.find(stats, fn stat ->
      interval = Timex.Interval.new([from: time, until: [minutes: 15]])
      stat.recorded_at in interval
    end)

    case value do
      nil ->
        0

      value ->
        value.player_count
    end
  end
end
