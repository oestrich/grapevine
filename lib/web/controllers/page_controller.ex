defmodule Web.PageController do
  use Web, :controller

  alias Gossip.Presence
  alias Web.Game

  def index(conn, _params) do
    game = Game.highlighted_game(Presence.online_games())

    conn
    |> assign(:highlighted_game, game)
    |> render("index.html")
  end

  def conduct(conn, _params) do
    render(conn, "conduct.html")
  end

  def docs(conn, _params) do
    render(conn, "docs.html")
  end

  def media(conn, _params) do
    render(conn, "media.html")
  end
end
