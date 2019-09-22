defmodule Web.EventView do
  use Web, :view

  alias Web.MarkdownView

  def event_description(conn, event) do
    description =
      event.description
      |> MarkdownView.strip()
      |> String.split(" ")
      |> Enum.take(50)
      |> Enum.join(" ")
      |> text_to_html()

    [description, link("...", to: Routes.event_path(conn, :show, event.uid))]
  end
end
