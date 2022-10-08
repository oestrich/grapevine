defmodule Web.GameStatisticController do
  use Web, :controller

  alias GrapevineData.Games
  alias GrapevineData.Statistics

  action_fallback(Web.FallbackController)

  def show(conn, %{"game_id" => short_name}) do
    with {:ok, game} <- Games.get_by_short(short_name, display: true) do
      conn
      |> assign(:game, game)
      |> assign(:title, "#{game.name} Statistics - Grapevine")
      |> assign(:open_graph_title, game.name)
      |> assign(:open_graph_description, game.description)
      |> assign(:open_graph_url, game_statistic_url(conn, :show, game.short_name))
      |> render("show.html")
    end
  end

  def players(conn, params = %{"game_id" => short_name}) do
    case Games.get_by_short(short_name) do
      {:ok, game} ->
        conn
        |> assign(:statistics, Statistics.player_statistics(game, stat_type(params), series_days(params), series_step(params)))
        |> put_resp_header("cache-control", "public, max-age=3600")
        |> render("players.json")

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Could not find that game.")
        |> redirect(to: page_path(conn, :index))
    end
  end

  def players(conn, params = %{"game_id" => short_name, "series" => "tod"}) do
    case Games.get_by_short(short_name) do
      {:ok, game} ->
        conn
        |> assign(:statistics, Statistics.last_week_time_of_day(game, stat_type(params)))
        |> put_resp_header("cache-control", "public, max-age=3600")
        |> render("players-tod.json")

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Could not find that game.")
        |> redirect(to: page_path(conn, :index))
    end
  end

  defp stat_type(%{"type" => "avg"}), do: :avg

  defp stat_type(%{"type" => "max"}), do: :max

  defp stat_type(%{"type" => "min"}), do: :min

  defp stat_type(_), do: :max

  # Values for different data series
  defp series_days(%{"series" => "48-hours"}), do: 2
  defp series_days(%{"series" => "week"}),     do: 7
  defp series_days(%{"series" => "month"}),    do: 30
  defp series_days(%{"series" => "year"}),     do: 360
  defp series_days(_),                         do: 2

  defp series_step(%{"series" => "48-hours"}), do: 1
  defp series_step(%{"series" => "week"}),     do: 4
  defp series_step(%{"series" => "month"}),    do: 24
  defp series_step(%{"series" => "year"}),     do: 168
  defp series_step(_),                         do: 1

end
