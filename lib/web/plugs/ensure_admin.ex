defmodule Web.Plugs.EnsureAdmin do
  @moduledoc """
  Verify a user is in the session
  """

  import Plug.Conn
  import Phoenix.Controller

  alias GrapevineData.Accounts
  alias Web.ErrorView
  alias Web.LayoutView

  def init(default), do: default

  def call(conn, _opts) do
    %{current_user: user} = conn.assigns

    case Accounts.is_admin?(user) do
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
