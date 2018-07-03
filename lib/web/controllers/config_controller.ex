defmodule Web.ConfigController do
  use Web, :controller

  plug Web.Plugs.VerifyUser

  def show(conn, _params) do
    render(conn, "show.html")
  end
end
