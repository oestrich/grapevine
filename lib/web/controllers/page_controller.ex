defmodule Web.PageController do
  use Web, :controller

  alias Grapevine.Games

  action_fallback(Web.FallbackController)

  def index(conn, _params) do
    conn
    |> assign(:games, Games.featured())
    |> render("index.html")
  end

  def about(conn, _params) do
    render(conn, "about.html")
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
