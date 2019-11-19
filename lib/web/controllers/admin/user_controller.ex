defmodule Web.Admin.UserController do
  use Web, :controller

  alias GrapevineData.Accounts

  plug(Web.Plugs.FetchPage)

  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    %{page: users, pagination: pagination} = Accounts.all(filter: params, page: page, per: per)

    conn
    |> assign(:users, users)
    |> assign(:pagination, pagination)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    with {:ok, user} <- Accounts.get(id) do
      conn
      |> assign(:user, user)
      |> render("show.html")
    end
  end

  def delete(conn, params = %{"id" => id}) do
    with {:ok, user} <- Accounts.get(id),
         {:ok, _user} <- Accounts.delete(user) do
      conn
      |> put_flash(:info, "Account removed.")
      |> redirect(to: delete_redirect_path(conn, params))
    else
      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :owns_game} ->
        conn
        |> put_flash(:error, "Could not remove account, it owns a game.")
        |> redirect(to: delete_redirect_path(conn, params))

      {:error, :verified} ->
        conn
        |> put_flash(:error, "Could not remove account, it's verified.")
        |> redirect(to: delete_redirect_path(conn, params))
    end
  end

  defp delete_redirect_path(conn, %{"back" => "unverified"}) do
    Routes.admin_user_path(conn, :index, unverified: true)
  end

  defp delete_redirect_path(conn, _params) do
    Routes.admin_user_path(conn, :index)
  end
end
