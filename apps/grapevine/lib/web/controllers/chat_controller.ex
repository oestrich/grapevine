defmodule Web.ChatController do
  use Web, :controller

  alias GrapevineData.Channels

  def index(conn, _params) do
    conn
    |> assign(:channels, Channels.all())
    |> assign(:title, "Grapevine Chat")
    |> put_layout("fullscreen.html")
    |> render("index.html")
  end
end
