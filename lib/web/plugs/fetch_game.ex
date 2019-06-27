defmodule Web.Plugs.FetchGame do
  @moduledoc """
  Fetch a user from the session
  """

  import Plug.Conn

  alias GrapevineData.Games

  def init(default), do: default

  def call(conn, _opts) do
    case Map.has_key?(conn.params, "client_id") do
      true ->
        fetch_game(conn, conn.params["client_id"])

      false ->
        conn
    end
  end

  defp fetch_game(conn, client_id) do
    case Games.get_by(client_id: client_id) do
      {:ok, game} ->
        assign(conn, :client_game, game)

      {:error, :not_found} ->
        conn
    end
  end
end
