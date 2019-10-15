defmodule GrapevineData.Repo.Migrations.CreateBlogPosts do
  use Ecto.Migration

  def change do
    create table(:blog_posts) do
      add(:uid, :uuid, default: fragment("uuid_generate_v4()"), null: false)
      add(:title, :string, null: false)
      add(:body, :text, null: false)
      add(:status, :string, default: "draft")
      add(:user_id, references(:users), null: false)

      timestamps()
    end

    create index(:blog_posts, :uid)
  end
end
