defmodule Web.PageView do
  use Web, :view

  alias Gossip.Channels
  alias Web.DocView

  def render("conduct.html", _assigns) do
    :gossip
    |> :code.priv_dir()
    |> Path.join("pages/CODE_OF_CONDUCT.md")
    |> File.read!()
    |> Earmark.as_html!()
    |> raw()
  end
end
