defmodule Web.Plugs.ValidateHost do
  @moduledoc """
  Validate the host matches the configured grapevine host
  """

  @config Application.get_env(:grapevine, :web)[:url]

  import Plug.Conn
  import Phoenix.Controller

  alias Web.Router.Helpers, as: Routes

  def init(default), do: default

  def call(conn, _opts) do
    case conn.host == @config[:host] do
      true ->
        conn

      false ->
        conn
        |> redirect(to: Routes.page_path(conn, :index))
        |> halt()
    end
  end
end
