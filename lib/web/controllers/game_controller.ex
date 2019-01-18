defmodule Web.GameController do
  use Web, :controller

  alias Gossip.Events
  alias Gossip.Games
  alias Gossip.Presence

  def index(conn, _params) do
    conn
    |> assign(:games, Games.all(sort: :online))
    |> assign(:title, "Games on Gossip")
    |> assign(:open_graph_title, "Games on Gossip")
    |> assign(:open_graph_description, "View a listing of games that are on the Gossip network.")
    |> assign(:open_graph_url, game_url(conn, :index))
    |> render("index.html")
  end

  def show(conn, %{"id" => short_name}) do
    with {:ok, game} <- Games.get_by_short(short_name, display: true) do
      conn
      |> assign(:game, game)
      |> assign(:events, Events.recent(game))
      |> assign(:title, "#{game.name} - Gossip")
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
