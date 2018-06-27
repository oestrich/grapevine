defmodule Web.RegistrationController do
  use Web, :controller

  alias Gossip.Games

  def new(conn, _params) do
    changeset = Games.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"game" => params}) do
    case Games.register(params) do
      {:ok, game} ->
        conn
        |> put_flash(:info, "Your game has been registered! Welcome!")
        |> put_session(:game_token, game.token)
        |> redirect(to: page_path(conn, :index))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was a problem registering. Please try again.")
        |> put_status(422)
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end
end
