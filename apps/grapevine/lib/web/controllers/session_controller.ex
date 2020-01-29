defmodule Web.SessionController do
  use Web, :controller

  alias GrapevineData.Accounts

  def new(conn, _params) do
    changeset = Accounts.new()

    conn
    |> assign(:layout_flash, false)
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Accounts.validate_login(email, password) do
      {:ok, user} ->
        :telemetry.execute([:grapevine, :accounts, :session, :login], %{count: 1})

        conn
        |> put_flash(:info, "You have signed in.")
        |> put_session(:user_token, user.token)
        |> after_sign_in_redirect(Routes.page_path(conn, :index))

      {:error, :invalid} ->
        conn
        |> put_flash(:error, "Your email or password is invalid")
        |> redirect(to: session_path(conn, :new))
    end
  end

  def delete(conn, _params) do
    :telemetry.execute([:grapevine, :accounts, :session, :logout], %{count: 1})

    conn
    |> clear_session()
    |> redirect(to: page_path(conn, :index))
  end

  @doc """
  Redirect to the last seen page after being asked to sign in

  Or the home page
  """
  def after_sign_in_redirect(conn, default_path) do
    case get_session(conn, :last_path) do
      nil ->
        redirect(conn, to: default_path)

      path ->
        conn
        |> put_session(:last_path, nil)
        |> redirect(to: path)
    end
  end
end
