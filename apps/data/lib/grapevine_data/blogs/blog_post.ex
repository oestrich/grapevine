defmodule GrapevineData.Blogs.BlogPost do
  @moduledoc """
  Blog Post Schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias GrapevineData.Accounts.User

  @type t :: %__MODULE__{}

  schema "blog_posts" do
    field(:uid, Ecto.UUID, read_after_writes: true)
    field(:status, :string, read_after_writes: true)
    field(:title, :string)
    field(:body, :string)
    field(:published_at, :utc_datetime)

    belongs_to(:user, User)

    timestamps()
  end

  def create_changeset(struct, user, params) do
    struct
    |> cast(params, [:title, :body])
    |> put_change(:status, "draft")
    |> put_change(:user_id, user.id)
    |> validate_required([:title, :body, :user_id])
    |> foreign_key_constraint(:user_id)
  end

  def update_changeset(struct, params) do
    struct
    |> cast(params, [:title, :body])
    |> put_change(:status, "draft")
    |> validate_required([:title, :body, :user_id])
  end

  def editor_changeset(struct, params) do
    struct
    |> cast(params, [:title, :body])
    |> validate_required([:title, :body, :user_id])
  end
end
