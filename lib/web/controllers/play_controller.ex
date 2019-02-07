defmodule Web.PlayController do
  use Web, :controller

  alias Grapevine.Games
  alias Web.Game

  def show(conn, %{"game_id" => short_name}) do
    with {:ok, game} <- Games.get_by_short(short_name, display: true),
         {:ok, game} <- Games.check_web_client(game),
         {:ok, game} <- check_user_allowed(conn, game) do
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

  defp check_user_allowed(conn, game) do
    case Game.client_allowed?(game, conn.assigns) do
      true ->
        {:ok, game}

      false ->
        {:error, :not_allowed}
    end
  end
end
