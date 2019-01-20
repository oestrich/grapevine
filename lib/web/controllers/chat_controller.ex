defmodule Web.ChatController do
  use Web, :controller

  alias Grapevine.Channels

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def show(conn, %{"id" => name}) do
    case Channels.get(name) do
      {:ok, channel} ->
        conn
        |> assign(:channel, channel)
        |> render("show.html")

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Unknown channel")
        |> redirect(to: chat_path(conn, :index))
    end
  end
end
