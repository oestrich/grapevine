defmodule Web.Manage.ClientController do
  use Web, :controller

  alias GrapevineData.Games
  alias GrapevineData.GameSettings
  alias GrapevineData.Gauges

  def show(conn, %{"game_id" => id}) do
    %{current_user: user} = conn.assigns

    with {:ok, game} <- Games.get(user, id) do
      conn
      |> assign(:game, game)
      |> assign(:gauges, Gauges.for(game))
      |> assign(:changeset, GameSettings.edit_client_settings(game))
      |> render("show.html")
    end
  end

  def update(conn, %{"game_id" => id, "client_settings" => params}) do
    %{current_user: user} = conn.assigns
    {:ok, game} = Games.get(user, id)

    with {:ok, _client_settings} <- GameSettings.update_client_settings(game, params) do
      conn
      |> put_flash(:info, "Updated!")
      |> redirect(to: manage_game_client_path(conn, :show, game.id))
    else
      {:error, :not_found} ->
        conn
        |> put_flash(:info, "Updated!")
        |> redirect(to: page_path(conn, :index))

      {:error, changeset} ->
        conn
        |> assign(:game, game)
        |> assign(:gauges, Gauges.for(game))
        |> assign(:changeset, changeset)
        |> render("show.html")
    end
  end
end
