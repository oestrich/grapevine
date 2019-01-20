defmodule Web.MSSPController do
  use Web, :controller

  def index(conn, _params) do
    conn
    |> assign(:title, "MSSP Check - Grapevine")
    |> assign(:open_graph_title, "MSSP Check")
    |> assign(:open_graph_description, "Check your game's MSSP data with Grapevine")
    |> assign(:open_graph_url, mssp_url(conn, :index))
    |> render("index.html")
  end
end
