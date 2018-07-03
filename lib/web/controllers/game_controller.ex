defmodule Web.GameController do
  use Web, :controller

  plug Web.Plugs.VerifyUser

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
