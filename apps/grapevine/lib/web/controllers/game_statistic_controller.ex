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

  def players(conn, %{"game_id" => short_name, "series" => "48-hours"}) do
    case Games.get_by_short(short_name) do
      {:ok, game} ->
        conn
        |> assign(:statistics, Statistics.last_few_days(game))
        |> put_resp_header("cache-control", "public, max-age=3600")
        |> render("players.json")

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Could not find that game.")
        |> redirect(to: page_path(conn, :index))
    end
  end

  def players(conn, params = %{"game_id" => short_name, "series" => "week"}) do
    case Games.get_by_short(short_name) do
      {:ok, game} ->
        conn
        |> assign(:statistics, Statistics.last_week(game, stat_type(params)))
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
end
