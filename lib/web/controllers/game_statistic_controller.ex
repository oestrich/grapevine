defmodule Web.GameStatisticController do
  use Web, :controller

  alias Grapevine.Games
  alias Grapevine.Statistics

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

  def players(conn, %{"game_id" => short_name}) do
    case Games.get_by_short(short_name) do
      {:ok, game} ->
        conn
        |> assign(:statistics, Statistics.last_few_days(game))
        |> render("players.json")

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Could not find that game.")
        |> redirect(to: page_path(conn, :index))
    end
  end
end
