defmodule Web.Plugs.SessionToken do
  @moduledoc """
  Insert a session token, signed by phoenix

  Session should be loaded before calling
  """

  import Plug.Conn

  def init(default), do: default

  def call(conn, _opts) do
    case get_session(conn, :session_token) do
      nil ->
        generate_token(conn)

      token ->
        assign(conn, :session_token, token)
    end
  end

  defp generate_token(conn) do
    token = Phoenix.Token.sign(conn, "session token", UUID.uuid4())

    conn
    |> assign(:session_token, token)
    |> put_session(:session_token, token)
  end
end
