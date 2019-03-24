defmodule Web.Client.PlayController do
  use Web, :controller

  alias Grapevine.Games
  alias Web.Game

  action_fallback(Web.FallbackController)

  def show(conn, _params) do
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
      |> put_view(Web.PlayView)
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
