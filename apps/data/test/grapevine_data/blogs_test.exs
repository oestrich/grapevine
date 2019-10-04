defmodule GrapevineData.BlogsTest do
  use Grapevine.DataCase

  alias GrapevineData.Blogs

  doctest Blogs

  describe "creating a blog post" do
    test "creates a new blog post" do
      user = create_user()

      {:ok, blog_post} = Blogs.create(user, %{
        title: "Updates for my Game",
        body: "Some _markdown_ text"
      })

      assert blog_post.status == "draft"
      assert blog_post.title == "Updates for my Game"
    end
  end

  describe "updating a blog post" do
    test "updates a blog post" do
      user = create_user()

      {:ok, blog_post} = Blogs.create(user, %{
        title: "Updates for my Game",
        body: "Some _markdown_ text"
      })

      assert blog_post.title == "Updates for my Game"

      {:ok, blog_post} = Blogs.update(blog_post, %{
        title: "Updates for my game",
      })

      assert blog_post.title == "Updates for my game"
    end
  end

  describe "publishing a post" do
    test "submit a post for publication" do
      user = create_user()

      {:ok, blog_post} = Blogs.create(user, %{
        title: "Updates for my Game",
        body: "Some _markdown_ text"
      })

      assert blog_post.status == "draft"

      {:ok, blog_post} = Blogs.submit(blog_post)

      assert blog_post.status == "submitted"
    end

    test "publish a post" do
      user = create_user()

      {:ok, blog_post} = Blogs.create(user, %{
        title: "Updates for my Game",
        body: "Some _markdown_ text"
      })

      {:ok, blog_post} = Blogs.publish(blog_post)

      assert blog_post.status == "published"
    end
  end
end
