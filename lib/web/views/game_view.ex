defmodule Web.GameView do
  use Web, :view

  def render("index.json", %{games: games}) do
    %{
      collection: render_many(games, __MODULE__, "show.json"),
    }
  end

  def render("show.json", %{game: game}) do
    %{
      game: Map.take(game.game, [:name, :homepage_url]),
      players: game.players,
    }
  end
end
