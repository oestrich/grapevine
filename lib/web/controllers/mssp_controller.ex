defmodule Web.MSSPController do
  use Web, :controller

  def index(conn, _params) do
    conn
    |> assign(:title, "MSSP Check - Gossip")
    |> assign(:open_graph_title, "MSSP Check")
    |> assign(:open_graph_description, "Check your game's MSSP data with Gossip")
    |> assign(:open_graph_url, mssp_url(conn, :index))
    |> render("index.html")
  end
end
