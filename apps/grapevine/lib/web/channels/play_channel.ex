defmodule Web.PlayChannel do
  @moduledoc """
  Follow along with the grapevine from the site
  """

  use Web, :channel

  alias GrapevineData.Authorizations
  alias GrapevineData.Games
  alias GrapevineTelnet.WebClient
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
      {:ok, :allowed} ->
        {:ok, game}

      {:error, _} ->
        {:error, "game is not open"}
    end
  end

  def start_client(socket) do
    {:ok, connection} = Games.get_web_client_connection(socket.assigns.game)

    {:ok, pid} =
      WebClient.connect(socket.assigns.session_token,
        client_ip: socket.assigns.ip,
        game: socket.assigns.game,
        client_settings: socket.assigns.game.client_settings,
        type: connection.type,
        host: connection.host,
        port: connection.port,
        certificate: connection.certificate,
        channel_pid: socket.channel_pid
      )

    Process.flag(:trap_exit, true)
    Process.link(pid)

    socket =
      socket
      |> assign(:client_pid, pid)
      |> assign(:connection, connection)

    push(socket, "connection", Map.take(connection, [:type, :host, :port]))

    {:ok, socket}
  end

  def handle_in("send", %{"message" => message}, socket) do
    WebClient.recv(socket.assigns.client_pid, message)
    {:noreply, socket}
  end

  def handle_in(event = "system/" <> _, params, socket) do
    WebClient.event(socket.assigns.client_pid, event, params)
    {:noreply, socket}
  end

  def handle_in("oauth", %{"state" => "accept"}, socket) do
    with true <- secure_telnet?(socket),
         {:ok, authorization} <- Map.fetch(socket.assigns, :authorization) do
      {:ok, authorization} = Authorizations.authorize(authorization)
      send_oauth_grant(socket, authorization)
    else
      _ ->
        {:noreply, socket}
    end
  end

  def handle_in("oauth", %{"state" => "reject"}, socket) do
    with true <- secure_telnet?(socket),
         {:ok, authorization} <- Map.fetch(socket.assigns, :authorization) do
      Authorizations.deny(authorization)
    end

    {:noreply, socket}
  end

  def handle_info(:start_client, socket) do
    {:ok, socket} = start_client(socket)
    {:noreply, socket}
  end

  def handle_info({:echo, data}, socket) do
    data =
      data
      |> String.chunk(:valid)
      |> Enum.map(&replace_invalid/1)
      |> Enum.join()

    case Jason.encode(data) do
      {:ok, _msg} ->
        push(socket, "echo", %{message: data})

      {:error, _error} ->
        push(socket, "echo", %{message: "\n\n\e[31mERROR - Hiccup from the game\n\n\e[0m"})
    end

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

  def handle_info({:oauth, "AuthorizationRequest", params}, socket) do
    with true <- secure_telnet?(socket),
         {:ok, user} <- Map.fetch(socket.assigns, :user),
         {:ok, game} <- Map.fetch(socket.assigns, :game),
         {:ok, user} <- Authorizations.check_for_username(user),
         {:ok, authorization} <- Authorizations.start_auth(user, game, params) do
      case authorization.active do
        true ->
          send_oauth_grant(socket, authorization)

        false ->
          push(socket, "oauth", %{event: "start", scopes: authorization.scopes})
          socket = assign(socket, :authorization, authorization)
          {:noreply, socket}
      end
    else
      _ ->
        {:noreply, socket}
    end
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

  defp replace_invalid(codepoint) do
    case String.valid?(codepoint) do
      true ->
        codepoint

      false ->
        <<0xEF, 0xBF, 0xBD>>
    end
  end

  defp secure_telnet?(socket) do
    with {:ok, connection} <- Map.fetch(socket.assigns, :connection),
         "secure telnet" <- connection.type do
      true
    else
      _ ->
        false
    end
  end

  defp send_oauth_grant(socket, authorization) do
    WebClient.event(socket.assigns.client_pid, "oauth", %{
      type: "AuthorizationGrant",
      state: authorization.state,
      code: authorization.code
    })

    socket = assign(socket, :authorization, authorization)

    {:noreply, socket}
  end
end
