defmodule Web.PageController do
  use Web, :controller

  alias Grapevine.Presence
  alias Web.Game

  def index(conn, _params) do
    conn
    |> assign(:games, Enum.map(Presence.online_games(), &(&1.game)))
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

  def colors(conn, _params) do
    render(conn, "colors.html")
  end
end
