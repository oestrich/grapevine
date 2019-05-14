defmodule Web.UserSocket do
  use Phoenix.Socket

  alias Grapevine.Accounts

  require Logger

  channel("chat:*", Web.ChatChannel)
  channel("mssp:*", Web.MSSPChannel)
  channel("play:client", Web.PlayChannel)

  def connect(params, socket, connection_info) do
    Logger.info("Web socket connection info - #{inspect(connection_info)}")

    socket =
      socket
      |> assign(:ip, connection_info.peer_data.address)
      |> load_user_token(params)
      |> load_session_token(params)

    {:ok, socket}
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
