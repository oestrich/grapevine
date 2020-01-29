defmodule Web.Plugs.EnsureDecanterEnabled do
  @moduledoc """
  Verify a user is in the session
  """

  import Plug.Conn
  import Phoenix.Controller

  alias GrapevineData.Accounts
  alias Web.ErrorView
  alias Web.LayoutView

  @decanter_enabled Application.get_env(:grapevine, :decanter)[:enabled]

  def init(default), do: default

  def call(conn, _opts) do
    case editor_or_admin?(conn.assigns) || @decanter_enabled do
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

  def editor_or_admin?(%{current_user: user}) when user != nil do
    Accounts.is_admin?(user) || Accounts.is_editor?(user)
  end

  def editor_or_admin?(_), do: false
end
