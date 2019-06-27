defmodule Web.PlayController do
  use Web, :controller

  alias GrapevineData.Games
  alias Web.Game

  action_fallback(Web.FallbackController)

  def show(conn, %{"game_id" => short_name}) do
    with {:ok, game} <- Games.get_by_short(short_name, display: true),
         {:ok, game} <- Games.check_web_client(game),
         {:ok, game} <- check_user_allowed(conn, game) do
      conn
      |> assign(:game, game)
      |> assign(:title, "Play #{game.name}")
      |> assign(:open_graph_title, game.name)
      |> assign(:open_graph_description, "Play #{game.name} on Grapevine")
      |> assign(:open_graph_url, play_url(conn, :show, game.short_name))
      |> put_layout("fullscreen.html")
      |> render("show.html")
    else
      {:error, :not_found} ->
        {:error, :not_found}

      {:error, _} ->
        conn
        |> put_flash(:error, "The web client is disabled for this game.")
        |> redirect(to: page_path(conn, :index))
    end
  end

  def client(conn, _params) do
    with {:ok, game} <- Games.get_by_host(conn.host),
         {:ok, game} <- Games.check_web_client(game),
         {:ok, game} <- check_user_allowed(conn, game) do
      conn
      |> assign(:game, game)
      |> assign(:title, "Play #{game.name}")
      |> assign(:open_graph_title, game.name)
      |> assign(:open_graph_description, "Play #{game.name} on Grapevine")
      |> assign(:open_graph_url, play_url(conn, :show, game.short_name))
      |> put_layout("cname.html")
      |> render("show.html")
    else
      {:error, _} ->
        {:error, :not_found}
    end
  end

  defp check_user_allowed(conn, game) do
    case Game.client_allowed?(game, conn.assigns, :current_user) do
      true ->
        {:ok, game}

      false ->
        {:error, :not_allowed}
    end
  end
end
