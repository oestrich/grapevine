defmodule Web.EventView do
  use Web, :view

  def event_description(event) do
    description =
      event.description
      |> String.split(" ")
      |> Enum.take(50)
      |> Enum.join(" ")
      |> text_to_html()

    [description, "..."]
  end
end
