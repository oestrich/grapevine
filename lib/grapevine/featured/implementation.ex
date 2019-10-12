defmodule Grapevine.Featured.Implementation do
  @moduledoc """
  Implementation details for the Featured GenServer
  """

  import Ecto.Query

  require Logger

  alias GrapevineData.Games
  alias GrapevineData.Repo

  @doc """
  Calculate the delay to the next cycle check which runs at 6 AM UTC
  """
  def calculate_next_cycle_delay(now) do
    now
    |> Timex.set(hour: 6, minute: 0, second: 0)
    |> maybe_shift_a_day(now)
    |> Timex.diff(now, :milliseconds)
  end

  defp maybe_shift_a_day(next_run, now) do
    case Timex.before?(now, next_run) do
      true ->
        next_run

      false ->
        Timex.shift(next_run, days: 1)
    end
  end

  @doc """
  Select the featured games for that day
  """
  def select_featured() do
    Ecto.Multi.new()
    |> reset_all()
    |> update_selected()
    |> Repo.transaction()
  end

  defp reset_all(multi) do
    Ecto.Multi.update_all(multi, :update_all, GrapevineData.Games.Game, set: [featured_order: nil])
  end

  defp update_selected(multi) do
    featured_games()
    |> Enum.with_index()
    |> Enum.reduce(multi, fn {game, order}, multi ->
      changeset =
        game
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_change(:featured_order, order)

      Ecto.Multi.update(multi, {:game, game.id}, changeset)
    end)
  end

  def featured_games() do
    top_games = top_games_player_count([])
    selected_ids = Enum.map(top_games, & &1.id)

    random_games_using = random_games_using_grapevine(already_picked: selected_ids)
    selected_ids = selected_ids ++ Enum.map(random_games_using, & &1.id)

    random_games = random_games(already_picked: selected_ids)

    Enum.shuffle(top_games ++ random_games_using ++ random_games)
  end

  def top_games_player_count(opts) do
    last_few_days =
      Timex.now()
      |> Timex.shift(days: -2)
      |> Timex.set(minute: 0, second: 0)
      |> DateTime.truncate(:second)

    active_cutoff = Timex.now() |> Timex.shift(minutes: -3)
    mssp_cutoff = Timex.now() |> Timex.shift(minutes: -90)

    limit = Keyword.get(opts, :select, 6)
    already_picked_game_ids = Keyword.get(opts, :already_picked, [])

    GrapevineData.Statistics.PlayerStatistic
    |> select([ps], ps.game_id)
    |> join(:left, [ps], g in assoc(ps, :game))
    |> where([ps, g], ps.recorded_at >= ^last_few_days)
    |> where([ps, g], g.display == true and g.featurable and not is_nil(g.cover_key))
    |> where([ps, g], g.last_seen_at > ^active_cutoff or g.telnet_last_seen_at > ^mssp_cutoff)
    |> where([ps, g], ps.game_id not in ^already_picked_game_ids)
    |> group_by([ps, g], [ps.game_id])
    |> order_by([ps, g], desc: max(ps.player_count))
    |> limit(^limit)
    |> Repo.all()
    |> Enum.map(fn game_id ->
      {:ok, game} = Games.get(game_id)
      game
    end)
    |> log_games()
  end

  def random_games_using_grapevine(opts) do
    active_cutoff = Timex.now() |> Timex.shift(minutes: -3)

    limit = Keyword.get(opts, :select, 3)
    already_picked_game_ids = Keyword.get(opts, :already_picked, [])

    GrapevineData.Games.Game
    |> base_query(already_picked_game_ids)
    |> where([g], g.last_seen_at > ^active_cutoff)
    |> Repo.all()
    |> log_games()
    |> Enum.shuffle()
    |> Enum.take(limit)
  end

  def random_games(opts) do
    mssp_cutoff = Timex.now() |> Timex.shift(minutes: -90)

    limit = Keyword.get(opts, :select, 3)
    already_picked_game_ids = Keyword.get(opts, :already_picked, [])

    GrapevineData.Games.Game
    |> base_query(already_picked_game_ids)
    |> where([g], g.telnet_last_seen_at > ^mssp_cutoff)
    |> Repo.all()
    |> log_games()
    |> Enum.shuffle()
    |> Enum.take(limit)
  end

  defp base_query(query, already_picked_game_ids) do
    query
    |> where([g], g.display == true and g.featurable and not is_nil(g.cover_key))
    |> where([g], g.id not in ^already_picked_game_ids)
  end

  defp log_games(games) do
    Enum.map(games, fn game ->
      Logger.info("Picking #{game.name} for featured", type: :featured)
      game
    end)
  end
end
