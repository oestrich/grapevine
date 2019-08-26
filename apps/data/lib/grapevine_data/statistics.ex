defmodule GrapevineData.Statistics do
  @moduledoc """
  Track statistics about a game
  """

  import Ecto.Query

  alias GrapevineData.Repo
  alias GrapevineData.Statistics.PlayerStatistic
  alias GrapevineData.Statistics.Session
  alias Stein.Pagination

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
    case :pg2.get_members(Grapevine.PlayerPresence) do
      members when is_list(members) ->
        Enum.each(members, fn pid ->
          %{game_id: game_id, player_count: count} = player_statistics
          GenServer.cast(pid, {:update_count, game_id, count})
        end)

        {:ok, player_statistics}

      {:error, {:no_such_group, Grapevine.PlayerPresence}} ->
        {:ok, player_statistics}
    end
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
  Fetch recent sessions
  """
  def recent_sessions(opts \\ []) do
    opts = Enum.into(opts, %{})

    query =
      Session
      |> preload([:game])
      |> order_by([s], desc: s.started_at)

    Pagination.paginate(Repo, query, opts)
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
      {time, find_nearest_stats(stats, time, :max, [hours: 1])}
    end)
  end

  @doc """
  Get the last week's worth of statistics
  """
  def last_week(game, type) do
    last_few_days =
      Timex.now()
      |> Timex.shift(days: -7)
      |> Timex.set(minute: 0, second: 0)
      |> DateTime.truncate(:second)

    stats =
      PlayerStatistic
      |> where([ps], ps.game_id == ^game.id)
      |> where([ps], ps.recorded_at >= ^last_few_days)
      |> Repo.all()

    interval = Timex.Interval.new(from: last_few_days, until: Timex.now(), step: [hours: 4])

    Enum.map(interval, fn time ->
      {time, find_nearest_stats(stats, time, type, [hours: 4])}
    end)
  end

  defp find_nearest_stats(stats, time, type, time_opts) do
    values =
      Enum.filter(stats, fn stat ->
        interval = Timex.Interval.new(from: time, until: time_opts)
        stat.recorded_at in interval
      end)

    case Enum.empty?(values) do
      true ->
        nil

      false ->
        values
        |> Enum.map(& &1.player_count)
        |> select_time(type)
    end
  end

  defp select_time([], _type), do: 0

  defp select_time(values, :avg) when is_list(values) do
    Enum.sum(values) / length(values)
  end

  defp select_time(values, :max), do: Enum.max(values)

  defp select_time(values, :min), do: Enum.min(values)

  @doc """
  Get stats by time of day for the last week
  """
  def last_week_time_of_day(game, type) do
    last_few_days =
      Timex.now()
      |> Timex.shift(days: -7)
      |> Timex.set(minute: 0, second: 0)
      |> DateTime.truncate(:second)

    stats =
      PlayerStatistic
      |> where([ps], ps.game_id == ^game.id)
      |> where([ps], ps.recorded_at >= ^last_few_days)
      |> Repo.all()

    hours =
      Enum.into(0..23, %{}, fn hour ->
        {hour, []}
      end)

    stats
    |> Enum.reduce(hours, fn stat, hours ->
      hour = Map.get(hours, stat.recorded_at.hour)
      Map.put(hours, stat.recorded_at.hour, [stat | hour])
    end)
    |> Enum.map(fn {hour, values} ->
      value =
        values
        |> Enum.map(& &1.player_count)
        |> select_time(type)

      {hour, value}
    end)
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
