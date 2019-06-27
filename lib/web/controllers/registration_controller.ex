defmodule Web.RegistrationController do
  use Web, :controller

  alias Grapevine.Accounts
  alias GrapevineData.Games
  alias Web.SessionController

  def new(conn, _params) do
    changeset = Accounts.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"user" => params}) do
    case Accounts.register(params) do
      {:ok, user} ->
        conn
        |> put_session(:user_token, user.token)
        |> SessionController.after_sign_in_redirect(Routes.registration_path(conn, :finalize))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was a problem registering. Please try again.")
        |> put_status(422)
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def finalize(conn, _params) do
    conn
    |> assign(:games, Games.featured())
    |> render("finalize.html")
  end
end
