defmodule Web.EventView do
  use Web, :view

  alias Web.MarkdownView

  def event_description(event) do
    description =
      event.description
      |> MarkdownView.strip()
      |> String.split(" ")
      |> Enum.take(50)
      |> Enum.join(" ")

    case String.length(event.description) > String.length(description) do
      true ->
        text_to_html(description <> "...")

      false ->
        text_to_html(description)
    end
  end
end
