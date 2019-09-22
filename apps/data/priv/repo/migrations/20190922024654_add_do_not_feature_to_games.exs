defmodule GrapevineData.Repo.Migrations.AddDoNotFeatureToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:featurable, :boolean, default: true, null: false)
    end
  end
end
