defmodule Web.UserSocket do
  use Phoenix.Socket

  alias GrapevineData.Accounts

  require Logger

  channel("chat:*", Web.ChatChannel)
  channel("mssp:*", Web.MSSPChannel)
  channel("play:client", Web.PlayChannel)

  def connect(params, socket, connection_info) do
    socket =
      socket
      |> assign(:ip, client_ip(connection_info))
      |> load_user_token(params)
      |> load_session_token(params)

    {:ok, socket}
  end

  def client_ip(connection_info) do
    real_ip =
      Enum.find(connection_info.x_headers, fn {key, _val} ->
        key == "x-real-ip"
      end)

    case real_ip do
      {"x-real-ip", client_ip} ->
        {:ok, client_ip} = :inet.parse_address(String.to_charlist(client_ip))
        client_ip

      _ ->
        connection_info.peer_data.address
    end
  end

  def load_user_token(socket, %{"token" => token}) do
    case Phoenix.Token.verify(socket, "user socket", token, max_age: 86_400) do
      {:ok, user_id} ->
        {:ok, user} = Accounts.get(user_id)
        assign(socket, :user, user)

      {:error, _reason} ->
        socket
    end
  end

  def load_user_token(socket, _), do: socket

  def load_session_token(socket, %{"session" => token}) do
    case Phoenix.Token.verify(socket, "session token", token, max_age: 86_400) do
      {:ok, token} ->
        assign(socket, :session_token, token)

      {:error, _reason} ->
        socket
    end
  end

  def load_session_token(socket, _), do: socket

  def id(_socket), do: nil
end
