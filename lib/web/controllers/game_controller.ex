defmodule Web.GameController do
  use Web, :controller

  alias Grapevine.Events
  alias Data.Games
  alias Grapevine.Presence

  action_fallback(Web.FallbackController)

  def index(conn, params) do
    filter = Map.get(params, "games", %{"online" => "yes"})
    games = Games.public(filter: filter)

    conn
    |> assign(:games, games)
    |> assign(:user_agents, Games.user_agents_in_use())
    |> assign(:filter, filter)
    |> assign(:title, "Games on Grapevine")
    |> assign(:open_graph_title, "Games on Grapevine")
    |> assign(:open_graph_description, "View a listing of games that are on the Grapevine network.")
    |> assign(:open_graph_url, game_url(conn, :index))
    |> render("index.html")
  end

  def show(conn, %{"id" => short_name}) do
    with {:ok, game} <- Games.get_by_short(short_name, display: true) do
      presence =
        Enum.find(Presence.online_games(), fn presence ->
          presence.game.id == game.id
        end)

      conn
      |> assign(:game, game)
      |> assign(:presence, presence)
      |> assign(:events, Events.recent(game))
      |> assign(:title, "#{game.name} - Grapevine")
      |> assign(:open_graph_title, game.name)
      |> assign(:open_graph_description, game.description)
      |> assign(:open_graph_url, game_url(conn, :show, game.short_name))
      |> render("show.html")
    end
  end

  def online(conn, _params) do
    games = Enum.filter(Presence.online_games(), & &1.game.display)

    conn
    |> assign(:games, games)
    |> render(:online)
  end
end
