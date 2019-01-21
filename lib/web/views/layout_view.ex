defmodule Web.LayoutView do
  use Web, :view

  def user_token(%{assigns: %{user_token: token}}), do: token
  def user_token(_), do: ""
end
