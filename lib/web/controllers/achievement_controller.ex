defmodule Web.AchievementController do
  use Web, :controller

  alias GrapevineData.Achievements
  alias GrapevineData.Games

  action_fallback(Web.FallbackController)

  def index(conn, %{"game_id" => game_name}) do
    with {:ok, game} <- Games.get_by_short(game_name, display: true) do
      conn
      |> assign(:game, game)
      |> assign(:achievements, Achievements.for(game))
      |> assign(:title, "#{game.name} Achievements - Grapevine")
      |> assign(:open_graph_title, "#{game.name} Achievements")
      |> assign(:open_graph_url, game_achievement_url(conn, :index, game.short_name))
      |> render("index.html")
    end
  end
end
