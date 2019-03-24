defmodule Web.SplitRouter do
  @moduledoc """
  Validate the host matches the configured grapevine host
  """

  import Plug.Conn

  alias Grapevine.CNAMEs
  alias Grapevine.Games

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
        end
    end
  end
end
