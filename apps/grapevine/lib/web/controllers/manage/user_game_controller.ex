defmodule Web.Manage.UserGameController do
  use Web, :controller

  plug(Web.Plugs.VerifyUser)

  alias GrapevineData.Games

  def index(conn, _params) do
    %{current_user: user} = conn.assigns

    conn
    |> assign(:games, Games.for_user(user))
    |> render("index.html")
  end
end
