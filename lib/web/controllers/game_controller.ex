defmodule Web.GameController do
  use Web, :controller

  alias Gossip.Games
  alias Gossip.Presence

  plug Web.Plugs.VerifyUser when action in [:edit, :update, :regenerate]

  def index(conn, _params) do
    games = Enum.filter(Presence.online_games(), &(&1.game.display))

    conn
    |> assign(:games, games)
    |> render("index.html")
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
        |> redirect(to: user_game_path(conn, :index))
    end
  end

  def update(conn, %{"id" => id, "game" => params}) do
    %{current_user: user} = conn.assigns

    with {:ok, game} <- Games.get(user, id),
         {:ok, _game} <- Games.update(game, params) do
      conn
      |> put_flash(:info, "Game updated!")
      |> redirect(to: user_game_path(conn, :index))
    end
  end

  def regenerate(conn, %{"id" => id}) do
    %{current_user: user} = conn.assigns

    case Games.regenerate_client_tokens(user, id) do
      {:ok, _game} ->
        conn
        |> put_flash(:info, "Game updated!")
        |> redirect(to: user_game_path(conn, :index))

      {:error, _} ->
        conn
        |> put_flash(:error, "An error occurred, please try again.")
        |> redirect(to: user_game_path(conn, :index))
    end
  end
end
