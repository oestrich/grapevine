defmodule Web.CurrentPlayerCountView do
  use Phoenix.HTML
  use Phoenix.LiveView

  alias Grapevine.PlayerPresence

  def render(assigns) do
    ~L[
      <div class="lead">
        Join the other <%= @count %> players on the network.
      </div>
    ]
  end

  def mount(_session, socket) do
    Web.Endpoint.subscribe("player:presence")
    socket = assign(socket, :count, PlayerPresence.current_total_count())
    {:ok, socket}
  end

  def handle_info(broadcast = %Phoenix.Socket.Broadcast{topic: "player:presence"}, socket) do
    socket = assign(socket, :count, broadcast.payload.count)
    {:noreply, socket}
  end
end
