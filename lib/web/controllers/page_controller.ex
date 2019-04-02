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
    conn
    |> assign(:title, "About Grapevine")
    |> assign(:open_graph_title, "About Grapevine")
    |> assign(:open_graph_description, "Learn more about MUDs and Grapevine.")
    |> assign(:open_graph_url, page_url(conn, :about))
    |> render("about.html")
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
