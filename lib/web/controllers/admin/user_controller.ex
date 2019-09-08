defmodule Web.Admin.UserController do
  use Web, :controller

  alias GrapevineData.Accounts

  plug(Web.Plugs.FetchPage)

  def index(conn, _params) do
    %{page: page, per: per} = conn.assigns
    %{page: users, pagination: pagination} = Accounts.all(page: page, per: per)

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
end
