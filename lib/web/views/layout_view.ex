defmodule Web.LayoutView do
  use Web, :view

  def user_token(%{assigns: %{user_token: token}}), do: token
  def user_token(_), do: ""

  def session_token(conn), do: conn.assigns.session_token

  def analytics_configured?() do
    analytics_id() != nil
  end

  def analytics_id() do
    Application.get_env(:grapevine, :web)[:analytics_id]
  end
end
