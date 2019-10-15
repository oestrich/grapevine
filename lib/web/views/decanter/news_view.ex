defmodule Web.Decanter.NewsView do
  use Web, :view

  alias Web.MarkdownView
  alias Web.TimeView

  def blog_post_owned_by_user?(%{current_user: current_user}, blog_post)
      when current_user != nil do
    current_user.id == blog_post.user_id
  end

  def blog_post_owned_by_user?(_, _), do: false

  def draft_post?(blog_post), do: blog_post.status == "draft"

  def status(%{status: "draft"}), do: "Draft"

  def status(%{status: "submitted"}), do: "Submitted"

  def status(%{status: "published"}), do: "Published"
end
