defmodule Web.Plugs.EnsureDecanterEnabled do
  @moduledoc """
  Verify a user is in the session
  """

  import Plug.Conn
  import Phoenix.Controller

  alias Web.ErrorView
  alias Web.LayoutView

  @decanter_enabled Application.get_env(:grapevine, :decanter)[:enabled]

  def init(default), do: default

  def call(conn, _opts) do
    case @decanter_enabled do
      true ->
        conn

      false ->
        conn
        |> put_status(:not_found)
        |> put_layout({LayoutView, "app.html"})
        |> put_view(ErrorView)
        |> render(:"404")
        |> halt()
    end
  end
end
