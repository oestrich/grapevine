defmodule Web.Manage.GameController do
  use Web, :controller

  alias GrapevineData.Games
  alias GrapevineTelnet.Presence, as: TelnetPresence

  plug(Web.Plugs.VerifyUser)

  def show(conn, %{"id" => id}) do
    %{current_user: user} = conn.assigns

    case Games.get(user, id) do
      {:ok, game} ->
        conn
        |> assign(:game, game)
        |> assign(:clients, TelnetPresence.online_clients_for(game))
        |> render("show.html")

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Could not find that game.")
        |> redirect(to: page_path(conn, :index))
    end
  end

  def new(conn, _params) do
    conn
    |> assign(:changeset, Games.new())
    |> render("new.html")
  end

  def create(conn, %{"game" => params}) do
    %{current_user: user} = conn.assigns

    case Games.register(user, params) do
      {:ok, game} ->
        conn
        |> put_flash(:info, "Game created!")
        |> redirect(to: manage_game_path(conn, :show, game.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the game.")
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    %{current_user: user} = conn.assigns

    case Games.get(user, id) do
      {:ok, game} ->
        conn
        |> assign(:game, game)
        |> assign(:changeset, Games.edit(game))
        |> render("edit.html")

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Could not find that game.")
        |> redirect(to: manage_setting_path(conn, :show))
    end
  end

  def update(conn, %{"id" => id, "game" => params}) do
    %{current_user: user} = conn.assigns

    {:ok, game} = Games.get(user, id)

    case Games.update(game, params) do
      {:ok, game} ->
        conn
        |> put_flash(:info, "Game updated!")
        |> redirect(to: manage_game_path(conn, :show, game.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was a problem updating.")
        |> assign(:game, game)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end

  def regenerate(conn, %{"id" => id}) do
    %{current_user: user} = conn.assigns

    case Games.regenerate_client_tokens(user, id) do
      {:ok, game} ->
        conn
        |> put_flash(:info, "Game updated!")
        |> redirect(to: manage_game_path(conn, :show, game.id))

      {:error, _} ->
        conn
        |> put_flash(:error, "An error occurred, please try again.")
        |> redirect(to: manage_setting_path(conn, :show))
    end
  end
end
