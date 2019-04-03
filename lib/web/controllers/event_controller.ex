defmodule Web.EventController do
  use Web, :controller

  alias Grapevine.Events

  def index(conn, _params) do
    conn
    |> assign(:events, Events.next_month())
    |> render("index.html")
  end
end
