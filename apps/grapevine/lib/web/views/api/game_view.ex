defmodule Web.Api.GameView do
  use Web, :view

  alias Web.ConnectionView

  def render("index.json", %{games: games, pagination: pagination, filter: filter}) do
    games
    |> index(pagination, filter)
    |> Representer.transform("json")
  end

  def render("show.json", %{game: game}) do
    game
    |> show()
    |> Representer.transform("json")
  end

  def render("game.json", %{game: game}) do
    Map.take(game, [
      :name,
      :short_name,
      :tagline,
      :description,
      :homepage_url,
      :discord_invite_url
    ])
  end

  def render("online.json", %{games: games}) do
    %{
      collection: render_many(games, __MODULE__, "presence.json")
    }
  end

  def render("presence.json", %{game: game}) do
    %{
      game: Map.take(game.game, [:name, :homepage_url]),
      players: game.players
    }
  end

  defp item(game) do
    connections = render_many(game.connections, ConnectionView, "show.json", as: :connection)

    %Representer.Item{
      data: render("game.json", %{game: game}),
      embedded: %{connections: connections}
    }
  end

  defp show(game) do
    game
    |> item()
    |> Representer.maybe_link(game.enable_web_client, %Representer.Link{
      rel: "https://grapevine.haus/client",
      href: Routes.play_url(Web.Endpoint, :show, game.short_name)
    })
  end

  defp index(games, pagination, filter) do
    games = Enum.map(games, &show/1)
    self_link = Routes.game_url(Web.Endpoint, :index, filter)

    %Representer.Collection{
      items: games,
      pagination: Representer.Pagination.new(self_link, pagination),
      links: [
        %Representer.Link{rel: "self", href: self_link}
      ]
    }
  end
end
