defmodule Web.Manage.SettingController do
  use Web, :controller

  alias Grapevine.Accounts
  alias GrapevineData.Games

  plug(Web.Plugs.VerifyUser)

  def show(conn, _params) do
    %{current_user: user} = conn.assigns

    conn
    |> assign(:changeset, Accounts.edit(user))
    |> assign(:games, Games.for_user(user))
    |> render("show.html")
  end

  def update(conn, %{"user" => params = %{"current_password" => current_password}}) do
    %{current_user: user} = conn.assigns

    case Accounts.change_password(user, current_password, params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Profile updated!")
        |> redirect(to: manage_setting_path(conn, :show))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "There was a problem updating.")
        |> redirect(to: manage_setting_path(conn, :show))
    end
  end

  def update(conn, %{"user" => params}) do
    %{current_user: user} = conn.assigns

    case Accounts.update(user, params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Profile updated!")
        |> redirect(to: manage_setting_path(conn, :show))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "There was a problem updating.")
        |> redirect(to: manage_setting_path(conn, :show))
    end
  end

  def verify(conn, _params) do
    %{current_user: user} = conn.assigns

    Accounts.reset_email_verification(user)

    notice = "Verification email sent. Please check your mailbox to confirm your email address."

    conn
    |> put_flash(:info, notice)
    |> redirect(to: Routes.page_path(conn, :index))
  end
end
