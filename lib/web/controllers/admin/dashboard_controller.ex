defmodule Web.Admin.DashboardController do
  use Web, :controller

  def index(conn, _params) do
    conn
    |> render("index.html")
  end
end
