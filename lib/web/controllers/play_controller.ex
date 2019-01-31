defmodule Web.PlayController do
  use Web, :controller

  alias Grapevine.Games

  def show(conn, %{"game_id" => short_name}) do
    with {:ok, game} <- Games.get_by_short(short_name, display: true),
         {:ok, game} <- Games.check_web_client(game) do
      conn
      |> assign(:game, game)
      |> put_layout("fullscreen.html")
      |> render("show.html")
    else
      {:error, _} ->
        conn
        |> put_flash(:error, "The web client is disabled for this game.")
        |> redirect(to: page_path(conn, :index))
    end
  end
end
