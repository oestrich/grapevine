defmodule Web.RegistrationResetController do
  use Web, :controller

  alias GrapevineData.Accounts

  def new(conn, _params) do
    changeset = Accounts.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"user" => %{"email" => email}}) do
    Accounts.start_password_reset(email)

    conn
    |> put_flash(:info, "Password reset started!")
    |> redirect(to: session_path(conn, :new))
  end

  def edit(conn, %{"token" => token}) do
    changeset = Accounts.new()

    conn
    |> assign(:token, token)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"token" => token, "user" => params}) do
    case Accounts.reset_password(token, params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Password reset!")
        |> redirect(to: session_path(conn, :new))

      _error ->
        conn
        |> put_flash(:info, "There was an issue resetting.")
        |> redirect(to: session_path(conn, :new))
    end
  end
end
