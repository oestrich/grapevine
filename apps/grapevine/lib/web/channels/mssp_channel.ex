defmodule Web.MSSPChannel do
  @moduledoc """
  Follow along with the grapevine from the site
  """

  use Web, :channel

  alias Grapevine.Telnet.MSSPClient

  def join("mssp:" <> id, _message, socket) do
    {:ok, assign(socket, :id, id)}
  end

  def handle_in("check", options, socket) do
    MSSPClient.start_link(
      type: :check,
      host: options["host"],
      port: String.to_integer(options["port"]),
      channel: socket.assigns.id
    )

    {:noreply, socket}
  end
end
