defmodule Web.GameStatisticController do
  use Web, :controller

  alias Gossip.Games
  alias Gossip.Statistics

  def players(conn, %{"game_id" => id}) do
    case Games.get(id) do
      {:ok, game} ->
        conn
        |> assign(:statistics, Statistics.last_week(game))
        |> render("players.json")

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Could not find that game.")
        |> redirect(to: page_path(conn, :index))
    end
  end
end
