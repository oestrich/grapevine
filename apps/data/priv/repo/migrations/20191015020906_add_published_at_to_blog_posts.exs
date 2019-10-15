defmodule GrapevineData.Repo.Migrations.AddPublishedAtToBlogPosts do
  use Ecto.Migration

  def change do
    alter table(:blog_posts) do
      add(:published_at, :utc_datetime)
    end
  end
end
