defmodule Web.SplitRouter do
  @moduledoc """
  Select the proper router based on the host header
  """

  import Plug.Conn
  import Phoenix.Controller

  alias Grapevine.CNAMEs
  alias GrapevineData.Games

  @config Application.get_env(:grapevine, :web)[:url]

  def init(default), do: default

  def call(conn, _opts) do
    case conn.host == @config[:host] do
      true ->
        Web.Router.call(conn, %{})

      false ->
        case CNAMEs.type_of_host(conn.host) do
          {:ok, :client, game_id} ->
            {:ok, game} = Games.get(game_id)

            conn = assign(conn, :current_game, game)

            Web.ClientRouter.call(conn, %{})

          {:ok, :site, game_id} ->
            {:ok, game} = Games.get(game_id)

            conn = assign(conn, :current_game, game)

            Web.HostedRouter.call(conn, %{})

          {:error, :not_found} ->
            conn
            |> fetch_session()
            |> fetch_flash()
            |> put_format("html")
            |> put_status(:not_found)
            |> put_layout({Web.LayoutView, "app.html"})
            |> put_view(Web.ErrorView)
            |> render(:"404")
        end
    end
  end
end
