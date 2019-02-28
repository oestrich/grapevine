defmodule Web.RegistrationController do
  use Web, :controller

  alias Grapevine.Accounts
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
        |> put_flash(:info, "You have registered! Please check your email to verify your account.")
        |> put_session(:user_token, user.token)
        |> SessionController.after_sign_in_redirect()

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was a problem registering. Please try again.")
        |> put_status(422)
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end
end
