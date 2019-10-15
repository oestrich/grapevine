defmodule Web.Decanter.NewsView do
  use Web, :view

  alias GrapevineData.Accounts
  alias Web.MarkdownView
  alias Web.SharedView
  alias Web.TimeView

  def blog_post_owned_by_user?(%{current_user: user}, blog_post) when user != nil do
    user.id == blog_post.user_id
  end

  def blog_post_owned_by_user?(_, _), do: false

  def draft_post?(blog_post), do: blog_post.status == "draft"

  def submitted_post?(blog_post), do: blog_post.status == "submitted"

  def editable?(blog_post) do
    draft_post?(blog_post) || submitted_post?(blog_post)
  end

  def status(%{status: "draft"}), do: "Draft"

  def status(%{status: "submitted"}), do: "Submitted"

  def status(%{status: "published"}), do: "Published"

  def editor_or_admin?(%{current_user: user}) when user != nil do
    Accounts.is_admin?(user) || Accounts.is_editor?(user)
  end

  def editor_or_admin?(_), do: false
end
