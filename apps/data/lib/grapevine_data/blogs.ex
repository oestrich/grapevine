defmodule GrapevineData.Blogs do
  @moduledoc """
  Context for blogs
  """

  import Ecto.Query

  alias GrapevineData.Blogs.BlogPost
  alias GrapevineData.Repo
  alias Stein.Pagination

  @doc """
  Changeset for a new blog post
  """
  def new_post(), do: Ecto.Changeset.change(%BlogPost{}, %{})

  @doc """
  Changeset for a editing a blog post
  """
  def edit_post(blog_post), do: Ecto.Changeset.change(blog_post, %{})

  @doc """
  Fetch a single blog post
  """
  def get(uid) when is_binary(uid) do
    case Repo.get_by(BlogPost, uid: uid) do
      nil ->
        {:error, :not_found}

      blog_post ->
        {:ok, Repo.preload(blog_post, [:user])}
    end
  end

  @doc """
  Return a list of all submitted blog posts for publication
  """
  def submitted_posts() do
    BlogPost
    |> where([bp], bp.status == "submitted")
    |> order_by([bp], desc: bp.inserted_at)
    |> preload([:user])
    |> Repo.all()
  end

  @doc """
  Return a list of all submitted blog posts for publication
  """
  def published_posts(opts \\ []) do
    opts = Enum.into(opts, %{})

    query =
      BlogPost
      |> where([bp], bp.status == "published")
      |> order_by([bp], desc: bp.inserted_at)
      |> preload([:user])

    Pagination.paginate(Repo, query, opts)
  end

  @doc """
  Return a list of all submitted blog posts for publication
  """
  def posts_for(user) do
    BlogPost
    |> where([bp], bp.user_id == ^user.id)
    |> order_by([bp], desc: bp.inserted_at)
    |> preload([:user])
    |> Repo.all()
  end

  @doc """
  Check if a user can read the blog post

      iex> Blogs.check_permission_to_read(%{id: 10}, %{status: "published"})
      {:ok, %{status: "published"}}

      iex> Blogs.check_permission_to_read(nil, %{status: "published"})
      {:ok, %{status: "published"}}

      iex> Blogs.check_permission_to_read(%{id: 10, role: "admin"}, %{status: "draft"})
      {:ok, %{status: "draft"}}

      iex> Blogs.check_permission_to_read(%{id: 10, role: "editor"}, %{status: "draft"})
      {:ok, %{status: "draft"}}

      iex> Blogs.check_permission_to_read(%{id: 10}, %{status: "draft", user_id: 10})
      {:ok, %{status: "draft", user_id: 10}}

      iex> Blogs.check_permission_to_read(%{id: 10}, %{status: "draft", user_id: 11})
      {:error, :not_found}
  """
  def check_permission_to_read(user, blog_post)

  def check_permission_to_read(_user, blog_post = %{status: "published"}), do: {:ok, blog_post}

  def check_permission_to_read(_user = %{role: "admin"}, blog_post), do: {:ok, blog_post}

  def check_permission_to_read(_user = %{role: "editor"}, blog_post), do: {:ok, blog_post}

  def check_permission_to_read(_user = %{id: user_id}, blog_post = %{user_id: user_id}), do: {:ok, blog_post}

  def check_permission_to_read(_user, _blog_post), do: {:error, :not_found}

  @doc """
  Check if a blog post is editable by the author

  Pre-published states only
  """
  def check_edit_status(blog_post = %{status: "draft"}), do: {:ok, blog_post}

  def check_edit_status(blog_post = %{status: "submitted"}), do: {:ok, blog_post}

  def check_edit_status(_), do: {:error, :locked}

  @doc """
  Create a new blog post written by a user
  """
  def create(user, params) do
    %BlogPost{}
    |> BlogPost.create_changeset(user, params)
    |> Repo.insert()
  end

  @doc """
  Submit a blog post for publication
  """
  def submit(blog_post) do
    blog_post
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_change(:status, "submitted")
    |> Repo.update()
  end

  @doc """
  Publish a blog post
  """
  def publish(blog_post, now \\ Timex.now()) do
    blog_post
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_change(:status, "published")
    |> Ecto.Changeset.put_change(:published_at, DateTime.truncate(now, :second))
    |> Repo.update()
  end

  @doc """
  Update a blog post
  """
  def update(blog_post, params) do
    blog_post
    |> BlogPost.update_changeset(params)
    |> Repo.update()
  end

  @doc """
  Update a blog post, from an editor
  """
  def editor_update(blog_post, params) do
    blog_post
    |> BlogPost.editor_changeset(params)
    |> Repo.update()
  end
end
