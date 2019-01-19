defmodule Web.RegistrationController do
  use Web, :controller

  alias Gossip.Accounts

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
        |> put_flash(:info, "You have registered! Welcome!")
        |> put_session(:user_token, user.token)
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
