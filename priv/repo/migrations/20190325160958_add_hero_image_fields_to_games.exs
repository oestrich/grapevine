defmodule GrapevineData.Repo.Migrations.AddHeroImageFieldsToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:hero_key, :uuid)
      add(:hero_extension, :string)
    end
  end
end
