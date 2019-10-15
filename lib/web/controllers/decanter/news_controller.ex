defmodule Web.Decanter.NewsController do
  use Web, :controller

  alias GrapevineData.Blogs

  action_fallback(Web.FallbackController)

  plug(Web.Plugs.FetchPage when action in [:index])

  def index(conn, _params) do
    %{page: page, per: per} = conn.assigns
    %{page: blog_posts, pagination: pagination} = Blogs.published_posts(page: page, per: per)

    conn
    |> assign(:blog_posts, blog_posts)
    |> assign(:pagination, pagination)
    |> render("index.html")
  end

  def feed(conn, _params) do
    %{page: blog_posts} = Blogs.published_posts(page: 1, per: 20)

    conn
    |> assign(:blog_posts, blog_posts)
    |> assign(:now, Timex.now())
    |> put_layout(false)
    |> put_resp_header("content-type", "application/atom+xml")
    |> render("feed.html")
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
         {:ok, blog_post} <- Blogs.check_edit_status(blog_post),
         {:ok, blog_post} <- Blogs.check_permission_to_read(user, blog_post) do
      conn
      |> assign(:blog_post, blog_post)
      |> assign(:changeset, Blogs.edit_post(blog_post))
      |> render("edit.html")
    else
      {:error, :locked} ->
        {:error, :not_found}

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  def update(conn, %{"uid" => uid, "blog_post" => params}) do
    %{current_user: user} = conn.assigns

    with {:ok, blog_post} <- Blogs.get(uid),
         {:ok, blog_post} <- Blogs.check_edit_status(blog_post),
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
    else
      {:error, :locked} ->
        {:error, :not_found}

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  def submit(conn, %{"uid" => uid}) do
    %{current_user: user} = conn.assigns

    with {:ok, blog_post} <- Blogs.get(uid),
         {:ok, blog_post} <- Blogs.check_permission_to_read(user, blog_post) do
      {:ok, blog_post} = Blogs.submit(blog_post)
      redirect(conn, to: Routes.decanter_news_path(conn, :show, blog_post.uid))
    end
  end
end
