defmodule Web.PageController do
  use Web, :controller

  alias Grapevine.CNAMEs
  alias Grapevine.Games
  alias Web.LayoutView
  alias Web.Hosted

  action_fallback(Web.FallbackController)

  @config Application.get_env(:grapevine, :web)[:url]

  def index(conn, _params) do
    case conn.host == @config[:host] do
      true ->
        games = Games.public(filter: %{"online" => "yes", "cover" => "yes"})

        conn
        |> assign(:games, games)
        |> render("index.html")

      false ->
        case CNAMEs.type_of_host(conn.host) do
          {:ok, :client, _game_id} ->
            redirect(conn, to: Routes.play_path(conn, :client))

          {:ok, :site, game_id} ->
            {:ok, game} = Games.get(game_id)

            conn
            |> put_layout({LayoutView, "hosted.html"})
            |> put_view(Hosted.GameView)
            |> assign(:game, game)
            |> render("show.html")

          {:error, :not_found} ->
            {:error, :not_found}
        end
    end
  end

  def conduct(conn, _params) do
    render(conn, "conduct.html")
  end

  def docs(conn, _params) do
    render(conn, "docs.html")
  end

  def media(conn, _params) do
    render(conn, "media.html")
  end

  def colors(conn, _params) do
    render(conn, "colors.html")
  end
end
