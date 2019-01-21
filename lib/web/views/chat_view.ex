defmodule Web.ChatView do
  use Web, :view

  def active(0), do: "active"
  def active(_), do: ""
end
