defmodule Web.PlayChannel do
  @moduledoc """
  Follow along with the grapevine from the site
  """

  use Phoenix.Channel

  alias Grapevine.Games
  alias Grapevine.Telnet.WebClient

  def join("play:client", message, socket) do
    case Map.has_key?(socket.assigns, :user) do
      true ->
        with {:ok, socket} <- assign_game(socket, message) do
          start_client(socket)
        end

      false ->
        {:error, %{reason: "user required"}}
    end
  end

  defp assign_game(socket, message) do
    with {:ok, short_name} <- Map.fetch(message, "game"),
         {:ok, game} <- Games.get_by_short(short_name) do
      {:ok, assign(socket, :game, game)}
    else
      :error ->
        {:error, %{reason: "must connect to a game"}}
    end
  end

  def start_client(socket) do
    {:ok, pid} = WebClient.start_link(
      host: "mclmud.mclink.it",
      port: 6000,
      channel_pid: socket.channel_pid
    )

    socket = assign(socket, :client_pid, pid)

    {:ok, socket}
  end

  def handle_in("send", %{"message" => message}, socket) do
    WebClient.recv(socket.assigns.client_pid, message)
    {:noreply, socket}
  end

  def handle_info({:echo, data}, socket) do
    push(socket, "echo", %{message: data})
    {:noreply, socket}
  end
end
