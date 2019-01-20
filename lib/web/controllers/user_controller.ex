defmodule Web.UserController do
  use Web, :controller

  plug(Web.Plugs.VerifyScopes, scope: "profile")

  def show(conn, _params) do
    conn
    |> assign(:user, conn.assigns.current_user)
    |> assign(:scopes, conn.assigns.current_scopes)
    |> render("show.json")
  end
end
