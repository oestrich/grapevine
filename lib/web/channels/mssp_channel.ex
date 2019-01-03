defmodule Web.MSSPChannel do
  @moduledoc """
  Follow along with the gossip from the site
  """

  use Phoenix.Channel

  alias Gossip.Telnet

  def join("mssp:" <> id, _message, socket) do
    {:ok, assign(socket, :id, id)}
  end

  def handle_in("check", options, socket) do
    Telnet.Client.start_link([
      type: :check,
      host: options["host"],
      port: String.to_integer(options["port"]),
      channel: socket.assigns.id
    ])

    {:noreply, socket}
  end
end
