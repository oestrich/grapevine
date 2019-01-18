defmodule Web.GameController do
  use Web, :controller

  alias Gossip.Presence

  def online(conn, _params) do
    games = Enum.filter(Presence.online_games(), & &1.game.display)

    conn
    |> assign(:games, games)
    |> render(:online)
  end
end
