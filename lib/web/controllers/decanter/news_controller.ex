defmodule Web.Decanter.NewsController do
  use Web, :controller

  alias GrapevineData.Blogs

  action_fallback Web.FallbackController

  def index(conn, _params) do
    conn
    |> render("index.html")
  end

  def show(conn, %{"uid" => uid}) do
    user = Map.get(conn.assigns, :current_user, nil)

    with {:ok, blog_post} <- Blogs.get(uid),
         {:ok, blog_post} <- Blogs.check_permission_to_read(user, blog_post) do
      conn
      |> assign(:blog_post, blog_post)
      |> render("show.html")
    end
  end

  def new(conn, _params) do
    conn
    |> assign(:changeset, Blogs.new_post())
    |> render("new.html")
  end

  def create(conn, %{"blog_post" => params}) do
    %{current_user: user} = conn.assigns

    case Blogs.create(user, params) do
      {:ok, blog_post} ->
        redirect(conn, to: Routes.decanter_news_path(conn, :show, blog_post.uid))

      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"uid" => uid}) do
    user = Map.get(conn.assigns, :current_user, nil)

    with {:ok, blog_post} <- Blogs.get(uid),
         {:ok, blog_post} <- Blogs.check_permission_to_read(user, blog_post) do
      conn
      |> assign(:blog_post, blog_post)
      |> assign(:changeset, Blogs.edit_post(blog_post))
      |> render("edit.html")
    end
  end

  def update(conn, %{"uid" => uid, "blog_post" => params}) do
    %{current_user: user} = conn.assigns

    with {:ok, blog_post} <- Blogs.get(uid),
         {:ok, blog_post} <- Blogs.check_permission_to_read(user, blog_post) do
      case Blogs.update(blog_post, params) do
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
end
