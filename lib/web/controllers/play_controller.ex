defmodule Web.PlayController do
  use Web, :controller

  alias Grapevine.Games

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
    case game.allow_anonymous_client do
      true ->
        {:ok, game}

      false ->
        case Map.has_key?(conn.assigns, :user) && conn.assigns.user != nil do
          true ->
            {:ok, game}

          false ->
            {:error, :user_required}
        end
    end
  end
end
