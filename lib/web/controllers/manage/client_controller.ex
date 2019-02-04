defmodule Web.Manage.ClientController do
  use Web, :controller

  alias Grapevine.Games
  alias Grapevine.Gauges

  def show(conn, %{"game_id" => id}) do
    %{current_user: user} = conn.assigns

    with {:ok, game} <- Games.get(user, id) do
      conn
      |> assign(:game, game)
      |> assign(:gauges, Gauges.for(game))
      |> render("show.html")
    end
  end
end
