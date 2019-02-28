defmodule Web.PlayChannel do
  @moduledoc """
  Follow along with the grapevine from the site
  """

  use Phoenix.Channel

  alias Grapevine.Games
  alias Telnet.WebClient
  alias Web.Game

  def join("play:client", message, socket) do
    case Map.has_key?(socket.assigns, :session_token) do
      true ->
        with {:ok, socket} <- assign_game(socket, message) do
          send(self(), :start_client)
          {:ok, socket}
        end

      false ->
        {:error, %{reason: "user required"}}
    end
  end

  defp assign_game(socket, message) do
    with {:ok, short_name} <- Map.fetch(message, "game"),
         {:ok, game} <- Games.get_by_short(short_name),
         {:ok, game} <- Games.check_web_client(game),
         {:ok, game} <- check_user_allowed(socket, game) do
      {:ok, assign(socket, :game, game)}
    else
      _ ->
        {:error, %{reason: "must connect to a game"}}
    end
  end

  defp check_user_allowed(socket, game) do
    case Game.client_allowed?(game, socket.assigns, :user) do
      true ->
        {:ok, game}

      false ->
        {:error, "game is not open"}
    end
  end

  def start_client(socket) do
    {:ok, connection} = Games.get_web_client_connection(socket.assigns.game)

    {:ok, pid} = WebClient.connect(socket.assigns.session_token,
      game: socket.assigns.game,
      client_settings: socket.assigns.game.client_settings,
      type: connection.type,
      host: connection.host,
      port: connection.port,
      channel_pid: socket.channel_pid
    )

    Process.flag(:trap_exit, true)
    Process.link(pid)

    socket = assign(socket, :client_pid, pid)
    push(socket, "connection", Map.take(connection, [:type, :host, :port]))

    {:ok, socket}
  end

  def handle_in("send", %{"message" => message}, socket) do
    WebClient.recv(socket.assigns.client_pid, message)
    {:noreply, socket}
  end

  def handle_info(:start_client, socket) do
    {:ok, socket} = start_client(socket)
    {:noreply, socket}
  end

  def handle_info({:echo, data}, socket) do
    push(socket, "echo", %{message: data})
    {:noreply, socket}
  end

  def handle_info({:ga}, socket) do
    push(socket, "ga", %{})
    {:noreply, socket}
  end

  def handle_info({:gmcp, module, data}, socket) do
    push(socket, "gmcp", %{module: module, data: data})
    {:noreply, socket}
  end

  def handle_info({:option, key, value}, socket) do
    push(socket, "option", %{key: key, value: value})
    {:noreply, socket}
  end

  def handle_info({:EXIT, pid, _reason}, socket) do
    case socket.assigns.client_pid == pid do
      true ->
        {:stop, :normal, socket}

      false ->
        {:noreply, socket}
    end
  end
end
