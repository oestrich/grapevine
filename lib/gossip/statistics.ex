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
  def record_players(game, players, time) do
    Telemetry.execute([:gossip, :statistics, :players, :record], length(players), %{time: time})

    %PlayerStatistic{}
    |> PlayerStatistic.changeset(game, players, time)
    |> Repo.insert()
  end

  @doc """
  Get all player counts for a game
  """
  def all_player_counts(game) do
    PlayerStatistic
    |> where([ps], ps.game_id == ^game.id)
    |> order_by([ps], desc: ps.recorded_at)
    |> Repo.all()
  end

  @doc """
  Get the last few days's worth of statistics
  """
  def last_few_days(game) do
    last_few_days =
      Timex.now()
      |> Timex.shift(days: -2)
      |> Timex.set(minute: 0, second: 0)
      |> DateTime.truncate(:second)

    stats =
      PlayerStatistic
      |> where([ps], ps.game_id == ^game.id)
      |> where([ps], ps.recorded_at >= ^last_few_days)
      |> Repo.all()

    interval = Timex.Interval.new([from: last_few_days, until: Timex.now(), step: [hours: 1] ])

    Enum.map(interval, fn time ->
      {time, find_nearest_stats(stats, time)}
    end)
  end

  defp find_nearest_stats(stats, time) do
    values = Enum.filter(stats, fn stat ->
      interval = Timex.Interval.new([from: time, until: [hours: 1]])
      stat.recorded_at in interval
    end)

    case Enum.empty?(values) do
      true ->
        nil

      false ->
        sum =
          values
          |> Enum.map(&(&1.player_count))
          |> Enum.sum()

        div(sum, Enum.count(values))
    end
  end
end
