defmodule Web.Plugs.SessionToken do
  @moduledoc """
  Insert a session token, signed by phoenix

  Session should be loaded before calling
  """

  import Plug.Conn

  def init(default), do: default

  def call(conn, api: true) do
    token = UUID.uuid4()
    assign(conn, :session_token, sign_token(conn, token))
  end

  def call(conn, _opts) do
    case get_session(conn, :session_token) do
      nil ->
        generate_token(conn)

      token ->
        assign(conn, :session_token, sign_token(conn, token))
    end
  end

  defp generate_token(conn) do
    token = UUID.uuid4()

    conn
    |> put_session(:session_token, token)
    |> assign(:session_token, sign_token(conn, token))
  end

  defp sign_token(conn, token) do
    Phoenix.Token.sign(conn, "session token", token)
  end
end
