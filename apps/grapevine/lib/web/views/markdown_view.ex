defmodule Web.MarkdownView do
  @doc """
  Parse into html and then strip to only markdown tags
  """
  def parse(text) do
    text
    |> Earmark.as_html!()
    |> HtmlSanitizeEx.markdown_html()
    |> Phoenix.HTML.raw()
  end

  def parse(text, raw: false) do
    text
    |> Earmark.as_html!()
    |> HtmlSanitizeEx.markdown_html()
  end

  @doc """
  Strip all tags from the markdown
  """
  def strip(text) do
    text
    |> Earmark.as_html!()
    |> HtmlSanitizeEx.strip_tags()
  end
end
