defmodule Web.Manage.HostedSiteController do
  use Web, :controller

  alias GrapevineData.Games

  def show(conn, %{"game_id" => id}) do
    %{current_user: user} = conn.assigns

    with {:ok, game} <- Games.get(user, id) do
      conn
      |> assign(:game, game)
      |> assign(:changeset, Games.edit_hosted_settings(game))
      |> render("show.html")
    end
  end

  def update(conn, %{"game_id" => id, "hosted_settings" => params}) do
    %{current_user: user} = conn.assigns
    {:ok, game} = Games.get(user, id)

    with {:ok, _hosted_settings} <- Games.update_hosted_settings(game, params) do
      conn
      |> put_flash(:info, "Updated!")
      |> redirect(to: manage_game_hosted_site_path(conn, :show, game.id))
    else
      {:error, :not_found} ->
        conn
        |> put_flash(:info, "Updated!")
        |> redirect(to: page_path(conn, :index))

      {:error, changeset} ->
        conn
        |> assign(:game, game)
        |> assign(:changeset, changeset)
        |> render("show.html")
    end
  end
end
