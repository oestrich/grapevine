defmodule Web.GameController do
  use Web, :controller

  alias Gossip.Presence

  def index(conn, _params) do
    conn
    |> assign(:games, Presence.online_games())
    |> render("index.html")
  end
end
