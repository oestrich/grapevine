defmodule Grapevine.Statistics do
  @moduledoc """
  Track statistics about a game
  """

  import Ecto.Query

  alias Grapevine.PlayerPresence
  alias Data.Repo
  alias Grapevine.Statistics.PlayerStatistic
  alias Grapevine.Statistics.Session

  @doc """
  Record a game's player count at a specific time on the socket
  """
  def record_socket_players(game, players, time) do
    :telemetry.execute([:grapevine, :statistics, :players, :record], %{count: length(players)}, %{time: time})

    %PlayerStatistic{}
    |> PlayerStatistic.socket_changeset(game, players, time)
    |> Repo.insert()
    |> broadcast_count()
  end

  @doc """
  Record a game's player count at a specific time on MSSP
  """
  def record_mssp_players(game, player_count, time) do
    :telemetry.execute([:grapevine, :statistics, :players, :record], %{count: player_count}, %{time: time})

    %PlayerStatistic{}
    |> PlayerStatistic.mssp_changeset(game, player_count, time)
    |> Repo.insert()
    |> broadcast_count()
  end

  def broadcast_count({:ok, player_statistics}) do
    PlayerPresence.update_count(player_statistics.game_id, player_statistics.player_count)
    {:ok, player_statistics}
  end

  def broadcast_count(result), do: result

  @doc """
  Record the start of a session
  """
  def record_web_client_started(game, sid, time \\ Timex.now()) do
    game
    |> Ecto.build_assoc(:sessions)
    |> Session.started_changeset(sid, time)
    |> Repo.insert()
  end

  @doc """
  Record the start of a session
  """
  def record_web_client_closed(sid, time \\ Timex.now()) do
    case Repo.get_by(Session, sid: sid) do
      nil ->
        {:error, :not_found}

      session ->
        session
        |> Session.closed_changeset(time)
        |> Repo.update()
    end
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

    interval = Timex.Interval.new(from: last_few_days, until: Timex.now(), step: [hours: 1])

    Enum.map(interval, fn time ->
      {time, find_nearest_stats(stats, time)}
    end)
  end

  defp find_nearest_stats(stats, time) do
    values =
      Enum.filter(stats, fn stat ->
        interval = Timex.Interval.new(from: time, until: [hours: 1])
        stat.recorded_at in interval
      end)

    case Enum.empty?(values) do
      true ->
        nil

      false ->
        values
        |> Enum.map(& &1.player_count)
        |> Enum.max()
    end
  end

  @doc """
  Get the most recent count of a game

  Restricting to the last hour
  """
  def most_recent_count(game) do
    last_hour =
      Timex.now()
      |> Timex.shift(minutes: -61)
      |> Timex.set(second: 0)
      |> DateTime.truncate(:second)

    PlayerStatistic
    |> select([ps], {ps.player_count, ps.recorded_at})
    |> where([ps], ps.game_id == ^game.id)
    |> where([ps], ps.recorded_at >= ^last_hour)
    |> order_by([ps], desc: ps.recorded_at)
    |> limit(1)
    |> Repo.one()
  end
end
