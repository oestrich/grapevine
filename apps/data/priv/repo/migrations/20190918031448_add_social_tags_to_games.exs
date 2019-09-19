defmodule GrapevineData.Repo.Migrations.AddSocialTagsToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:twitter_username, :string)
      add(:facebook_url, :text)
    end
  end
end
