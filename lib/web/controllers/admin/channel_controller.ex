defmodule Web.Admin.ChannelController do
  use Web, :controller

  alias Grapevine.Channels
  alias GrapevineData.Messages

  def index(conn, _params) do
    conn
    |> assign(:channels, Channels.all(include_hidden: true))
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    with {:ok, channel} <- Channels.get(id) do
      messages = Messages.for(channel)

      conn
      |> assign(:channel, channel)
      |> assign(:messages, messages)
      |> render(:show)
    end
  end

  def pause(conn, %{"id" => id}) do
    with {:ok, channel} <- Channels.get(id) do
      Channels.pause(channel.name)

      conn
      |> put_flash(:info, "Channel was paused")
      |> redirect(to: Routes.admin_channel_path(conn, :show, id))
    end
  end
end
