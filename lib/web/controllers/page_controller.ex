defmodule Web.PageController do
  use Web, :controller

  alias Grapevine.CNAMEs
  alias Grapevine.Games

  action_fallback(Web.FallbackController)

  @config Application.get_env(:grapevine, :web)

  def index(conn, _params) do
    case conn.host != @config[:host] do
      true ->
        case CNAMEs.host_known?(conn.host) do
          true ->
            redirect(conn, to: Routes.play_path(conn, :client))

          false ->
            {:error, :not_found}
        end

      false ->
        games = Games.public(filter: %{"online" => "yes", "cover" => "yes"})

        conn
        |> assign(:games, games)
        |> render("index.html")
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
