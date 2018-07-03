defmodule Web.Plugs.FetchUser do
  @moduledoc """
  Fetch a user from the session
  """

  import Plug.Conn

  alias Gossip.Accounts

  def init(default), do: default

  def call(conn, _opts) do
    case conn |> get_session(:user_token) do
      nil ->
        conn

      token ->
        load_user(conn, Accounts.from_token(token))
    end
  end

  defp load_user(conn, {:ok, user}) do
    conn |> assign(:current_user, user)
  end

  defp load_user(conn, _), do: conn
end
