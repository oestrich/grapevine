defmodule Web.Admin.ChannelController do
  use Web, :controller

  alias GrapevineData.Channels
  alias GrapevineData.Messages

  def index(conn, _params) do
    conn
    |> assign(:channels, Channels.all())
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    with {:ok, channel} <- Channels.get(id) do
      conn
      |> assign(:channel, channel)
      |> assign(:messages, Messages.for(channel))
      |> render("show.html")
    end
  end
end
