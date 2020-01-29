defmodule Web.GameController do
  use Web, :controller

  alias GrapevineData.Events
  alias GrapevineData.Games
  alias Grapevine.Presence

  plug(Web.Plugs.FetchPage, [per: 25] when action in [:index])

  action_fallback(Web.FallbackController)

  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "games", %{"online" => "yes"})
    %{page: games, pagination: pagination} = Games.public(filter: filter, page: page, per: per)

    conn
    |> assign(:games, games)
    |> assign(:user_agents, Games.user_agents_in_use())
    |> assign(:pagination, pagination)
    |> assign(:filter, filter)
    |> assign(:title, "Games on Grapevine")
    |> assign(:open_graph_title, "Games on Grapevine")
    |> assign(
      :open_graph_description,
      "View a listing of games that are on the Grapevine network."
    )
    |> assign(:open_graph_url, game_url(conn, :index))
    |> render(:index)
  end

  def show(conn, %{"id" => short_name}) do
    with {:ok, game} <- Games.get_by_short(short_name, display: true) do
      presence =
        Enum.find(Presence.online_games(), fn presence ->
          presence.game.id == game.id
        end)

      conn
      |> assign(:game, game)
      |> assign(:players, players(presence))
      |> assign(:events, Events.recent(game))
      |> assign(:title, "#{game.name} - Grapevine")
      |> assign(:open_graph_title, game.name)
      |> assign(:open_graph_description, game.description)
      |> assign(:open_graph_url, game_url(conn, :show, game.short_name))
      |> render(:show)
    end
  end

  def online(conn, _params) do
    games = Enum.filter(Presence.online_games(), & &1.game.display)

    conn
    |> assign(:games, games)
    |> render(:online)
  end

  def surprise(conn, %{"play" => "true"}) do
    case Presence.random_online_web_game() do
      {:ok, game} ->
        redirect(conn, to: Routes.play_path(conn, :show, game.short_name))

      :error ->
        conn
        |> put_flash(:error, "There are no online web games.")
        |> redirect(to: game_path(conn, :index))
    end
  end

  def surprise(conn, _params) do
    case Presence.random_online_game() do
      {:ok, game} ->
        redirect(conn, to: Routes.game_path(conn, :show, game.short_name))

      :error ->
        conn
        |> put_flash(:error, "There are no online games.")
        |> redirect(to: game_path(conn, :index))
    end
  end

  defp players(nil), do: []
  defp players(%{players: players}), do: players
end
