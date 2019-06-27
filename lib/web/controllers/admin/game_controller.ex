defmodule Web.Admin.GameController do
  use Web, :controller

  alias GrapevineData.Games

  def index(conn, _params) do
    conn
    |> assign(:games, Games.all())
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    with {:ok, game} <- Games.get(id) do
      conn
      |> assign(:game, game)
      |> render("show.html")
    end
  end
end
