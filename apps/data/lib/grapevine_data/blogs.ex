defmodule GrapevineData.Blogs do
  @moduledoc """
  Context for blogs
  """

  alias GrapevineData.Blogs.BlogPost
  alias GrapevineData.Repo

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
  Check if a user can read the blog post

      iex> Blogs.check_permission_to_read(%{id: 10}, %{status: "published"})
      {:ok, %{status: "published"}}

      iex> Blogs.check_permission_to_read(nil, %{status: "published"})
      {:ok, %{status: "published"}}

      iex> Blogs.check_permission_to_read(%{id: 10, role: "admin"}, %{status: "draft"})
      {:ok, %{status: "draft"}}

      iex> Blogs.check_permission_to_read(%{id: 10}, %{status: "draft", user_id: 10})
      {:ok, %{status: "draft", user_id: 10}}

      iex> Blogs.check_permission_to_read(%{id: 10}, %{status: "draft", user_id: 11})
      {:error, :not_found}
  """
  def check_permission_to_read(user, blog_post)

  def check_permission_to_read(_user, blog_post = %{status: "published"}), do: {:ok, blog_post}

  def check_permission_to_read(_user = %{role: "admin"}, blog_post), do: {:ok, blog_post}

  def check_permission_to_read(_user = %{id: user_id}, blog_post = %{user_id: user_id}), do: {:ok, blog_post}

  def check_permission_to_read(_user, _blog_post), do: {:error, :not_found}

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
  def publish(blog_post) do
    blog_post
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_change(:status, "published")
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
end
