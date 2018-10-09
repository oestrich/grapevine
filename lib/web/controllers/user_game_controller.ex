defmodule Web.UserGameController do
  use Web, :controller

  plug Web.Plugs.VerifyUser

  alias Gossip.Games

  def index(conn, _params) do
    %{current_user: user} = conn.assigns

    conn
    |> assign(:changeset, Games.new())
    |> assign(:games, Games.for_user(user))
    |> render("index.html")
  end

  def create(conn, %{"game" => params}) do
    %{current_user: user} = conn.assigns

    case Games.register(user, params) do
      {:ok, _game} ->
        conn
        |> put_flash(:info, "Game created!")
        |> redirect(to: user_game_path(conn, :index))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the game.")
        |> assign(:changeset, changeset)
        |> render("index.html")
    end
  end
end
