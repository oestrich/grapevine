defmodule Web.Decanter.DraftController do
  use Web, :controller

  alias GrapevineData.Blogs

  def index(conn, _params) do
    %{current_user: user} = conn.assigns

    conn
    |> assign(:blog_posts, Blogs.posts_for(user))
    |> render("index.html")
  end
end
