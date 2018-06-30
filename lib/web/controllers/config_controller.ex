defmodule Web.ConfigController do
  use Web, :controller

  plug Web.Plugs.VerifyGame

  def show(conn, _params) do
    render(conn, "show.html")
  end
end
