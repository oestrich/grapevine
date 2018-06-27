defmodule Web.Plugs.FetchGame do
  @moduledoc """
  Fetch a game from the session
  """

  import Plug.Conn

  alias Gossip.Games

  def init(default), do: default

  def call(conn, _opts) do
    case conn |> get_session(:game_token) do
      nil ->
        conn

      token ->
        load_game(conn, Games.from_token(token))
    end
  end

  defp load_game(conn, {:ok, game}) do
    conn |> assign(:current_game, game)
  end

  defp load_game(conn, _), do: conn
end
