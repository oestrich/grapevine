defmodule Web.Decanter.Manage.QueueController do
  use Web, :controller

  alias GrapevineData.Blogs

  def index(conn, _params) do
    conn
    |> assign(:blog_posts, Blogs.submitted_posts())
    |> render("index.html")
  end

  def edit(conn, %{"uid" => uid}) do
    with {:ok, blog_post} <- Blogs.get(uid) do
      conn
      |> assign(:blog_post, blog_post)
      |> assign(:changeset, Blogs.edit_post(blog_post))
      |> render("edit.html")
    end
  end

  def update(conn, %{"uid" => uid, "blog_post" => params}) do
    with {:ok, blog_post} <- Blogs.get(uid) do
      case Blogs.editor_update(blog_post, params) do
        {:ok, blog_post} ->
          redirect(conn, to: Routes.decanter_news_path(conn, :show, blog_post.uid))

        {:error, changeset} ->
          conn
          |> assign(:blog_post, blog_post)
          |> assign(:changeset, changeset)
          |> render("edit.html")
      end
    end
  end

  def publish(conn, %{"uid" => uid}) do
    with {:ok, blog_post} <- Blogs.get(uid) do
      {:ok, blog_post} = Blogs.publish(blog_post)
      redirect(conn, to: Routes.decanter_news_path(conn, :show, blog_post.uid))
    end
  end
end
