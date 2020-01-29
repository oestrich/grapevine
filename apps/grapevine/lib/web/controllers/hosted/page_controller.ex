defmodule Web.Hosted.PageController do
  use Web, :controller

  alias Web.Hosted

  action_fallback(Web.FallbackController)

  def index(conn, _params) do
    %{current_game: game} = conn.assigns

    conn
    |> put_layout("hosted.html")
    |> put_view(Hosted.GameView)
    |> assign(:game, game)
    |> assign(:hosted_settings, game.hosted_settings)
    |> assign(:title, game.name)
    |> assign(:open_graph_title, game.name)
    |> assign(:open_graph_description, "#{game.name} on Grapevine")
    |> render("show.html")
  end
end
