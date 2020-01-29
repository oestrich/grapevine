defmodule Web.Admin.OpenWebClientView do
  use Phoenix.HTML
  use Phoenix.LiveView

  alias GrapevineTelnet.Presence, as: TelnetPresence
  alias Web.TimeView
  alias Web.Router.Helpers, as: Routes

  def render(assigns) do
    ~L[
      <h4>Open Web Clients</h4>

      <table class="table">
        <thead>
          <tr>
            <th>Game</th>
            <th>Player Name</th>
            <th>Open Since</th>
            <th>Last Send</th>
          </tr>
        </thead>
        <tbody>
          <%= Enum.map(@clients, fn client -> %>
            <tr>
              <td><%= link(client.game.name, to: Routes.game_path(@socket, :show, client.game.short_name)) %></td>
              <td><%= client.player_name || "Anonymous Player" %></td>
              <td><%= TimeView.time(client.opened_at) %></td>
              <td><%= if client.last_sent_at, do: TimeView.time(client.last_sent_at) %></td>
            </tr>
          <% end) %>
        </tbody>
      </table>
    ]
  end

  def mount(_session, socket) do
    socket = assign(socket, :clients, TelnetPresence.online_clients())

    Web.Endpoint.subscribe("telnet:presence")

    {:ok, socket}
  end

  def handle_info(broadcast = %Phoenix.Socket.Broadcast{topic: "telnet:presence"}, socket) do
    case broadcast.event do
      "client/online" ->
        client_online(socket, broadcast.payload)

      "client/offline" ->
        client_offline(socket, broadcast.payload)

      "client/update" ->
        client_update(socket, broadcast.payload)
    end
  end

  defp client_online(socket, client) do
    socket = assign(socket, :clients, [client | socket.assigns.clients])
    {:noreply, socket}
  end

  defp client_offline(socket, client) do
    clients =
      Enum.reject(socket.assigns.clients, fn online_client ->
        client.pid == online_client.pid
      end)

    socket = assign(socket, :clients, clients)
    {:noreply, socket}
  end

  defp client_update(socket, client) do
    clients =
      Enum.reject(socket.assigns.clients, fn online_client ->
        client.pid == online_client.pid
      end)

    socket = assign(socket, :clients, [client | clients])
    {:noreply, socket}
  end
end
