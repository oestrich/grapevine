defmodule Web.SessionController do
  use Web, :controller

  alias Gossip.Games

  def new(conn, _params) do
    changeset = Games.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"game" => %{"email" => email, "password" => password}}) do
    case Games.validate_login(email, password) do
      {:ok, game} ->
        conn
        |> put_session(:game_token, game.token)
        |> redirect(to: page_path(conn, :index))

      {:error, :invalid} ->
        conn
        |> put_flash(:error, "Your email or password is invalid")
        |> redirect(to: session_path(conn, :new))
    end
  end

  def delete(conn, _params) do
    conn
    |> clear_session()
    |> redirect(to: page_path(conn, :index))
  end
end
