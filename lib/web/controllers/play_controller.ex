defmodule Web.PlayController do
  use Web, :controller

  def show(conn, _params) do
    render(conn, "show.html")
  end
end
