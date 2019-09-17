defmodule Web.MarkdownView do
  def parse(text) do
    text
    |> Earmark.as_html!()
    |> HtmlSanitizeEx.markdown_html()
    |> Phoenix.HTML.raw()
  end
end
